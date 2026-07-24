import 'package:flutter/widgets.dart';

/// Fora do web não há botão do Google para renderizar: `entrar()` dispara o
/// fluxo nativo diretamente. Ver `botao_google_renderizado.dart`.
Widget construirBotaoGoogleRenderizado({double? larguraMinima}) {
  return const SizedBox.shrink();
}
