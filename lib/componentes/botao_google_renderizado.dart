/// Botão de login renderizado pelo Google Identity Services.
///
/// No web, o GIS só aceita login iniciado pelo widget que ele mesmo renderiza —
/// `GoogleSignIn.authenticate()` lança `UnsupportedError` e
/// `supportsAuthenticate()` devolve `false`. Fora do web nada é renderizado,
/// porque o login é disparado programaticamente por `entrar()`.
///
/// O import condicional mantém `package:google_sign_in_web` fora do build
/// Android/iOS e dos testes, que rodam na VM do Dart.
library;

export 'botao_google_renderizado_stub.dart'
    if (dart.library.js_interop) 'botao_google_renderizado_web.dart';
