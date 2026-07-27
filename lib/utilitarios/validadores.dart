import 'utilitarios_data.dart';
import 'validador_cpf.dart';

/// Validadores de entrada de dados para o aplicativo Alta.
///
/// Esta classe fornece métodos estáticos para validar dados de pacientes
/// como CPF, telefone, data de nascimento, endereço e nome.
///
/// **Retorno dos métodos:**
/// - `validarX()` retorna `bool`: true = válido, false = inválido
/// - `mensagemErroX()` retorna `String?`: null = válido, mensagem de erro caso contrário
///
/// **Exemplo de uso:**
/// ```dart
/// import 'package:alta/utilitarios/validadores.dart';
///
/// if (!Validadores.validarCPF('123.456.789-09')) {
///   print('CPF inválido!');
/// }
///
/// final erro = Validadores.mensagemErroCPF('123.456.789-00');
/// if (erro != null) {
///   showError(erro);
/// }
/// ```
class Validadores {
  /// Valida um CPF brasileiro.
  ///
  /// Remove formatação e verifica os dígitos verificadores via [ValidadorCpf].
  ///
  /// **Retorna:** `true` se válido, `false` caso contrário
  static bool validarCPF(String cpf) => ValidadorCpf.validar(cpf);

  /// Valida um telefone brasileiro.
  ///
  /// Aceita telefones com 10 ou 11 dígitos (com ou sem 9 na sequência).
  /// Valida DDD (primeiros 2 dígitos) entre 11 e 99.
  ///
  /// **Aceita:**
  /// - `(11) 3333-4444` (10 dígitos com formatação)
  /// - `(11) 99999-9999` (11 dígitos com formatação)
  /// - `1133334444` (10 dígitos sem formatação)
  /// - `11999999999` (11 dígitos sem formatação)
  /// - Variações com espaços e símbolos
  ///
  /// **Rejeita:**
  /// - `1199` (menos de 10 dígitos)
  /// - `119999999999` (mais de 11 dígitos)
  /// - `0133334444` (começa com 0)
  /// - `(10) 99999-9999` (DDD inválido)
  ///
  /// **Parâmetros:**
  /// - `telefone`: Telefone a validar (com ou sem formatação)
  ///
  /// **Retorna:** `true` se válido, `false` caso contrário
  static bool validarTelefone(String telefone) {
    final apenas = telefone.replaceAll(RegExp(r'\D'), '');

    // Telefone deve ter 10 ou 11 dígitos
    if (apenas.length < 10 || apenas.length > 11) return false;

    // Não pode começar com zero
    if (apenas.startsWith('0')) return false;

    // DDD (primeiros 2 dígitos) deve ser de 11 a 99
    final ddd = int.parse(apenas.substring(0, 2));
    if (ddd < 11 || ddd > 99) return false;

    return true;
  }

  /// Valida uma data de nascimento.
  ///
  /// A data não pode ser no futuro. Aceita qualquer data no passado,
  /// inclusive datas muito antigas.
  ///
  /// **Aceita:**
  /// - `DateTime(1990, 5, 15)` (data no passado)
  /// - `DateTime.now()` (hoje)
  /// - Datas muito antigas (ex: 1900)
  ///
  /// **Rejeita:**
  /// - Datas no futuro
  ///
  /// **Parâmetros:**
  /// - `data`: Data de nascimento a validar
  ///
  /// **Retorna:** `true` se válida, `false` caso contrário
  static bool validarDataNascimento(DateTime data) {
    if (data.isAfter(DateTime.now())) return false;
    return UtilitariosData.calcularIdade(data) >= 0;
  }

  /// Valida um endereço de residência.
  ///
  /// O endereço deve ter no mínimo 5 caracteres (após remover espaços).
  ///
  /// **Aceita:**
  /// - `Rua das Flores, 123` (endereço completo)
  /// - `Av. Brasil, 1000 Apt 42` (com complemento)
  ///
  /// **Rejeita:**
  /// - `Rua` (menos de 5 caracteres)
  /// - `` (vazio)
  /// - `     ` (apenas espaços)
  ///
  /// **Parâmetros:**
  /// - `endereco`: Endereço a validar
  ///
  /// **Retorna:** `true` se válido, `false` caso contrário
  static bool validarEndereco(String endereco) {
    final trimado = endereco.trim();
    return trimado.isNotEmpty && trimado.length >= 5;
  }

  /// Valida um nome completo.
  ///
  /// O nome deve conter pelo menos primeiro e último nome.
  /// Cada parte do nome deve ter no mínimo 2 caracteres.
  ///
  /// **Aceita:**
  /// - `João Silva` (primeiro e último nome)
  /// - `Maria da Silva` (nome com preposição)
  /// - `João Pedro da Silva Santos` (múltiplos nomes)
  /// - `José Peçanha` (com acentuação)
  ///
  /// **Rejeita:**
  /// - `João` (apenas primeiro nome)
  /// - `J Silva` (primeira parte com 1 caractere)
  /// - `João S` (última parte com 1 caractere)
  /// - `` (vazio)
  /// - `     ` (apenas espaços)
  ///
  /// **Parâmetros:**
  /// - `nome`: Nome completo a validar
  ///
  /// **Retorna:** `true` se válido, `false` caso contrário
  static bool validarNome(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));

    // Mínimo 2 partes (primeiro e último nome)
    if (partes.length < 2) return false;

    // Cada parte deve ter pelo menos 2 caracteres
    return partes.every((parte) => parte.length >= 2);
  }

  /// Retorna uma mensagem de erro específica para validação de CPF.
  ///
  /// Útil para exibir mensagens ao usuário em formulários.
  /// Verifica múltiplos critérios de validação e retorna a mensagem apropriada.
  ///
  /// **Retorna:**
  /// - `null` se o CPF for válido
  /// - String descritiva do erro (ex: "CPF é obrigatório", "CPF é inválido")
  ///
  /// **Exemplo:**
  /// ```dart
  /// final erro = Validadores.mensagemErroCPF('123');
  /// if (erro != null) {
  ///   showErrorDialog(erro);
  /// }
  /// ```
  static String? mensagemErroCPF(String cpf) {
    if (cpf.isEmpty) return 'CPF é obrigatório';
    if (cpf.replaceAll(RegExp(r'\D'), '').length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
    if (!validarCPF(cpf)) return 'CPF é inválido';
    return null;
  }

  /// Retorna uma mensagem de erro específica para validação de telefone.
  static String? mensagemErroTelefone(String telefone) {
    if (telefone.isEmpty) return 'Telefone é obrigatório';
    if (!validarTelefone(telefone)) return 'Telefone é inválido';
    return null;
  }

  /// Retorna uma mensagem de erro específica para validação de data.
  static String? mensagemErroDataNascimento(DateTime? data) {
    if (data == null) return 'Data de nascimento é obrigatória';
    if (!validarDataNascimento(data)) {
      return 'Data de nascimento é inválida';
    }
    return null;
  }

  /// Retorna uma mensagem de erro específica para validação de endereço.
  static String? mensagemErroEndereco(String endereco) {
    if (endereco.isEmpty) return 'Endereço é obrigatório';
    if (!validarEndereco(endereco)) {
      return 'Endereço deve ter pelo menos 5 caracteres';
    }
    return null;
  }

  /// Retorna uma mensagem de erro específica para validação de nome.
  static String? mensagemErroNome(String nome) {
    if (nome.isEmpty) return 'Nome é obrigatório';
    if (!validarNome(nome)) {
      return 'Nome deve conter primeiro e último nome, com pelo menos 2 caracteres cada';
    }
    return null;
  }
}
