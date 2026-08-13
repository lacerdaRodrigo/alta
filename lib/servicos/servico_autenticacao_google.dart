import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'autorizador_google.dart';
import 'cliente_google_autenticado.dart';

const googleOAuthClientIdWeb = String.fromEnvironment(
  'GOOGLE_OAUTH_CLIENT_ID_WEB',
  defaultValue: '',
);

/// Escopos OAuth exigidos pelo app.
///
/// `spreadsheets` é necessário para a Sheets API; `drive.file` dá acesso apenas
/// aos arquivos criados pelo próprio app (usado para localizar a planilha).
const escoposGoogleFisio = <String>[
  'email',
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/spreadsheets',
];

class SessaoGoogle {
  final String nomeUsuario;
  final String email;
  final Future<Map<String, String>> Function() obterHeaders;

  const SessaoGoogle({
    required this.nomeUsuario,
    required this.email,
    required this.obterHeaders,
  });

  ClienteGoogleAutenticado criarCliente() {
    return ClienteGoogleAutenticado(obterHeaders);
  }
}

class ContaGoogleConectada {
  final String nomeUsuario;
  final String email;

  const ContaGoogleConectada({required this.nomeUsuario, required this.email});
}

abstract class ServicoAutenticacaoGoogle {
  Stream<ContaGoogleConectada> get contasConectadas;
  Stream<SessaoGoogle> get sessoesConectadas;

  /// Se `entrar()` pode ser chamado diretamente pelo toque no botão do App.
  ///
  /// `true` em todas as plataformas suportadas hoje: no nativo via
  /// `GoogleSignIn.authenticate()`, no web via um popup do OAuth2 do GIS
  /// (`autorizador_google_web.dart`). Existe como sinal defensivo para uma
  /// futura plataforma que exija outro fluxo — quando isso acontecer,
  /// `TelaLogin` já sabe recuar sem travar o botão.
  bool get suportaLoginProgramatico;

  Future<void> inicializar();
  Future<SessaoGoogle?> tentarRestaurarSessao();
  Future<SessaoGoogle> entrar();
  Future<void> sair();
}

class ServicoAutenticacaoGoogleReal implements ServicoAutenticacaoGoogle {
  final _contasController = StreamController<ContaGoogleConectada>.broadcast();
  final _sessoesController = StreamController<SessaoGoogle>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _assinaturaEventos;
  Future<void>? _inicializacao;

  /// Quem obtém os tokens das APIs Google. A implementação vem por import
  /// condicional: no web fala direto com o GIS para não reabrir o seletor de
  /// contas; fora dele usa `conta.authorizationClient`.
  final AutorizadorGoogle _autorizador = criarAutorizadorGoogle(
    clientIdWeb: googleOAuthClientIdWeb,
  );

  @override
  Stream<ContaGoogleConectada> get contasConectadas => _contasController.stream;

  @override
  Stream<SessaoGoogle> get sessoesConectadas => _sessoesController.stream;

  @override
  bool get suportaLoginProgramatico => true;

  @override
  Future<void> inicializar() {
    // `initialize()` só pode rodar uma vez; guardar o Future evita que chamadas
    // concorrentes (restauração de sessão + toque no botão) inicializem duas
    // vezes — no web isso aparece como
    // "google.accounts.id.initialize() is called multiple times".
    return _inicializacao ??= _inicializar();
  }

  Future<void> _inicializar() async {
    if (googleOAuthClientIdWeb.isEmpty) {
      throw StateError(
        'GOOGLE_OAUTH_CLIENT_ID_WEB não foi definido. '
        'Configure a variável de ambiente ou execute:\n'
        'flutter run --dart-define=GOOGLE_OAUTH_CLIENT_ID_WEB=SEU_CLIENT_ID',
      );
    }

    await GoogleSignIn.instance.initialize(
      // No web o clientId identifica a aplicação; no Android ele vem do
      // google-services.json e o mesmo ID web entra como `serverClientId`,
      // necessário para obter access token das APIs Google.
      clientId: kIsWeb ? googleOAuthClientIdWeb : null,
      serverClientId: kIsWeb ? null : googleOAuthClientIdWeb,
    );

    _assinaturaEventos = GoogleSignIn.instance.authenticationEvents.listen(
      _tratarEvento,
      onError: _contasController.addError,
    );
  }

