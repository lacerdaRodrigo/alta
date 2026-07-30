import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../modelos/agendamento.dart';
import '../modelos/evolucao.dart';
import '../modelos/paciente.dart';
import '../utilitarios/gerador_id.dart';
import '../utilitarios/utilitarios_data.dart';
import 'preferencias.dart';
import 'servico_google_drive.dart';
import 'servico_google_sheets.dart';
import 'versao_esquema.dart';

class DadosCarregados {
  final List<Paciente> pacientes;
  final List<Agendamento> agendamentos;
  final List<Evolucao> evolucoes;
  final String valorSessaoPadrao;
  final List<String> logsAuditoria;
  final String planilhaId;

  /// Planilhas com o nome da base encontradas além da que está em uso.
  ///
  /// Vazio no caso normal. Quando não está, o app escolheu a mais recente e a
  /// tela de Configurações avisa — sem isso o usuário não teria como perceber
  /// que passou a gravar em outra planilha.
  final List<PlanilhaBanco> planilhasDuplicadas;

  const DadosCarregados({
    required this.pacientes,
    required this.agendamentos,
    required this.evolucoes,
    required this.valorSessaoPadrao,
    required this.logsAuditoria,
    required this.planilhaId,
    this.planilhasDuplicadas = const [],
  });
}

class RepositorioDadosGoogle {
  final ServicoGoogleDrive _drive;
  final ServicoGoogleSheets _sheets;
  String? _planilhaId;
  List<PlanilhaBanco> _planilhasDuplicadas = const [];

  RepositorioDadosGoogle(http.Client cliente)
    : _drive = ServicoGoogleDrive(cliente),
      _sheets = ServicoGoogleSheets(cliente);

  /// Planilhas com o nome da base que existem além da que está em uso.
  ///
  /// Só é preenchido quando a busca no Drive realmente roda: se o ID veio do
  /// cache ou das preferências, o app nem consulta o Drive e a lista fica
  /// vazia.
  List<PlanilhaBanco> get planilhasDuplicadas => _planilhasDuplicadas;

  void limparCache() {
    _planilhaId = null;
    _planilhasDuplicadas = const [];
    Preferencias.limparPlanilhaId();
  }

  Future<String> obterPlanilhaId() async {
    if (_planilhaId != null) {
      try {
        await _sheets.validarVersao(_planilhaId!);
        return _planilhaId!;
      } catch (e) {
        developer.log(
          'Versão da planilha em cache incompatível, descartando cache',
          error: e,
          name: 'RepositorioDadosGoogle',
        );
        limparCache();
        // Continua o fluxo abaixo para buscar/criar nova planilha
      }
    }

    _planilhaId = await Preferencias.lerPlanilhaId();
    if (_planilhaId != null) {
      try {
        await _sheets.validarVersao(_planilhaId!);
        return _planilhaId!;
      } catch (e) {
        developer.log(
          'Planilha armazenada tem versão incompatível',
          error: e,
          name: 'RepositorioDadosGoogle',
        );
        // Limpar e tentar encontrar outra
        await Preferencias.limparPlanilhaId();
        _planilhaId = null;
      }
    }

    final encontradas = await _drive.buscarPlanilhasBanco();
    _planilhasDuplicadas = encontradas.length > 1
        ? encontradas.sublist(1)
        : const [];
    if (_planilhasDuplicadas.isNotEmpty) {
      developer.log(
        'Há ${encontradas.length} planilhas chamadas '
        '"${ServicoGoogleDrive.nomeBanco}" no Drive. Usando a mais recente '
        '(${encontradas.first.id}); as outras serão ignoradas.',
        name: 'RepositorioDadosGoogle',
      );
    }

    final existente = encontradas.isEmpty ? null : encontradas.first.id;
    if (existente != null) {
      _planilhaId = existente;
      try {
        await _sheets.garantirEstrutura(existente);
        await _sheets.validarVersao(existente);
        await Preferencias.salvarPlanilhaId(existente);
        developer.log(
          'Planilha existente encontrada e validada',
          name: 'RepositorioDadosGoogle',
        );
        return existente;
      } catch (e, st) {
        developer.log(
          'Erro ao validar planilha existente',
          error: e,
          stackTrace: st,
          name: 'RepositorioDadosGoogle',
        );
        _planilhaId = null;
        rethrow;
      }
    }

    // Criar nova planilha
    _planilhaId = await _sheets.criarPlanilhaBanco();
    // Persiste o ID antes de gravar a versão: se a gravação falhar, uma
    // próxima tentativa reaproveita esta planilha em vez de criar outra.
    await Preferencias.salvarPlanilhaId(_planilhaId!);
    await _sheets.salvarVersaoEsquema(_planilhaId!);
    developer.log(
      'Nova planilha criada com versão ${VersaoEsquema.versaoAtual}',
      name: 'RepositorioDadosGoogle',
    );
    return _planilhaId!;
  }

