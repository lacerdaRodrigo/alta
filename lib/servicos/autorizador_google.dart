/// Ponte para a implementação de autorização de cada plataforma.
///
/// O import condicional mantém `package:google_identity_services_web` (e o
/// `dart:js_interop` que ele usa) fora do build Android/iOS e dos testes, que
/// rodam na VM do Dart.
library;

export 'autorizador_google_base.dart';
export 'autorizador_google_stub.dart'
    if (dart.library.js_interop) 'autorizador_google_web.dart';
