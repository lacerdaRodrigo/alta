import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_identity_services_web/oauth2.dart' as oauth2;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'autorizador_google_base.dart';

/// Autorização no web falando direto com o Google Identity Services.
///
/// **Por que o login interativo não usa o botão de identidade do GIS
/// (`GoogleSignIn`/`google_sign_in_web`):** esse botão só resolve
/// identidade — para autorizar Drive/Sheets seria preciso um **segundo**
/// popup, disparado depois que a identidade chega pelo stream
/// `authenticationEvents`. Esse segundo popup não nasce de um clique nesta
/// página (o clique original foi consumido pela interação inteira com o
/// primeiro popup, que leva segundos): o Chrome tolera isso na maioria das
/// vezes, mas o WebKit do iOS — usado por **todo** navegador no iOS, Chrome
/// incluso, por exigência da Apple — bloqueia esse popup sempre. Foi isso que
/// impedia o login de completar no iPhone.
///
/// A correção é não ter um segundo popup: [entrarInterativo] pede conta +
/// consentimento dos escopos num popup só, chamado sem nenhum `await` antes
/// — ainda dentro da mesma pilha síncrona do toque do usuário no botão do
/// App — e depois busca nome/e-mail com o próprio access token
/// (`https://www.googleapis.com/oauth2/v3/userinfo`), já que o escopo
/// `email` está entre os pedidos.
///
/// `garantirAutorizacao`/`headers`/`headersSeAutorizado` continuam existindo
/// para **renovar** o token depois do login (ele expira em 1h no web) — aí
/// sim usamos `login_hint` com `prompt` vazio, porque a conta já é conhecida
/// e não há necessidade de abrir UI nenhuma.
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

  @override
  Future<ContaAutenticada> entrarInterativo(List<String> escopos) {
    final resultado = Completer<ContaAutenticada>();

    Future<ContaAutenticada> concluir(
      String token,
      int? expiresIn,
      List<String> escoposConcedidos,
    ) async {
      final resposta = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resposta.statusCode != 200) {
        throw StateError('Não foi possível obter os dados da conta Google.');
      }
      final identidade = jsonDecode(resposta.body) as Map<String, dynamic>;
      final email = identidade['email'] as String;
      final nome = identidade['name'] as String? ?? email;

      _tokens[email] = _TokenEmCache(
        token: token,
        expiraEm: DateTime.now().add(
          Duration(seconds: expiresIn ?? 3600) - _margemExpiracao,
        ),
        escopos: escoposConcedidos.toSet(),
      );

      return ContaAutenticada(
        nomeUsuario: nome,
        email: email,
        obterHeaders: () => _token(email, escopos).then(_cabecalhos),
      );
    }

    // Único popup do login: pede conta e consentimento dos escopos juntos.
    // `requestAccessToken()` é chamado abaixo sem nenhum `await` antes —
    // continua dentro da mesma pilha síncrona do toque do usuário, o que o
    // navegador exige para não tratar o popup como bloqueado.
    final cliente = oauth2.oauth2.initTokenClient(
      oauth2.TokenClientConfig(
        client_id: _clientId,
        scope: escopos,
        prompt: 'select_account',
        include_granted_scopes: true,
        callback: (resposta) {
          final erro = resposta.error;
          final token = resposta.access_token;
          if (erro != null || token == null) {
            resultado.completeError(
              StateError(
                'Não foi possível obter autorização do Google'
                '${erro == null ? '' : ' ($erro)'}.',
              ),
            );
            return;
          }
          unawaited(
            concluir(
              token,
              resposta.expires_in,
              resposta.scope,
            ).then(resultado.complete, onError: resultado.completeError),
          );
        },
        error_callback: (erro) {
          developer.log(
            'Login interativo do Google falhou: ${erro?.type} ${erro?.message}',
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