  Future<DadosCarregados> carregarTudo() async {
    try {
      final id = await obterPlanilhaId();

      developer.log(
        'Iniciando carregamento de dados',
        name: 'RepositorioDadosGoogle',
      );

      // Carrega todas as abas em paralelo
      final results = await Future.wait([
        _sheets.lerAba(id, 'Pacientes'),
        _sheets.lerAba(id, 'Agenda'),
        _sheets.lerAba(id, 'Evolucoes'),
        _sheets.lerAba(id, 'Configuracoes'),
        _sheets.lerAba(id, 'Auditoria'),
      ]);

      final pacientes = results[0].map(_pacienteDeLinha).toList();
      final agendamentos = results[1].map(_agendamentoDeLinha).toList();
      final evolucoes = results[2].map(_evolucaoDeLinha).toList();
      final configuracoes = results[3];
      final logs = results[4].reversed.map((linha) {
        final dados = _preencher(linha, 4);
        return '${dados[1]} - ${dados[2]} - ${dados[3]}';
      }).toList();

      developer.log(
        'Dados carregados com sucesso: '
        '${pacientes.length} pacientes, '
        '${agendamentos.length} agendamentos, '
        '${evolucoes.length} evoluções',
        name: 'RepositorioDadosGoogle',
      );

      return DadosCarregados(
        pacientes: pacientes,
        agendamentos: agendamentos,
        evolucoes: evolucoes,
        valorSessaoPadrao: _valorConfiguracao(
          configuracoes,
          'valor_sessao_padrao',
          padrao: '150,00',
        ),
        logsAuditoria: logs,
        planilhaId: id,
        planilhasDuplicadas: _planilhasDuplicadas,
      );
    } catch (e, st) {
      developer.log(
        'Erro ao carregar dados',
        error: e,
        stackTrace: st,
        name: 'RepositorioDadosGoogle',
      );
      rethrow;
    }
  }

  Future<void> salvarPaciente(Paciente paciente) async {
    try {
      final id = await obterPlanilhaId();
      await _sheets.inserirLinha(id, 'Pacientes', _valoresPaciente(paciente));
      await registrarAuditoria(
        'CADASTRO_PACIENTE',
        'Paciente ${paciente.idPaciente} cadastrado.',
      );

      developer.log(
        'Paciente salvo com sucesso: ${paciente.idPaciente}',
        name: 'RepositorioDadosGoogle',
      );
    } catch (e, st) {
      developer.log(
        'Erro ao salvar paciente: ${paciente.idPaciente}',
        error: e,
        stackTrace: st,
        name: 'RepositorioDadosGoogle',
      );
      rethrow;
    }
  }

  Future<void> salvarAgendamento(Agendamento agendamento) async {
    try {
      final id = await obterPlanilhaId();
      await _sheets.inserirLinha(id, 'Agenda', _valoresAgendamento(agendamento));
      await registrarAuditoria(
        'AGENDAMENTO_SESSAO',
        'Sessão ${agendamento.idAgendamento} agendada.',
      );
      developer.log(
        'Agendamento salvo: ${agendamento.idAgendamento}',
        name: 'RepositorioDadosGoogle',
      );
    } catch (e, st) {
      developer.log(
        'Erro ao salvar agendamento: ${agendamento.idAgendamento}',
        error: e,
        stackTrace: st,
        name: 'RepositorioDadosGoogle',
      );
      rethrow;
    }
  }

  Future<void> salvarEvolucao(Evolucao evolucao) async {
    try {
      final id = await obterPlanilhaId();
      await _sheets.inserirLinha(id, 'Evolucoes', _valoresEvolucao(evolucao));
      await registrarAuditoria(
        'REGISTRO_EVOLUCAO',
        'Evolução ${evolucao.idEvolucao} criada.',
      );
      developer.log(
        'Evolução salva: ${evolucao.idEvolucao}',
        name: 'RepositorioDadosGoogle',
      );
    } catch (e, st) {
      developer.log(
        'Erro ao salvar evolução: ${evolucao.idEvolucao}',
        error: e,
        stackTrace: st,
        name: 'RepositorioDadosGoogle',
      );
      rethrow;
    }
  }

