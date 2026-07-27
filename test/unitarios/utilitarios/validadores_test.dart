import 'package:flutter_test/flutter_test.dart';
import 'package:alta/utilitarios/validadores.dart';

void main() {
  group('Validadores.validarCPF', () {
    test('aceita CPF válido com formatação', () {
      expect(Validadores.validarCPF('111.444.777-35'), isTrue);
    });

    test('aceita CPF válido sem formatação', () {
      expect(Validadores.validarCPF('11144477735'), isTrue);
    });

    test('rejeita CPF com dígitos repetidos', () {
      expect(Validadores.validarCPF('111.111.111-11'), isFalse);
    });

    test('rejeita CPF com número de dígitos errado', () {
      expect(Validadores.validarCPF('123.456.789'), isFalse);
    });

    test('rejeita CPF com dígito verificador inválido', () {
      expect(Validadores.validarCPF('123.456.789-00'), isFalse);
    });

    test('rejeita CPF vazio', () {
      expect(Validadores.validarCPF(''), isFalse);
    });

    test('rejeita CPF com apenas pontos e hífens', () {
      expect(Validadores.validarCPF('...-'), isFalse);
    });

    test('retorna mensagem de erro para CPF inválido', () {
      final erro = Validadores.mensagemErroCPF('123.456.789-00');
      expect(erro, isNotNull);
      expect(erro, contains('inválido'));
    });

    test('retorna null para CPF válido', () {
      final erro = Validadores.mensagemErroCPF('111.444.777-35');
      expect(erro, isNull);
    });

    test('retorna mensagem específica para CPF vazio', () {
      final erro = Validadores.mensagemErroCPF('');
      expect(erro, 'CPF é obrigatório');
    });
  });

  group('Validadores.validarTelefone', () {
    test('aceita telefone com 10 dígitos', () {
      expect(Validadores.validarTelefone('(11) 3333-4444'), isTrue);
    });

    test('aceita telefone com 11 dígitos', () {
      expect(Validadores.validarTelefone('(11) 99999-9999'), isTrue);
    });

    test('aceita telefone sem formatação com 10 dígitos', () {
      expect(Validadores.validarTelefone('1133334444'), isTrue);
    });

    test('aceita telefone sem formatação com 11 dígitos', () {
      expect(Validadores.validarTelefone('11999999999'), isTrue);
    });

    test('rejeita telefone com menos de 10 dígitos', () {
      expect(Validadores.validarTelefone('1133'), isFalse);
    });

    test('rejeita telefone com mais de 11 dígitos', () {
      expect(Validadores.validarTelefone('119999999999999'), isFalse);
    });

    test('rejeita telefone começando com 0', () {
      expect(Validadores.validarTelefone('0133334444'), isFalse);
    });

    test('rejeita DDD inválido (menor que 11)', () {
      expect(Validadores.validarTelefone('(10) 99999-9999'), isFalse);
    });

    test('retorna mensagem de erro para telefone inválido', () {
      final erro = Validadores.mensagemErroTelefone('1199');
      expect(erro, isNotNull);
    });

    test('retorna null para telefone válido', () {
      final erro = Validadores.mensagemErroTelefone('(11) 99999-9999');
      expect(erro, isNull);
    });
  });

  group('Validadores.validarDataNascimento', () {
    test('aceita data de nascimento no passado', () {
      final data = DateTime(1990, 5, 15);
      expect(Validadores.validarDataNascimento(data), isTrue);
    });

    test('aceita data de nascimento hoje', () {
      final hoje = DateTime.now();
      expect(Validadores.validarDataNascimento(hoje), isTrue);
    });

    test('rejeita data de nascimento no futuro', () {
      final futuro = DateTime.now().add(const Duration(days: 1));
      expect(Validadores.validarDataNascimento(futuro), isFalse);
    });

    test('aceita data muito no passado', () {
      final antiguo = DateTime(1900, 1, 1);
      expect(Validadores.validarDataNascimento(antiguo), isTrue);
    });

    test('retorna mensagem de erro para data inválida', () {
      final futuro = DateTime.now().add(const Duration(days: 1));
      final erro = Validadores.mensagemErroDataNascimento(futuro);
      expect(erro, isNotNull);
    });

    test('retorna null para data válida', () {
      final valida = DateTime(1990, 5, 15);
      final erro = Validadores.mensagemErroDataNascimento(valida);
      expect(erro, isNull);
    });

    test('retorna mensagem para data nula', () {
      final erro = Validadores.mensagemErroDataNascimento(null);
      expect(erro, 'Data de nascimento é obrigatória');
    });
  });

  group('Validadores.validarEndereco', () {
    test('aceita endereço válido', () {
      expect(Validadores.validarEndereco('Rua das Flores, 123'), isTrue);
    });

    test('rejeita endereço com menos de 5 caracteres', () {
      expect(Validadores.validarEndereco('Rua'), isFalse);
    });

    test('rejeita endereço vazio', () {
      expect(Validadores.validarEndereco(''), isFalse);
    });

    test('rejeita endereço com apenas espaços', () {
      expect(Validadores.validarEndereco('     '), isFalse);
    });

    test('aceita endereço com 5 caracteres exatos', () {
      expect(Validadores.validarEndereco('Rua1'), isFalse); // Ainda < 5
      expect(Validadores.validarEndereco('Rua 1'), isTrue); // Agora = 5
    });

    test('retorna mensagem de erro para endereço inválido', () {
      final erro = Validadores.mensagemErroEndereco('Rua');
      expect(erro, isNotNull);
    });

    test('retorna null para endereço válido', () {
      final erro = Validadores.mensagemErroEndereco('Rua das Flores, 123');
      expect(erro, isNull);
    });
  });

  group('Validadores.validarNome', () {
    test('aceita nome com primeiro e último nome', () {
      expect(Validadores.validarNome('João Silva'), isTrue);
    });

    test('aceita nome com múltiplos nomes', () {
      expect(Validadores.validarNome('João Pedro Silva Santos'), isTrue);
    });

    test('rejeita nome com apenas um nome', () {
      expect(Validadores.validarNome('João'), isFalse);
    });

    test('rejeita nome vazio', () {
      expect(Validadores.validarNome(''), isFalse);
    });

    test('rejeita nome com espaços apenas', () {
      expect(Validadores.validarNome('     '), isFalse);
    });

    test('rejeita nome onde parte tem menos de 2 caracteres', () {
      expect(Validadores.validarNome('J Silva'), isFalse);
    });

    test('rejeita nome onde última parte tem menos de 2 caracteres', () {
      expect(Validadores.validarNome('João S'), isFalse);
    });

    test('aceita nome com caracteres acentuados', () {
      expect(Validadores.validarNome('José Peçanha'), isTrue);
    });

    test('retorna mensagem de erro para nome inválido', () {
      final erro = Validadores.mensagemErroNome('João');
      expect(erro, isNotNull);
    });

    test('retorna null para nome válido', () {
      final erro = Validadores.mensagemErroNome('João Silva');
      expect(erro, isNull);
    });
  });

  group('Integração: múltiplos validadores', () {
    test('pessoa completa e válida', () {
      const nome = 'Maria Santos';
      const cpf = '111.444.777-35';
      const telefone = '(11) 99999-9999';
      final dataNascimento = DateTime(1990, 5, 15);
      const endereco = 'Rua das Flores, 123';

      expect(Validadores.validarNome(nome), isTrue);
      expect(Validadores.validarCPF(cpf), isTrue);
      expect(Validadores.validarTelefone(telefone), isTrue);
      expect(Validadores.validarDataNascimento(dataNascimento), isTrue);
      expect(Validadores.validarEndereco(endereco), isTrue);
    });

    test('pessoa com alguns dados inválidos', () {
      const nome = 'Maria';
      const cpf = '111.444.777-35';
      const telefone = '1199'; // Inválido
      final dataNascimento = DateTime(1990, 5, 15);
      const endereco = 'Rua';

      expect(Validadores.validarNome(nome), isFalse); // Falta sobrenome
      expect(Validadores.validarCPF(cpf), isTrue);
      expect(Validadores.validarTelefone(telefone), isFalse);
      expect(Validadores.validarDataNascimento(dataNascimento), isTrue);
      expect(Validadores.validarEndereco(endereco), isFalse); // Muito curto
    });
  });
}
