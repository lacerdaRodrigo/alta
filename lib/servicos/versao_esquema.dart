/// Gerenciamento de versão do esquema das planilhas do Google Sheets.
///
/// Esta classe coordena as versões entre o aplicativo e a estrutura das
/// planilhas armazenadas no Google Sheets. Detecta incompatibilidades e
/// facilita migrações futuras entre versões.
///
/// **Fluxo de versionamento:**
/// 1. App salva versão na aba "Versao" ao criar planilha nova
/// 2. Ao carregar, verifica se versão é compatível
/// 3. Se incompatível, exibe mensagem clara ao usuário
/// 4. Se compatível, carrega dados normalmente
///
/// **Exemplo de uso:**
/// ```dart
/// import 'package:alta/servicos/versao_esquema.dart';
///
/// // Validar versão
/// final resultado = VersaoEsquema.validar(1);
/// if (resultado != null) {
///   print('Erro: $resultado');
/// }
///
/// // Obter índices de colunas
/// final indices = VersaoEsquema.obterIndicesColunas(1);
/// final nomeIndex = indices['nome'];
/// ```
class VersaoEsquema {
  /// Versão atual suportada pelo aplicativo.
  static const int versaoAtual = 1;

  /// Histórico de versões com descrição das mudanças.
  ///
  /// Cada entrada documenta as alterações de estrutura em cada versão.
  /// Útil para rastrear evolution do schema e gerar migration guides.
  static const Map<int, String> historico = {
    1: 'Versão inicial com abas: Pacientes, Agenda, Evolucoes, Configuracoes, Auditoria',
  };

  /// Obtém o mapa de índices de colunas para uma versão específica.
  ///
  /// Mapeia o nome da coluna para seu índice (0-based) na planilha.
  /// Usado pelo parser de dados (ex: `Paciente.deLinhaPlanilha()`) para
  /// buscar colunas por nome em vez de índice hardcoded.
  ///
  /// **Parâmetros:**
  /// - `versao`: Versão do esquema (ex: 1)
  ///
  /// **Retorna:** `Map<String, int>` com mapeamento coluna -> índice
  ///
  /// **Lança:** [UnsupportedError] se versão não é suportada
  ///
  /// **Exemplo:**
  /// ```dart
  /// final indices = VersaoEsquema.obterIndicesColunas(1);
  /// final nomeIndex = indices['nome']; // 1
  /// final cpfIndex = indices['cpf'];   // 4
  /// ```
  static Map<String, int> obterIndicesColunas(int versao) {
    switch (versao) {
      case 1:
        return {
          // Aba: Pacientes
          'idPaciente': 0,
          'nome': 1,
          'telefone': 2,
          'dataNascimento': 3,
          'cpf': 4,
          'endereco': 5,
          'queixaPrincipal': 6,
          'histDoencaAtual': 7,
          'histPregresso': 8,
          'ocupacao': 9,
          'situacao': 10,
          'dataCadastro': 11,
          'genero': 12,
          'dor': 13,
          'comorbidades': 14,
          'medicamentos': 15,
          'alergias': 16,
          'cirurgias': 17,
          'habitosVida': 18,
        };
      default:
        throw UnsupportedError(
          'Versão de esquema $versao não é suportada por este app. '
          'Versão suportada: $versaoAtual',
        );
    }
  }

  /// Valida se uma versão de planilha é compatível com este app.
  ///
  /// Compara a versão da planilha com a versão suportada pelo app e
  /// retorna uma mensagem descritiva se houver incompatibilidade.
  ///
  /// **Parâmetros:**
  /// - `versaoSheets`: Versão da planilha no Google Sheets
  ///
  /// **Retorna:**
  /// - `null` se versão é compatível
  /// - `String` com mensagem de erro se incompatível
  ///
  /// **Exemplo:**
  /// ```dart
  /// final erro = VersaoEsquema.validar(2);
  /// if (erro != null) {
  ///   print('Erro: $erro');
  /// }
  /// ```
  static String? validar(int versaoSheets) {
    if (versaoSheets > versaoAtual) {
      return 'A planilha usa versão $versaoSheets, '
          'mas este app suporta apenas até versão $versaoAtual. '
          'Atualize o app para a versão mais recente.';
    }

    if (versaoSheets < versaoAtual) {
      return 'A planilha usa versão $versaoSheets, '
          'mas este app requer versão $versaoAtual. '
          'Entre em contato com o suporte para migrar sua planilha.';
    }

    return null; // Compatível
  }

  /// Obtém a descrição/changelog de uma versão.
  ///
  /// Procura no [historico] e retorna a descrição das mudanças naquela versão.
  ///
  /// **Parâmetros:**
  /// - `versao`: Versão a consultar
  ///
  /// **Retorna:** Descrição das mudanças ou "Versão desconhecida"
  static String obterDescricao(int versao) {
    return historico[versao] ?? 'Versão desconhecida';
  }

  /// Verifica se uma versão é suportada pelo app.
  ///
  /// Retorna `true` para versões iguais ou menores que [versaoAtual].
  ///
  /// **Parâmetros:**
  /// - `versao`: Versão a verificar
  ///
  /// **Retorna:** `true` se suportada, `false` caso contrário
  static bool ehSuportada(int versao) {
    return versao <= versaoAtual;
  }

  /// Calcula a próxima versão após a fornecida.
  ///
  /// Útil para preparar migrations e planning de futuras versões.
  ///
  /// **Parâmetros:**
  /// - `versaoAtual`: Versão base
  ///
  /// **Retorna:** Versão incrementada (versaoAtual + 1)
  static int obterProximaVersao(int versaoAtual) => versaoAtual + 1;
}
