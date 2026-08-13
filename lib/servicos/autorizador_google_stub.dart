import 'package:google_sign_in/google_sign_in.dart';

import 'autorizador_google_base.dart';

/// Implementação para as plataformas nativas (e para os testes, que rodam na
/// VM do Dart).
///
/// Aqui `conta.authorizationClient` é o caminho recomendado e já validado: o
/// Credential Manager devolve a conta e a autorização sai sem nenhuma tela
/// adicional quando o consentimento já foi dado.
AutorizadorGoogle criarAutorizadorGoogle({required String clientIdWeb}) =>
    AutorizadorGoogleNativo();

class AutorizadorGoogleNativo implements AutorizadorGoogle {
  @override
  Future<void> garantirAutorizacao(
    GoogleSignInAccount conta,
    List<String> escopos,
  ) async {
    final cliente = conta.authorizationClient;
    final existente = await cliente.authorizationForScopes(escopos);
    if (existente != null) return;
    await cliente.authorizeScopes(escopos);
  }

  @override
  Future<Map<String, String>?> headersSeAutorizado(
    GoogleSignInAccount conta,
    List<String> escopos,
  ) {
    return conta.authorizationClient.authorizationHeaders(escopos);
  }

  @override
  Future<Map<String, String>> headers(
    GoogleSignInAccount conta,
    List<String> escopos,
  ) async {
    final headers = await conta.authorizationClient.authorizationHeaders(
      escopos,
    );
    if (headers == null) {
      throw StateError('Não foi possível obter autorização do Google.');
    }
    return headers;
  }

  @override
  Future<ContaAutenticada> entrarInterativo(List<String> escopos) async {
    final conta = await GoogleSignIn.instance.authenticate(
      scopeHint: escopos,
    );
    await garantirAutorizacao(conta, escopos);
    return ContaAutenticada(
      nomeUsuario: conta.displayName ?? conta.email,
      email: conta.email,
      obterHeaders: () => headers(conta, escopos),
    );
  }
}
