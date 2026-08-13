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

  /// Login interativo completo — identidade + autorização dos escopos — num
  /// único fluxo, disparado pelo toque do usuário no botão do App.
  ///
  /// Cada plataforma resolve à sua maneira: no nativo, `GoogleSignIn.authenticate()`
  /// seguido de `authorizationClient`, sem UI extra. No web, um único popup do
  /// OAuth2 do GIS cobre escolha de conta **e** consentimento — ver
  /// `autorizador_google_web.dart` para o porquê de não usar mais o botão de
  /// identidade renderizado pelo GIS.
  Future<ContaAutenticada> entrarInterativo(List<String> escopos);
}

/// Resultado de [AutorizadorGoogle.entrarInterativo]: identidade da conta e
/// como obter cabeçalhos de autorização para ela.
class ContaAutenticada {
  final String nomeUsuario;
  final String email;
  final Future<Map<String, String>> Function() obterHeaders;

  const ContaAutenticada({
    required this.nomeUsuario,
    required this.email,
    required this.obterHeaders,
  });
}
