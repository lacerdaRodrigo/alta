import 'dart:developer' as developer;

import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import 'versao_esquema.dart';

class ServicoGoogleSheets {
  static const nomeBanco = '__saas_fisio_db__';

  /// Versão do esquema suportada por esta classe de serviço
  static const int versaoEsquema = VersaoEsquema.versaoAtual;

  static const cabecalhos = <String, List<String>>{
    'Pacientes': [
      'ID_Paciente',
      'Nome',
      'Telefone',
      'Data_Nascimento',
      'CPF',
      'Endereco',
      'Queixa_Principal',
      'Hist_Doenca_Atual',
      'Hist_Pregresso',
      'Ocupacao',
      'Situacao',
      'Data_Cadastro',
      'Genero',
      'Dor',
      'Comorbidades',
      'Medicamentos',
      'Alergias',
      'Cirurgias',
      'Habitos_Vida',
    ],
    'Agenda': [
      'ID_Agendamento',
      'ID_Paciente',
      'Data',
      'Hora_Inicio',
      'Hora_Fim',
      'Valor_Sessao',
      'Observacoes',
      'Situacao',
      'Data_Criacao',
    ],
    'Evolucoes': [
      'ID_Evolucao',
      'ID_Paciente',
      'ID_Agendamento',
      'Data_Atendimento',
      'Evolucao_Texto',
      'Data_Registro',
      'Local_Atendimento',
      'Status_Presenca',
      'Dor_Sessao',
      'Horario_Inicio_Real',
      'Horario_Fim_Real',
      'Condicao_Paciente',
      'Pressao_Arterial',
      'Frequencia_Cardiaca',
    ],
    'Configuracoes': ['Chave', 'Valor'],
    'Auditoria': ['ID_Log', 'Data_Hora', 'Operacao', 'Detalhes'],
  };

  final sheets.SheetsApi _api;

  ServicoGoogleSheets(http.Client cliente) : _api = sheets.SheetsApi(cliente);

  Future<String> criarPlanilhaBanco() async {
    final planilha = await _api.spreadsheets.create(
      sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: nomeBanco),
        sheets: [
          for (final aba in cabecalhos.keys)
            sheets.Sheet(properties: sheets.SheetProperties(title: aba)),
          sheets.Sheet(properties: sheets.SheetProperties(title: 'Versao')),
        ],
      ),
      $fields: 'spreadsheetId',
    );

    final id = planilha.spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Não foi possível criar a planilha de dados.');
    }

    await garantirCabecalhos(id);
    return id;
  }

  Future<void> garantirEstrutura(String planilhaId) async {
    final planilha = await _api.spreadsheets.get(
      planilhaId,
      $fields: 'sheets(properties(title))',
    );
    final abasExistentes =
        planilha.sheets
            ?.map((aba) => aba.properties?.title)
            .whereType<String>()
            .toSet() ??
        <String>{};

    final requests = <sheets.Request>[];
    for (final aba in cabecalhos.keys) {
      if (!abasExistentes.contains(aba)) {
        requests.add(
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(title: aba),
            ),
          ),
        );
      }
    }

    if (requests.isNotEmpty) {
      await _api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: requests),
        planilhaId,
      );
    }

    await garantirCabecalhos(planilhaId);
  }

  Future<void> garantirCabecalhos(String planilhaId) async {
    for (final entrada in cabecalhos.entries) {
      await atualizarLinha(
        planilhaId,
        '${entrada.key}!A1:${_coluna(entrada.value.length)}1',
        entrada.value,
      );
    }
  }

  Future<List<List<String>>> lerAba(String planilhaId, String aba) async {
    final resposta = await _api.spreadsheets.values.get(
      planilhaId,
      '$aba!A2:Z',
    );
    final valores = resposta.values ?? [];
    return valores
        .where(
          (linha) => linha.any((valor) => valor.toString().trim().isNotEmpty),
        )
        .map((linha) => [for (final valor in linha) valor.toString()])
        .toList();
  }

  Future<void> inserirLinha(
    String planilhaId,
    String aba,
    List<Object?> valores,
  ) async {
    await _api.spreadsheets.values.append(
      sheets.ValueRange(values: [valores]),
      planilhaId,
      '$aba!A:Z',
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  Future<void> atualizarLinha(
    String planilhaId,
    String range,
    List<Object?> valores,
  ) async {
    await _api.spreadsheets.values.update(
      sheets.ValueRange(values: [valores]),
      planilhaId,
      range,
      valueInputOption: 'USER_ENTERED',
    );
  }

  /// Lê a versão do esquema armazenada na planilha
  /// Retorna 1 por padrão se a aba "Versao" não existir (planilhas antigas)
  Future<int> lerVersaoEsquema(String planilhaId) async {
    try {
      final resposta = await _api.spreadsheets.values.get(
        planilhaId,
        'Versao!B1',
      );

      final valores = resposta.values;
      if (valores == null || valores.isEmpty) {
        developer.log(
          'Aba Versao não encontrada ou vazia. Assumindo versão 1.',
          name: 'ServicoGoogleSheets',
        );
        return 1;
      }

      // `values` vem como lista de linhas: [[valor]]. Usar `valores[0]` direto
      // dava "[1]" no `toString()`, o parse falhava e **toda** planilha era
      // tratada como versão 1 — inclusive uma de versão futura, que deveria
      // ser recusada por `validarVersao`.
      final primeiraLinha = valores.first;
      final versaoStr = primeiraLinha.isEmpty
          ? ''
          : primeiraLinha.first.toString().trim();
      final versao = int.tryParse(versaoStr);

      if (versao == null) {
        developer.log(
          'Versão inválida: "$versaoStr". Assumindo versão 1.',
          name: 'ServicoGoogleSheets',
        );
        return 1;
      }

      return versao;
    } catch (e, st) {
      developer.log(
        'Erro ao ler versão de esquema',
        error: e,
        stackTrace: st,
        name: 'ServicoGoogleSheets',
      );
      return 1; // Assumir versão 1 se houver erro
    }
  }

  /// Valida se a versão da planilha é compatível com este app
  /// Lança exceção se incompatível
  Future<void> validarVersao(String planilhaId) async {
    final versaoSheets = await lerVersaoEsquema(planilhaId);
    final mensagem = VersaoEsquema.validar(versaoSheets);

    if (mensagem != null) {
      throw StateError(mensagem);
    }

    developer.log(
      'Versão de esquema compatível: $versaoSheets',
      name: 'ServicoGoogleSheets',
    );
  }

  /// Salva a versão do esquema na planilha
  /// Cria a aba "Versao" se não existir
  Future<void> salvarVersaoEsquema(String planilhaId) async {
    try {
      // Tenta atualizar a célula de versão
      await atualizarLinha(
        planilhaId,
        'Versao!A1:B1',
        ['versao', versaoEsquema.toString()],
      );

      developer.log(
        'Versão de esquema salva: $versaoEsquema',
        name: 'ServicoGoogleSheets',
      );
    } catch (e, st) {
      developer.log(
        'Erro ao salvar versão de esquema',
        error: e,
        stackTrace: st,
        name: 'ServicoGoogleSheets',
      );
      rethrow;
    }
  }

  String _coluna(int indice1Base) {
    var indice = indice1Base;
    var resultado = '';
    while (indice > 0) {
      indice--;
      resultado = String.fromCharCode(65 + (indice % 26)) + resultado;
      indice ~/= 26;
    }
    return resultado;
  }
}
