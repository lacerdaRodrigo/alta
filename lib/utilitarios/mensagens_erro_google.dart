import 'package:flutter/services.dart';

/// Traduz erros do Google Sign-In para mensagens úteis na UI.
String mensagemErroLoginGoogle(Object erro) {
  if (erro is StateError && erro.message == 'Login Google cancelado.') {
    return 'Login cancelado.';
  }

  final texto = erro is PlatformException
      ? '${erro.code} ${erro.message} ${erro.details}'
      : erro.toString();

  // O plugin classifica como "cancelado" um erro que não é do usuário: quando o
  // par pacote + SHA-1 não está registrado como cliente OAuth Android, o Google
  // aborta o fluxo e o Android devolve `[16] Account reauth failed`. Tratar isso
  // como desistência esconde um erro de configuração — foi o que aconteceu na
  // migração para `com.rodrigo.alta`.
  final pareceCancelamento = texto.contains('GoogleSignInExceptionCode.canceled');
  if (pareceCancelamento &&
      (texto.contains('reauth failed') || texto.contains('[16]'))) {
    return 'Este app não está registrado para OAuth 2.0. No Google Cloud '
        'Console → Credenciais, crie um cliente OAuth do tipo Android para '
        'com.rodrigo.alta com o SHA-1 da chave que assinou o APK. '
        'Cadastrar a impressão digital só no Firebase não basta.';
  }
  if (pareceCancelamento) {
    return 'Login cancelado.';
  }

  if (texto.contains('12500')) {
    return 'Login Google não configurado para este dispositivo. '
        'Ative o provedor Google em Firebase → Authentication '
        'e confirme o SHA-1 do app no Google Cloud Console.';
  }

  if (RegExp(r'\b10\b|: 10|ApiException: 10').hasMatch(texto)) {
    return 'SHA-1 ou pacote Android não conferem com o cliente OAuth. '
        'Confirme com.rodrigo.alta e o SHA-1 da chave de assinatura no '
        'Google Cloud Console → Credenciais.';
  }

  if (texto.contains('access_denied') || texto.contains('12501')) {
    return 'Permissão negada. Adicione seu e-mail como usuário de teste '
        'na Tela de consentimento OAuth (Google Cloud Console).';
  }

  return 'Falha ao autenticar. Verifique sua conexão e tente novamente.';
}
