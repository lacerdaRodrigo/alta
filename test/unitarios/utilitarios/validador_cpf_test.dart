import 'package:flutter_test/flutter_test.dart';
import 'package:alta/utilitarios/validador_cpf.dart';

void main() {
  group('ValidadorCpf', () {
    group('validar', () {
      test('deve aceitar um CPF válido sem máscara', () {
        expect(ValidadorCpf.validar('52998224725'), isTrue);
      });

      test('deve aceitar um CPF válido com máscara', () {
        expect(ValidadorCpf.validar('529.982.247-25'), isTrue);
      });

      test('deve rejeitar CPF com todos os dígitos iguais', () {
        expect(ValidadorCpf.validar('111.111.111-11'), isFalse);
        expect(ValidadorCpf.validar('000.000.000-00'), isFalse);
        expect(ValidadorCpf.validar('999.999.999-99'), isFalse);
      });

      test('deve rejeitar CPF com dígitos verificadores incorretos', () {
        expect(ValidadorCpf.validar('529.982.247-26'), isFalse);
        expect(ValidadorCpf.validar('12345678901'), isFalse);
      });

      test('deve rejeitar CPF com quantidade de dígitos incorreta', () {
        expect(ValidadorCpf.validar('123'), isFalse);
        expect(ValidadorCpf.validar(''), isFalse);
        expect(ValidadorCpf.validar('1234567890'), isFalse); // 10 dígitos
      });
    });

    group('formatar', () {
      test('deve aplicar máscara corretamente em string numérica', () {
        expect(ValidadorCpf.formatar('52998224725'), equals('529.982.247-25'));
      });

      test('deve retornar o valor original se não tiver 11 dígitos', () {
        expect(ValidadorCpf.formatar('123'), equals('123'));
      });
    });

    group('removerMascara', () {
      test('deve remover pontos e traço de um CPF formatado', () {
        expect(
          ValidadorCpf.removerMascara('529.982.247-25'),
          equals('52998224725'),
        );
      });

      test('deve retornar string vazia quando recebe vazio', () {
        expect(ValidadorCpf.removerMascara(''), equals(''));
      });
    });
  });
}
