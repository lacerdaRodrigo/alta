import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alta/utilitarios/mensagens_erro_google.dart';

void main() {
  group('mensagemErroLoginGoogle', () {
    test('cancelamento explícito do serviço vira mensagem curta', () {
      expect(
        mensagemErroLoginGoogle(StateError('Login Google cancelado.')),
        'Login cancelado.',
      );
    });

    test('cancelamento do plugin vira mensagem curta', () {
      // Como o plugin descreve a desistência real do usuário.
      const erro =
          'GoogleSignInException(code GoogleSignInExceptionCode.canceled, '
          'User canceled the sign-in flow., null)';
      expect(mensagemErroLoginGoogle(erro), 'Login cancelado.');
    });

    test(
      'app não registrado no OAuth não é tratado como cancelamento',
      () {
        // O plugin classifica como `canceled`, mas é erro de configuração: o
        // par pacote + SHA-1 não está registrado como cliente OAuth Android.
        const erro =
            'GoogleSignInException(code GoogleSignInExceptionCode.canceled, '
            '[16] Account reauth failed., null)';
        final mensagem = mensagemErroLoginGoogle(erro);

        expect(mensagem, isNot('Login cancelado.'));
        expect(mensagem, contains('não está registrado para OAuth'));
        expect(mensagem, contains('com.rodrigo.alta'));
      },
    );

    test('erro 10 aponta para o cliente OAuth, não para o Firebase', () {
      final mensagem = mensagemErroLoginGoogle(
        PlatformException(code: 'sign_in_failed', message: 'ApiException: 10'),
      );
      expect(mensagem, contains('SHA-1'));
      expect(mensagem, contains('Google Cloud Console'));
    });

    test('erro 12500 orienta configurar o provedor Google', () {
      final mensagem = mensagemErroLoginGoogle(
        PlatformException(code: 'sign_in_failed', message: '12500'),
      );
      expect(mensagem, contains('não configurado'));
    });

    test('permissão negada orienta a lista de usuários de teste', () {
      final mensagem = mensagemErroLoginGoogle('access_denied');
      expect(mensagem, contains('usuário de teste'));
    });

    test('popup bloqueado pelo navegador orienta liberar pop-ups', () {
      final mensagem = mensagemErroLoginGoogle(
        StateError('Não foi possível obter autorização do Google (popup_closed).'),
      );
      expect(mensagem, contains('bloqueou'));
      expect(mensagem, contains('pop-ups'));
    });

    test('erro desconhecido cai na mensagem genérica', () {
      expect(
        mensagemErroLoginGoogle(Exception('socket fechou')),
        'Falha ao autenticar. Verifique sua conexão e tente novamente.',
      );
    });
  });
}