  Future<void> _tratarEvento(GoogleSignInAuthenticationEvent evento) async {
    switch (evento) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        await _publicarSessao(user);
      case GoogleSignInAuthenticationEventSignOut():
        break;
    }
  }

  /// Publica a conta e, em seguida, a sessão autorizada.
  ///
  /// A ordem importa: só a sessão liga `estaAutenticado` no notificador, então
  /// deixá-la por último garante uma única notificação de "entrou" por login.
  Future<void> _publicarSessao(GoogleSignInAccount conta) async {
    try {
      await _garantirAutorizacao(conta);
    } catch (e, st) {
      developer.log(
        'Falha ao autorizar escopos do Google',
        error: e,
        stackTrace: st,
        name: 'ServicoAutenticacaoGoogle',
      );
      _sessoesController.addError(e, st);
      return;
    }

    _contasController.add(
      ContaGoogleConectada(
        nomeUsuario: conta.displayName ?? conta.email,
        email: conta.email,
      ),
    );
    _sessoesController.add(_criarSessao(conta));
  }

  /// Garante que os escopos estejam autorizados antes de considerar a sessão
  /// válida. Autenticação (quem é o usuário) e autorização (acesso ao
  /// Drive/Sheets) são etapas separadas na API 7.x — foi exatamente essa
  /// distinção que faltava na 6.x e deixava a sessão sem access token.
  Future<void> _garantirAutorizacao(GoogleSignInAccount conta) {
    return _autorizador.garantirAutorizacao(conta, escoposGoogleFisio);
  }

  SessaoGoogle _criarSessao(GoogleSignInAccount conta) {
    // Resolvido a cada requisição: no web o access token expira em 1h e não é
    // renovado sozinho, então pedir os headers na hora do uso permite obter um
    // token novo quando o antigo vencer.
    Future<Map<String, String>> obterHeaders() =>
        _autorizador.headers(conta, escoposGoogleFisio);

    return SessaoGoogle(
      nomeUsuario: conta.displayName ?? conta.email,
      email: conta.email,
      obterHeaders: obterHeaders,
    );
  }

  @override
  Future<SessaoGoogle?> tentarRestaurarSessao() async {
    await inicializar();

    final conta = await GoogleSignIn.instance
        .attemptLightweightAuthentication();
    if (conta == null) return null;

    // A restauração leve devolve identidade; a autorização pode ter expirado.
    // Validar aqui evita entregar uma sessão que falharia na primeira chamada
    // à API.
    final headers = await _autorizador.headersSeAutorizado(
      conta,
      escoposGoogleFisio,
    );
    if (headers == null) return null;

    return _criarSessao(conta);
  }

  @override
  Future<SessaoGoogle> entrar() async {
    await inicializar();

    final conta = await _autorizador.entrarInterativo(escoposGoogleFisio);
    final sessao = SessaoGoogle(
      nomeUsuario: conta.nomeUsuario,
      email: conta.email,
      obterHeaders: conta.obterHeaders,
    );

    // No nativo, `GoogleSignIn.authenticate()` (chamado dentro de
    // `entrarInterativo`) já dispara `authenticationEvents`, que
    // `_tratarEvento` escuta e publica sozinho via `_publicarSessao` —
    // publicar de novo aqui duplicaria a notificação. No web não existe
    // esse evento automático: o login não passa mais pelo `GoogleSignIn`
    // (ver `autorizador_google_web.dart`), então é aqui que a sessão
    // precisa ser publicada.
    if (kIsWeb) {
      _contasController.add(
        ContaGoogleConectada(nomeUsuario: conta.nomeUsuario, email: conta.email),
      );
      _sessoesController.add(sessao);
    }

    return sessao;
  }

  @override
  Future<void> sair() async {
    if (_inicializacao == null) return;
    await GoogleSignIn.instance.signOut();
  }

  @visibleForTesting
  Future<void> descartar() async {
    await _assinaturaEventos?.cancel();
    await _contasController.close();
    await _sessoesController.close();
  }
}
