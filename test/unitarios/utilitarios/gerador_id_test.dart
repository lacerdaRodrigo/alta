import 'package:flutter_test/flutter_test.dart';
import 'package:alta/utilitarios/gerador_id.dart';

void main() {
  group('GeradorId.proximo', () {
    test('lista vazia gera o primeiro ID', () {
      expect(GeradorId.proximo('A', const []), 'A001');
    });

    test('incrementa a partir do maior número existente', () {
      expect(
        GeradorId.proximo('A', const ['A001', 'A002', 'A003']),
        'A004',
      );
    });

    test('usa o maior número mesmo com buracos na numeração', () {
      // length seria 2 -> 'A003' (colisão com existente). max+1 evita isso.
      expect(GeradorId.proximo('A', const ['A001', 'A005']), 'A006');
    });

    test('ignora IDs com prefixo diferente', () {
      expect(GeradorId.proximo('E', const ['A009', 'E002']), 'E003');
    });

    test('ignora sufixos não numéricos', () {
      expect(GeradorId.proximo('A', const ['Axyz', 'A007']), 'A008');
    });

    test('ignora entradas vazias ou só com o prefixo', () {
      expect(GeradorId.proximo('L', const ['', 'L', 'L004']), 'L005');
    });

    test('respeita a largura customizada de padding', () {
      expect(GeradorId.proximo('A', const [], largura: 5), 'A00001');
    });

    test('não trunca números maiores que a largura', () {
      expect(GeradorId.proximo('A', const ['A999'], largura: 3), 'A1000');
    });
  });
}
