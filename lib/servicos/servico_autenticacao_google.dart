import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// `false` no web: o Google Identity Services só aceita login iniciado pelo
  /// widget que ele mesmo renderiza, então `entrar()` não pode ser chamado —
  /// a `TelaLogin` mostra o botão do Google e o login chega pelos streams.
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

  @override
  Stream<ContaGoogleConectada> get contasConectadas => _contasController.stream;

  @override
  Stream<SessaoGoogle> get sessoesConectadas => _sessoesController.stream;

  @override
  bool get suportaLoginProgramatico =>
      GoogleSignIn.instance.supportsAuthenticate();

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

  /// Cliente usado para pedir os tokens de autorização.
  ///
  /// No web usamos o cliente **sem** vínculo com a conta de propósito: quando
  /// recebe um hint de usuário, `google_sign_in_web` monta o token client com
  /// `prompt: 'select_account'` (ver `src/gis_client.dart`), o que reabre a tela
  /// de escolha de conta logo depois de o usuário já ter escolhido a conta no
  /// botão do Google — duas seleções para um único login. Sem o hint, o
  /// `prompt` fica vazio e o Google reaproveita a sessão ativa, só mostrando o
  /// seletor quando existe ambiguidade real entre contas conectadas.
  ///
  /// Fora do web mantemos o cliente da conta, que é a forma recomendada e já
  /// funciona bem no fluxo nativo.
  GoogleSignInAuthorizationClient _clienteAutorizacao(
    GoogleSignInAccount conta,
  ) {
    return kIsWeb
        ? GoogleSignIn.instance.authorizationClient
        : conta.authorizationClient;
  }

  /// Garante que os escopos estejam autorizados antes de considerar a sessão
  /// válida. Autenticação (quem é o usuário) e autorização (acesso ao
  /// Drive/Sheets) são etapas separadas na API 7.x — foi exatamente essa
  /// distinção que faltava na 6.x e deixava a sessão sem access token.
  Future<void> _garantirAutorizacao(GoogleSignInAccount conta) async {
    final cliente = _clienteAutorizacao(conta);
    final existente = await cliente.authorizationForScopes(escoposGoogleFisio);
    if (existente != null) return;
    await cliente.authorizeScopes(escoposGoogleFisio);
  }

  SessaoGoogle _criarSessao(GoogleSignInAccount conta) {
    // Resolvido a cada requisição: no web o access token expira em 1h e não é
    // renovado sozinho, então pedir os headers na hora do uso permite que
    // `authorizationHeaders` devolva um token novo quando o antigo vencer.
    Future<Map<String, String>> obterHeaders() async {
      final headers = await _clienteAutorizacao(
        conta,
      ).authorizationHeaders(escoposGoogleFisio);
      if (headers == null) {
        throw StateError('Não foi possível obter autorização do Google.');
      }
      return headers;
    }

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
    final headers = await _clienteAutorizacao(
      conta,
    ).authorizationForScopes(escoposGoogleFisio);
    if (headers == null) return null;

    return _criarSessao(conta);
  }

  @override
  Future<SessaoGoogle> entrar() async {
    await inicializar();

    if (!suportaLoginProgramatico) {
      throw StateError(
        'Nesta plataforma o login só pode ser iniciado pelo botão do Google.',
      );
    }

    final conta = await GoogleSignIn.instance.authenticate(
      scopeHint: escoposGoogleFisio,
    );
    await _garantirAutorizacao(conta);
    return _criarSessao(conta);
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
