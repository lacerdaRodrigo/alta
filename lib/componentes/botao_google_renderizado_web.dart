import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

/// Botão oficial do Google Identity Services. Ver `botao_google_renderizado.dart`.
///
/// Renderizado no tamanho grande e retangular para preencher a área do botão
/// visual do app, que fica por baixo: o clique precisa cair sobre este widget,
/// não sobre o desenho.
Widget construirBotaoGoogleRenderizado({double? larguraMinima}) {
  return google_web.renderButton(
    configuration: google_web.GSIButtonConfiguration(
      type: google_web.GSIButtonType.standard,
      theme: google_web.GSIButtonTheme.outline,
      size: google_web.GSIButtonSize.large,
      text: google_web.GSIButtonText.continueWith,
      shape: google_web.GSIButtonShape.rectangular,
      logoAlignment: google_web.GSIButtonLogoAlignment.left,
      minimumWidth: larguraMinima,
    ),
  );
}