  Future<void> atualizarEvolucao(Evolucao evolucao) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Evolucoes');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == evolucao.idEvolucao,
    );
    if (indice == -1) return;

    await _sheets.atualizarLinha(
      id,
      'Evolucoes!A${indice + 2}:N${indice + 2}',
      _valoresEvolucao(evolucao),
    );
    await registrarAuditoria(
      'EDITAR_EVOLUCAO',
      'Evolução ${evolucao.idEvolucao} atualizada.',
    );
  }

  Future<void> atualizarPaciente(Paciente paciente) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Pacientes');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == paciente.idPaciente,
    );
    if (indice == -1) {
      throw StateError('Paciente ${paciente.idPaciente} não encontrado.');
    }

    await _sheets.atualizarLinha(
      id,
      'Pacientes!A${indice + 2}:S${indice + 2}',
      _valoresPaciente(paciente),
    );
    await registrarAuditoria(
      'EDITAR_PACIENTE',
      'Paciente ${paciente.idPaciente} atualizado.',
    );
  }

  Future<void> arquivarPaciente(String idPaciente) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Pacientes');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == idPaciente,
    );
    if (indice == -1) return;

    final colSituacao = Paciente.indicesColunas['situacao']!;
    final linha = _preencher(linhas[indice], 19);
    linha[colSituacao] = 'Arquivado';
    await _sheets.atualizarLinha(
      id,
      'Pacientes!A${indice + 2}:S${indice + 2}',
      linha,
    );
    await registrarAuditoria(
      'ARQUIVAMENTO_PACIENTE',
      'Paciente $idPaciente arquivado.',
    );
  }

  Future<void> restaurarPaciente(String idPaciente) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Pacientes');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == idPaciente,
    );
    if (indice == -1) return;

    final colSituacao = Paciente.indicesColunas['situacao']!;
    final linha = _preencher(linhas[indice], 19);
    linha[colSituacao] = 'Ativo';
    await _sheets.atualizarLinha(
      id,
      'Pacientes!A${indice + 2}:S${indice + 2}',
      linha,
    );
    await registrarAuditoria(
      'RESTAURACAO_PACIENTE',
      'Paciente $idPaciente restaurado.',
    );
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Agenda');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == agendamento.idAgendamento,
    );
    if (indice == -1) {
      throw StateError(
        'Agendamento ${agendamento.idAgendamento} não encontrado.',
      );
    }

    await _sheets.atualizarLinha(
      id,
      'Agenda!A${indice + 2}:I${indice + 2}',
      _valoresAgendamento(agendamento),
    );
    await registrarAuditoria(
      'EDITAR_AGENDAMENTO',
      'Sessão ${agendamento.idAgendamento} atualizada.',
    );
  }

  Future<void> marcarAgendamentoRealizado(String idAgendamento) async {
    await atualizarSituacaoAgendamento(
      idAgendamento,
      Agendamento.situacaoRealizado,
    );
  }

  Future<void> atualizarSituacaoAgendamento(
    String idAgendamento,
    String situacao,
  ) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Agenda');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == idAgendamento,
    );
    if (indice == -1) return;

    final colSituacao = Agendamento.indicesColunas['situacao']!;
    final linha = _preencher(linhas[indice], 9);
    linha[colSituacao] = situacao;
    await _sheets.atualizarLinha(
      id,
      'Agenda!A${indice + 2}:I${indice + 2}',
      linha,
    );
    await registrarAuditoria(
      'ATUALIZAR_AGENDAMENTO',
      'Sessão $idAgendamento atualizada para $situacao.',
    );
  }

  Future<void> salvarValorSessaoPadrao(String valor) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Configuracoes');
    final indice = linhas.indexWhere(
      (linha) => linha.isNotEmpty && linha.first == 'valor_sessao_padrao',
    );

    if (indice == -1) {
      await _sheets.inserirLinha(id, 'Configuracoes', [
        'valor_sessao_padrao',
        valor,
      ]);
    } else {
      await _sheets.atualizarLinha(
        id,
        'Configuracoes!A${indice + 2}:B${indice + 2}',
        ['valor_sessao_padrao', valor],
      );
    }

    await registrarAuditoria(
      'CONFIGURACAO',
      'Valor padrão da sessão atualizado para R\$ $valor.',
    );
  }

  Future<void> registrarAuditoria(String operacao, String detalhes) async {
    final id = await obterPlanilhaId();
    final linhas = await _sheets.lerAba(id, 'Auditoria');
    final agora = DateTime.now();
    final data =
        '${UtilitariosData.formatarDataBr(agora)} ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    await _sheets.inserirLinha(id, 'Auditoria', [
      GeradorId.proximo(
        'L',
        linhas.map((linha) => linha.isNotEmpty ? linha.first : ''),
      ),
      data,
      operacao,
      detalhes,
    ]);
  }

  String urlPlanilha(String planilhaId) {
    return 'https://docs.google.com/spreadsheets/d/$planilhaId/edit';
  }

  Paciente _pacienteDeLinha(List<String> linhaOriginal) {
    final linha = _preencher(linhaOriginal, 19);
    String col(String nome) => linha[Paciente.indicesColunas[nome]!];
    String? colOuNull(String nome) => col(nome).isEmpty ? null : col(nome);
    return Paciente(
      idPaciente: col('idPaciente'),
      nome: col('nome'),
      telefone: col('telefone'),
      dataNascimento: _parseDataBr(col('dataNascimento')),
      cpf: col('cpf'),
      endereco: col('endereco'),
      queixaPrincipal: colOuNull('queixaPrincipal'),
      histDoencaAtual: colOuNull('histDoencaAtual'),
      histPregresso: colOuNull('histPregresso'),
      ocupacao: colOuNull('ocupacao'),
      situacao: col('situacao').isEmpty ? 'Ativo' : col('situacao'),
      dataCadastro: DateTime.tryParse(col('dataCadastro')) ?? DateTime.now(),
      genero: colOuNull('genero'),
      dor: colOuNull('dor'),
      comorbidades: colOuNull('comorbidades'),
      medicamentos: colOuNull('medicamentos'),
      alergias: colOuNull('alergias'),
      cirurgias: colOuNull('cirurgias'),
      habitosVida: colOuNull('habitosVida'),
    );
  }

  Agendamento _agendamentoDeLinha(List<String> linhaOriginal) {
    final linha = _preencher(linhaOriginal, 9);
    String col(String nome) => linha[Agendamento.indicesColunas[nome]!];
    return Agendamento(
      idAgendamento: col('idAgendamento'),
      idPaciente: col('idPaciente'),
      data: _parseDataBr(col('data')),
      horaInicio: col('horaInicio'),
      horaFim: col('horaFim'),
      valorSessao: double.tryParse(col('valorSessao').replaceAll(',', '.')) ?? 0,
      observacoes: col('observacoes'),
      situacao: col('situacao').isEmpty ? 'Agendado' : col('situacao'),
      dataCriacao: DateTime.tryParse(col('dataCriacao')) ?? DateTime.now(),
    );
  }

  Evolucao _evolucaoDeLinha(List<String> linhaOriginal) {
    return Evolucao.deLinhaPlanilha(linhaOriginal);
  }

  List<Object?> _valoresPaciente(Paciente paciente) {
    final mapa = paciente.paraMapaPlanilha();
    return ServicoGoogleSheets.cabecalhos['Pacientes']!
        .map((coluna) => mapa[coluna] ?? '')
        .toList();
  }

  List<Object?> _valoresAgendamento(Agendamento agendamento) {
    final mapa = agendamento.paraMapaPlanilha();
    return ServicoGoogleSheets.cabecalhos['Agenda']!
        .map((coluna) => mapa[coluna] ?? '')
        .toList();
  }

  List<Object?> _valoresEvolucao(Evolucao evolucao) {
    final mapa = evolucao.paraMapaPlanilha();
    return ServicoGoogleSheets.cabecalhos['Evolucoes']!
        .map((coluna) => mapa[coluna] ?? '')
        .toList();
  }

  String _valorConfiguracao(
    List<List<String>> linhas,
    String chave, {
    required String padrao,
  }) {
    final linha = linhas.firstWhere(
      (linha) => linha.isNotEmpty && linha.first == chave,
      orElse: () => const [],
    );
    return linha.length > 1 && linha[1].isNotEmpty ? linha[1] : padrao;
  }

  List<String> _preencher(List<String> linha, int tamanho) {
    return [...linha, for (var i = linha.length; i < tamanho; i++) ''];
  }

  DateTime _parseDataBr(String data) {
    final partes = data.split('/');
    if (partes.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(partes[2]) ?? DateTime.now().year,
      int.tryParse(partes[1]) ?? DateTime.now().month,
      int.tryParse(partes[0]) ?? DateTime.now().day,
    );
  }
}
