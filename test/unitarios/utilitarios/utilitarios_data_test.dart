import 'package:flutter_test/flutter_test.dart';
import 'package:alta/utilitarios/utilitarios_data.dart';

void main() {
  group('UtilitariosData', () {
    group('calcularIdade', () {
      test(
        'deve retornar a idade correta quando o aniversário já passou no ano',
        () {
          final nascimento = DateTime(1986, 1, 15);
          final referencia = DateTime(2026, 6, 4);
          expect(
            UtilitariosData.calcularIdade(
              nascimento,
              dataReferencia: referencia,
            ),
            equals(40),
          );
        },
      );

      test(
        'deve retornar idade reduzida se o aniversário ainda não chegou no ano',
        () {
          final nascimento = DateTime(1986, 12, 25);
          final referencia = DateTime(2026, 6, 4);
          expect(
            UtilitariosData.calcularIdade(
              nascimento,
              dataReferencia: referencia,
            ),
            equals(39),
          );
        },
      );

      test('deve retornar a idade correta no dia do aniversário', () {
        final nascimento = DateTime(1996, 6, 4);
        final referencia = DateTime(2026, 6, 4);
        expect(
          UtilitariosData.calcularIdade(nascimento, dataReferencia: referencia),
          equals(30),
        );
      });

      test('deve retornar 0 para um bebê nascido no mesmo ano', () {
        final nascimento = DateTime(2026, 1, 1);
        final referencia = DateTime(2026, 6, 4);
        expect(
          UtilitariosData.calcularIdade(nascimento, dataReferencia: referencia),
          equals(0),
        );
      });
    });

    group('ehDataRetroativa', () {
      test('deve retornar verdadeiro para data no passado', () {
        final passado = DateTime(2025, 1, 1, 10, 0);
        final agora = DateTime(2026, 6, 4, 12, 0);
        expect(UtilitariosData.ehDataRetroativa(passado, agora: agora), isTrue);
      });

      test('deve retornar falso para data no futuro', () {
        final futuro = DateTime(2026, 7, 1, 14, 0);
        final agora = DateTime(2026, 6, 4, 12, 0);
        expect(UtilitariosData.ehDataRetroativa(futuro, agora: agora), isFalse);
      });

      test('deve retornar verdadeiro para mesmo dia mas 30 min no passado', () {
        final passado = DateTime(2026, 6, 4, 11, 30);
        final agora = DateTime(2026, 6, 4, 12, 0);
        expect(UtilitariosData.ehDataRetroativa(passado, agora: agora), isTrue);
      });
    });

    group('obterSaudacao', () {
      test('deve retornar Bom dia entre 05h e 11h59', () {
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 5, 0)),
          equals('Bom dia'),
        );
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 11, 59)),
          equals('Bom dia'),
        );
      });

      test('deve retornar Boa tarde entre 12h e 17h59', () {
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 12, 0)),
          equals('Boa tarde'),
        );
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 17, 59)),
          equals('Boa tarde'),
        );
      });

      test('deve retornar Boa noite entre 18h e 04h59', () {
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 18, 0)),
          equals('Boa noite'),
        );
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 23, 59)),
          equals('Boa noite'),
        );
        expect(
          UtilitariosData.obterSaudacao(agora: DateTime(2026, 6, 4, 3, 0)),
          equals('Boa noite'),
        );
      });
    });

    group('formatarDataBr', () {
      test('deve formatar data corretamente no padrão DD/MM/AAAA', () {
        expect(
          UtilitariosData.formatarDataBr(DateTime(2026, 6, 4)),
          equals('04/06/2026'),
        );
      });

      test('deve preencher com zeros à esquerda para dia/mês de um dígito', () {
        expect(
          UtilitariosData.formatarDataBr(DateTime(2026, 1, 5)),
          equals('05/01/2026'),
        );
      });
    });

    group('formatarMesAno', () {
      test('deve retornar mês abreviado e ano', () {
        expect(
          UtilitariosData.formatarMesAno(DateTime(2026, 6, 15)),
          equals('Jun 2026'),
        );
        expect(
          UtilitariosData.formatarMesAno(DateTime(2026, 1, 1)),
          equals('Jan 2026'),
        );
        expect(
          UtilitariosData.formatarMesAno(DateTime(2026, 12, 31)),
          equals('Dez 2026'),
        );
      });
    });

    group('mesmoMesAno', () {
      test('deve retornar true para datas no mesmo mês e ano', () {
        expect(
          UtilitariosData.mesmoMesAno(
            DateTime(2026, 6, 1),
            DateTime(2026, 6, 30),
          ),
          isTrue,
        );
      });

      test('deve retornar false para meses ou anos diferentes', () {
        expect(
          UtilitariosData.mesmoMesAno(
            DateTime(2026, 6, 1),
            DateTime(2026, 7, 1),
          ),
          isFalse,
        );
        expect(
          UtilitariosData.mesmoMesAno(
            DateTime(2026, 6, 1),
            DateTime(2025, 6, 1),
          ),
          isFalse,
        );
      });
    });

    group('ehDataRetroativa — edge cases', () {
      test('mesmo dia, 1 minuto no passado é retroativo', () {
        final agora = DateTime(2026, 6, 20, 21, 6);
        final selecionada = DateTime(2026, 6, 20, 21, 5);
        expect(
          UtilitariosData.ehDataRetroativa(selecionada, agora: agora),
          isTrue,
        );
      });

      test('mesmo dia, 1 minuto no futuro NÃO é retroativo', () {
        final agora = DateTime(2026, 6, 20, 21, 6);
        final selecionada = DateTime(2026, 6, 20, 21, 7);
        expect(
          UtilitariosData.ehDataRetroativa(selecionada, agora: agora),
          isFalse,
        );
      });

      test('mesmo exato instante NÃO é retroativo', () {
        final agora = DateTime(2026, 6, 20, 21, 6);
        expect(
          UtilitariosData.ehDataRetroativa(agora, agora: agora),
          isFalse,
        );
      });

      test('ontem qualquer hora é retroativo', () {
        final agora = DateTime(2026, 6, 20, 8, 0);
        final ontem = DateTime(2026, 6, 19, 23, 59);
        expect(
          UtilitariosData.ehDataRetroativa(ontem, agora: agora),
          isTrue,
        );
      });

      test('amanhã 00:00 NÃO é retroativo', () {
        final agora = DateTime(2026, 6, 20, 23, 59);
        final amanha = DateTime(2026, 6, 21, 0, 0);
        expect(
          UtilitariosData.ehDataRetroativa(amanha, agora: agora),
          isFalse,
        );
      });

      test('mesmo dia meia-noite é retroativo se hora atual é posterior', () {
        final agora = DateTime(2026, 6, 20, 14, 0);
        final meiaNoite = DateTime(2026, 6, 20, 0, 0);
        expect(
          UtilitariosData.ehDataRetroativa(meiaNoite, agora: agora),
          isTrue,
        );
      });
    });

    group('mesmoDia', () {
      test('mesmo dia com horários diferentes retorna true', () {
        expect(
          UtilitariosData.mesmoDia(
            DateTime(2026, 6, 20, 8, 0),
            DateTime(2026, 6, 20, 22, 30),
          ),
          isTrue,
        );
      });

      test('dias diferentes retorna false', () {
        expect(
          UtilitariosData.mesmoDia(
            DateTime(2026, 6, 20),
            DateTime(2026, 6, 21),
          ),
          isFalse,
        );
      });
    });
  });
}
