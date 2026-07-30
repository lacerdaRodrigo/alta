import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_identity_services_web/oauth2.dart' as oauth2;
import 'package:google_sign_in/google_sign_in.dart';

import 'autorizador_google_base.dart';

/// Autorização no web falando direto com o Google Identity Services.
///
/// **Por que não usar o `authorizationClient` do `google_sign_in`:** o plugin
/// monta o token client amarrando o hint de usuário ao `prompt`
/// (`google_sign_in_web/lib/src/gis_client.dart`):
///
/// ```dart
/// prompt: userHint == null ? '' : 'select_account',
/// login_hint: userHint,
/// ```
///
/// Os dois caminhos possíveis mostram o seletor de contas de novo quando o
/// navegador tem mais de uma sessão Google aberta:
/// - `GoogleSignIn.instance.authorizationClient` (sem hint) manda `prompt: ''`
///   mas também `login_hint: null` — o Google não sabe qual conta usar e
///   pergunta;
/// - `conta.authorizationClient` manda o hint, e por isso o plugin força
///   `prompt: 'select_account'` — que é literalmente "abra o seletor".
///
/// Como no web o login tem duas etapas obrigatórias (identidade pelo botão do
/// GIS + autorização pelo token client), o usuário acabava escolhendo a conta
/// duas vezes por login. Aqui montamos o par que o plugin não permite —
/// `login_hint` com `prompt` vazio — então o segundo passo vai direto para a
/// conta escolhida no botão e nem aparece quando o consentimento já existe.
///
/// No Android nada disso se aplica: ver `autorizador_google_stub.dart`.
AutorizadorGoogle criarAutorizadorGoogle({required String clientIdWeb}) =>
    AutorizadorGoogleWeb(clientIdWeb);

/// Margem de segurança antes da expiração do access token: pedir um novo antes
/// de o antigo vencer evita que uma requisição longa comece com token válido e
/// termine com ele vencido.
const _margemExpiracao = Duration(minutes: 1);

class _TokenEmCache {
  final String token;
  final DateTime expiraEm;
  final Set<String> escopos;

  const _TokenEmCache({
    required this.token,
    required this.expiraEm,
    required this.escopos,
  });

  bool cobre(List<String> pedidos, DateTime agora) =>
      agora.isBefore(expiraEm) && pedidos.every(escopos.contains);
}

class AutorizadorGoogleWeb implements AutorizadorGoogle {
  AutorizadorGoogleWeb(this._clientId);

  final String _clientId;

  /// Cache por e-mail: trocar de conta não pode reaproveitar o token da
  /// anterior.
  final Map<String, _TokenEmCache> _tokens = {};

  /// Uma requisição em andamento por conta — sem isso, duas chamadas
  /// simultâneas às APIs abririam dois popups de autorização.
  final Map<String, Future<String>> _pendentes = {};

  @override
  Future<void> garantirAutorizacao(
    GoogleSignInAccount conta,
    List<String> escopos,
  ) async {
    await _token(conta.email, escopos);
  }

  @override
  Future<Map<String, String>?> headersSeAutorizado(
    GoogleSignInAccount conta,
    List<String> escopos,
  ) async {
    final cache = _tokens[conta.email];
    if (cache == null || !cache.cobre(escopos, DateTime.now())) return null;
    return _cabecalhos(cache.token);
  }

  @override
  Future<Map<String, String>> headers(
    GoogleSignInAccount conta,
    List<String> escopos,
  ) async {
    return _cabecalhos(await _token(conta.email, escopos));
  }

  Map<String, String> _cabecalhos(String token) => {
    'Authorization': 'Bearer $token',
  };

  Future<String> _token(String email, List<String> escopos) {
    final cache = _tokens[email];
    if (cache != null && cache.cobre(escopos, DateTime.now())) {
      return Future.value(cache.token);
    }
    return _pendentes[email] ??= _solicitarToken(email, escopos).whenComplete(
      () => _pendentes.remove(email),
    );
  }

  Future<String> _solicitarToken(String email, List<String> escopos) {
    final resultado = Completer<String>();

    final cliente = oauth2.oauth2.initTokenClient(
      oauth2.TokenClientConfig(
        client_id: _clientId,
        scope: escopos,
        // O par que resolve a dupla escolha de conta: o hint leva o Google
        // direto à conta que o usuário já escolheu no botão, e o `prompt`
        // vazio impede que o seletor seja reaberto. Trocar `prompt` por
        // 'select_account' (ou remover o hint) traz o bug de volta.
        login_hint: email,
        prompt: '',
        include_granted_scopes: true,
        callback: (resposta) {
          final erro = resposta.error;
          final token = resposta.access_token;
          if (erro != null || token == null) {
            _tokens.remove(email);
            resultado.completeError(
              StateError(
                'Não foi possível obter autorização do Google'
                '${erro == null ? '' : ' ($erro)'}.',
              ),
            );
            return;
          }
          _tokens[email] = _TokenEmCache(
            token: token,
            expiraEm: DateTime.now().add(
              Duration(seconds: resposta.expires_in ?? 3600) - _margemExpiracao,
            ),
            escopos: resposta.scope.toSet(),
          );
          resultado.complete(token);
        },
        error_callback: (erro) {
          _tokens.remove(email);
          developer.log(
            'Autorização do Google falhou: ${erro?.type} ${erro?.message}',
            name: 'AutorizadorGoogleWeb',
          );
          resultado.completeError(
            StateError(
              'Não foi possível obter autorização do Google '
              '(${erro?.message ?? erro?.type.name ?? 'erro desconhecido'}).',
            ),
          );
        },
      ),
    );

    cliente.requestAccessToken();
    return resultado.future;
  }
}
