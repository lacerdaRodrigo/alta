import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'cliente_google_autenticado.dart';

const googleOAuthClientIdWeb = String.fromEnvironment(
  'GOOGLE_OAUTH_CLIENT_ID_WEB',
  defaultValue: '',
);

const escoposGoogleFisio = <String>[
  'email',
  'https://www.googleapis.com/auth/drive.file',
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
  Future<void> inicializar();
  Future<SessaoGoogle?> tentarRestaurarSessao();
  Future<SessaoGoogle> entrar();
  Future<void> sair();
}

GoogleSignIn _criarGoogleSignIn() {
  if (googleOAuthClientIdWeb.isEmpty) {
    throw StateError(
      'GOOGLE_OAUTH_CLIENT_ID_WEB não foi definido. '
      'Configure a variável de ambiente ou execute:\n'
      'flutter run --dart-define=GOOGLE_OAUTH_CLIENT_ID_WEB=SEU_CLIENT_ID'
    );
  }

  if (kIsWeb) {
    return GoogleSignIn(
      clientId: googleOAuthClientIdWeb,
      scopes: escoposGoogleFisio,
    );
  }

  // Android/iOS: clientId vem do google-services.json / GoogleService-Info.plist.
  // serverClientId (OAuth Web) é necessário para obter access token das APIs Google.
  return GoogleSignIn(
    scopes: escoposGoogleFisio,
    serverClientId: googleOAuthClientIdWeb,
  );
}

class ServicoAutenticacaoGoogleReal implements ServicoAutenticacaoGoogle {
  final _contasController = StreamController<ContaGoogleConectada>.broadcast();
  final _sessoesController = StreamController<SessaoGoogle>.broadcast();
  late final GoogleSignIn _googleSignIn = _criarGoogleSignIn();
  bool _inicializado = false;

  @override
  Stream<ContaGoogleConectada> get contasConectadas => _contasController.stream;

  @override
  Stream<SessaoGoogle> get sessoesConectadas => _sessoesController.stream;

  @override
  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;
  }

  @override
  Future<SessaoGoogle?> tentarRestaurarSessao() async {
    await inicializar();

    final conta = await _googleSignIn.signInSilently();
    if (conta == null) return null;

    return _criarSessao(conta);
  }

  @override
  Future<SessaoGoogle> entrar() async {
    await inicializar();

    final conta = await _googleSignIn.signIn();
    if (conta == null) {
      throw StateError('Login Google cancelado.');
    }

    final sessao = _criarSessao(conta);
    // A conta vai primeiro de propósito: cada emissão vira uma mudança de
    // estado em `AutenticacaoNotificador`, e só a sessão liga
    // `estaAutenticado`. Publicando a conta antes, a virada para autenticado é
    // a última notificação do login — nenhum ouvinte reage duas vezes a ela.
    _contasController.add(
      ContaGoogleConectada(
        nomeUsuario: conta.displayName ?? conta.email,
        email: conta.email,
      ),
    );
    _sessoesController.add(sessao);
    return sessao;
  }

  SessaoGoogle _criarSessao(GoogleSignInAccount conta) {
    Future<Map<String, String>> obterHeaders() async {
      final auth = await conta.authentication;
      final token = auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Não foi possível obter autorização do Google.');
      }
      return {'Authorization': 'Bearer $token'};
    }

    return SessaoGoogle(
      nomeUsuario: conta.displayName ?? conta.email,
      email: conta.email,
      obterHeaders: obterHeaders,
    );
  }

  @override
  Future<void> sair() async {
    if (!_inicializado) return;
    await _googleSignIn.signOut();
  }
}
