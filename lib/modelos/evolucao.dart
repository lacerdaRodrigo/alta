class Evolucao {
  /// Prazo para corrigir um registro. Passado isso a evolução vira prontuário
  /// fechado: continua **visível**, mas não pode mais ser alterada.
  static const janelaEdicao = Duration(hours: 24);

  static const indicesColunas = {
    'idEvolucao': 0,
    'idPaciente': 1,
    'idAgendamento': 2,
    'dataAtendimento': 3,
    'evolucaoTexto': 4,
    'dataRegistro': 5,
    'localAtendimento': 6,
    'statusPresenca': 7,
    'dorSessao': 8,
    'horarioInicioReal': 9,
    'horarioFimReal': 10,
    'condicaoPaciente': 11,
    'pressaoArterial': 12,
    'frequenciaCardiaca': 13,
  };

  final String idEvolucao;
  final String idPaciente;
  final String idAgendamento;
  final DateTime dataAtendimento;
  final String evolucaoTexto;
  final DateTime dataRegistro;
  final String localAtendimento;
  final String statusPresenca;
  final int dorSessao;
  final DateTime horarioInicioReal;
  final DateTime horarioFimReal;
  final String condicaoPaciente;
  final String? pressaoArterial;
  final int? frequenciaCardiaca;

  Evolucao({
    required this.idEvolucao,
    required this.idPaciente,
    required this.idAgendamento,
    required this.dataAtendimento,
    required this.evolucaoTexto,
    this.localAtendimento = 'Domicílio',
    this.statusPresenca = 'Presente',
    this.dorSessao = 0,
    required this.horarioInicioReal,
    required this.horarioFimReal,
    this.condicaoPaciente = 'Melhora',
    this.pressaoArterial,
    this.frequenciaCardiaca,
    DateTime? dataRegistro,
  }) : dataRegistro = dataRegistro ?? DateTime.now();

  /// Recebe `agora` para ser testável sem depender do relógio do sistema.
  bool editavelEm(DateTime agora) =>
      agora.difference(dataRegistro) < janelaEdicao;

  bool get editavel => editavelEm(DateTime.now());

  Map<String, dynamic> paraMapaPlanilha() {
    return {
      'ID_Evolucao': idEvolucao,
      'ID_Paciente': idPaciente,
      'ID_Agendamento': idAgendamento,
      'Data_Atendimento':
          '${dataAtendimento.day.toString().padLeft(2, '0')}/${dataAtendimento.month.toString().padLeft(2, '0')}/${dataAtendimento.year}',
      'Evolucao_Texto': evolucaoTexto,
      'Data_Registro': dataRegistro.toIso8601String(),
      'Local_Atendimento': localAtendimento,
      'Status_Presenca': statusPresenca,
      'Dor_Sessao': dorSessao.toString(),
      'Horario_Inicio_Real':
          '${horarioInicioReal.hour.toString().padLeft(2, '0')}:${horarioInicioReal.minute.toString().padLeft(2, '0')}',
      'Horario_Fim_Real':
          '${horarioFimReal.hour.toString().padLeft(2, '0')}:${horarioFimReal.minute.toString().padLeft(2, '0')}',
      'Condicao_Paciente': condicaoPaciente,
      'Pressao_Arterial': pressaoArterial ?? '',
      'Frequencia_Cardiaca': frequenciaCardiaca?.toString() ?? '',
    };
  }

  factory Evolucao.deLinhaPlanilha(List<String> linha) {
    String obterValor(String nomeColuna, {String padrao = ''}) {
      final idx = indicesColunas[nomeColuna] ?? -1;
      if (idx == -1 || idx >= linha.length) return padrao;
      final valor = linha[idx].trim();
      return valor.isEmpty ? padrao : valor;
    }

    final horarioInicio = _parseHora(obterValor('horarioInicioReal'));
    final horarioFim = _parseHora(obterValor('horarioFimReal'));
    final dataAtendimento = _parseData(obterValor('dataAtendimento'));

    return Evolucao(
      idEvolucao: obterValor('idEvolucao'),
      idPaciente: obterValor('idPaciente'),
      idAgendamento: obterValor('idAgendamento'),
      dataAtendimento: dataAtendimento,
      evolucaoTexto: obterValor('evolucaoTexto'),
      // Cai em `dataAtendimento`, não em "agora": com `DateTime.now()` uma linha
      // sem Data_Registro renasceria dentro da janela das 24h a cada
      // carregamento, deixando a evolução editável para sempre.
      dataRegistro:
          DateTime.tryParse(obterValor('dataRegistro')) ?? dataAtendimento,
      localAtendimento: obterValor('localAtendimento', padrao: 'Domicílio'),
      statusPresenca: obterValor('statusPresenca', padrao: 'Presente'),
      dorSessao: int.tryParse(obterValor('dorSessao', padrao: '0')) ?? 0,
      horarioInicioReal: horarioInicio,
      horarioFimReal: horarioFim,
      condicaoPaciente: obterValor('condicaoPaciente', padrao: 'Melhora'),
      pressaoArterial: obterValor('pressaoArterial').isEmpty
          ? null
          : obterValor('pressaoArterial'),
      frequenciaCardiaca: int.tryParse(obterValor('frequenciaCardiaca')),
    );
  }

  static DateTime _parseData(String data) {
    final partes = data.split('/');
    if (partes.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(partes[2]) ?? DateTime.now().year,
      int.tryParse(partes[1]) ?? DateTime.now().month,
      int.tryParse(partes[0]) ?? DateTime.now().day,
    );
  }

  static DateTime _parseHora(String hora) {
    if (hora.isEmpty) return DateTime.now();
    final partes = hora.split(':');
    if (partes.length != 2) return DateTime.now();
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    return DateTime(2000, 1, 1, h, m);
  }
}
