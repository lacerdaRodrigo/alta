import 'package:google_sign_in/google_sign_in.dart';

/// Obtém os tokens de acesso às APIs do Google (Drive/Sheets) para uma conta
/// já autenticada.
///
/// Existe porque **autenticação e autorização são etapas separadas no web** e
/// cada plataforma resolve a segunda de um jeito: no Android o cliente da
/// própria conta (`conta.authorizationClient`) faz tudo sem UI extra; no web o
/// caminho do plugin sempre acaba reabrindo o seletor de contas — ver
/// `autorizador_google_web.dart` para o porquê.
abstract class AutorizadorGoogle {
  /// Autoriza os escopos, abrindo UI se necessário.
  ///
  /// Chamado logo após o login para que a sessão só seja publicada quando já
  /// puder chamar as APIs.
  Future<void> garantirAutorizacao(
    GoogleSignInAccount conta,
    List<String> escopos,
  );

  /// Cabeçalhos de autorização **sem** abrir UI, ou `null` se os escopos ainda
  /// não estão autorizados. Usado ao restaurar sessão.
  Future<Map<String, String>?> headersSeAutorizado(
    GoogleSignInAccount conta,
    List<String> escopos,
  );

  /// Cabeçalhos de autorização para uma requisição às APIs do Google.
  ///
  /// Lança se não for possível obter o token — no web ele expira em 1h e é
  /// renovado aqui, por isso os headers são resolvidos a cada requisição.
  Future<Map<String, String>> headers(
    GoogleSignInAccount conta,
    List<String> escopos,
  );
}
