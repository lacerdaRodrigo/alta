import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/agendamento.dart';
import '../modelos/evolucao.dart';
import '../modelos/paciente.dart';
import '../servicos/servico_google_drive.dart';
import '../servicos/servico_repositorio_dados.dart';
import 'provedor_autenticacao.dart';

enum StatusCarregamentoDados { inicial, carregando, carregado, erro }

class EstadoCarregamentoDados {
  final StatusCarregamentoDados status;
  final String? mensagemErro;

  const EstadoCarregamentoDados({
    this.status = StatusCarregamentoDados.inicial,
    this.mensagemErro,
  });

  bool get estaCarregando =>
      status == StatusCarregamentoDados.inicial ||
      status == StatusCarregamentoDados.carregando;

  bool get carregouComSucesso => status == StatusCarregamentoDados.carregado;

  bool get possuiErro => status == StatusCarregamentoDados.erro;
}

class CarregamentoDadosNotifier extends Notifier<EstadoCarregamentoDados> {
  @override
  EstadoCarregamentoDados build() => const EstadoCarregamentoDados();

  void carregando() {
    state = const EstadoCarregamentoDados(
      status: StatusCarregamentoDados.carregando,
    );
  }

  void sucesso() {
    state = const EstadoCarregamentoDados(
      status: StatusCarregamentoDados.carregado,
    );
  }

  void erro(Object erro) {
    state = EstadoCarregamentoDados(
      status: StatusCarregamentoDados.erro,
      mensagemErro: 'Não foi possível carregar os dados da planilha. $erro',
    );
  }

  void resetar() {
    state = const EstadoCarregamentoDados();
  }
}

class ListaPacientesNotifier extends Notifier<List<Paciente>> {
  @override
  List<Paciente> build() => [];

  void definir(List<Paciente> pacientes) => state = pacientes;
}

class BuscaNotifier extends Notifier<String> {
  @override
  String build() => '';

  void definir(String termo) => state = termo;
}

class ListaAgendamentosNotifier extends Notifier<List<Agendamento>> {
  @override
  List<Agendamento> build() => [];

  void definir(List<Agendamento> agendamentos) => state = agendamentos;
}

class ListaEvolucoesNotifier extends Notifier<List<Evolucao>> {
  @override
  List<Evolucao> build() => [];

  void definir(List<Evolucao> evolucoes) => state = evolucoes;
}

class ValorSessaoPadraoNotifier extends Notifier<String> {
  @override
  String build() => '150,00';

  void definir(String valor) => state = valor;
}

class LogsAuditoriaNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void definir(List<String> logs) => state = logs;

  void adicionar(String log) => state = [log, ...state];
}

class PlanilhaIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void definir(String? id) => state = id;
}

/// Planilhas com o nome da base que existem no Drive além da que está em uso.
class PlanilhasDuplicadasNotifier extends Notifier<List<PlanilhaBanco>> {
  @override
  List<PlanilhaBanco> build() => const [];

  void definir(List<PlanilhaBanco> planilhas) => state = planilhas;
}

final provedorRepositorioDados = Provider<RepositorioDadosGoogle?>((ref) {
  final sessao = ref.watch(provedorAutenticacao).sessao;
  if (sessao == null) {
    return null;
  }
  return RepositorioDadosGoogle(sessao.criarCliente());
});

final provedorCarregamentoDados =
    NotifierProvider<CarregamentoDadosNotifier, EstadoCarregamentoDados>(
      CarregamentoDadosNotifier.new,
    );
final provedorListaPacientes =
    NotifierProvider<ListaPacientesNotifier, List<Paciente>>(
      ListaPacientesNotifier.new,
    );
final provedorBusca = NotifierProvider<BuscaNotifier, String>(
  BuscaNotifier.new,
);
final provedorListaAgendamentos =
    NotifierProvider<ListaAgendamentosNotifier, List<Agendamento>>(
      ListaAgendamentosNotifier.new,
    );
final provedorListaEvolucoes =
    NotifierProvider<ListaEvolucoesNotifier, List<Evolucao>>(
      ListaEvolucoesNotifier.new,
    );
final provedorValorSessaoPadrao =
    NotifierProvider<ValorSessaoPadraoNotifier, String>(
      ValorSessaoPadraoNotifier.new,
    );
final provedorLogsAuditoria =
    NotifierProvider<LogsAuditoriaNotifier, List<String>>(
      LogsAuditoriaNotifier.new,
    );
final provedorPlanilhaId = NotifierProvider<PlanilhaIdNotifier, String?>(
  PlanilhaIdNotifier.new,
);
final provedorPlanilhasDuplicadas =
    NotifierProvider<PlanilhasDuplicadasNotifier, List<PlanilhaBanco>>(
      PlanilhasDuplicadasNotifier.new,
    );

void limparDados(WidgetRef ref) {
  ref.read(provedorCarregamentoDados.notifier).resetar();
  ref.read(provedorListaPacientes.notifier).definir([]);
  ref.read(provedorBusca.notifier).definir('');
  ref.read(provedorListaAgendamentos.notifier).definir([]);
  ref.read(provedorListaEvolucoes.notifier).definir([]);
  ref.read(provedorValorSessaoPadrao.notifier).definir('150,00');
  ref.read(provedorLogsAuditoria.notifier).definir([]);
  ref.read(provedorPlanilhaId.notifier).definir(null);
  ref.read(provedorPlanilhasDuplicadas.notifier).definir(const []);
}

/// Referências resolvidas uma única vez, antes de qualquer `await`.
///
/// O carregamento é disparado do `initState` de uma tela, mas os notifiers
/// vivem no `ProviderScope` global. Se a tela for desmontada durante a chamada
/// de rede, usar o `WidgetRef` depois lançaria
/// "Bad state: Using 'ref' when a widget is about to or has been unmounted is
/// unsafe" — as referências capturadas aqui continuam válidas.
class _DependenciasCarregamento {
  final EstadoAutenticacao auth;
  final RepositorioDadosGoogle repositorio;
  final ListaPacientesNotifier listaPacientes;
  final ListaAgendamentosNotifier listaAgendamentos;
  final ListaEvolucoesNotifier listaEvolucoes;
  final ValorSessaoPadraoNotifier valorSessaoPadrao;
  final LogsAuditoriaNotifier logsAuditoria;
  final PlanilhaIdNotifier planilhaId;
  final PlanilhasDuplicadasNotifier planilhasDuplicadas;
  final CarregamentoDadosNotifier carregamento;

  const _DependenciasCarregamento({
    required this.auth,
    required this.repositorio,
    required this.listaPacientes,
    required this.listaAgendamentos,
    required this.listaEvolucoes,
    required this.valorSessaoPadrao,
    required this.logsAuditoria,
    required this.planilhaId,
    required this.planilhasDuplicadas,
    required this.carregamento,
  });

  factory _DependenciasCarregamento.ler(WidgetRef ref) {
    return _DependenciasCarregamento(
      auth: ref.read(provedorAutenticacao),
      repositorio: _repositorio(ref),
      listaPacientes: ref.read(provedorListaPacientes.notifier),
      listaAgendamentos: ref.read(provedorListaAgendamentos.notifier),
      listaEvolucoes: ref.read(provedorListaEvolucoes.notifier),
      valorSessaoPadrao: ref.read(provedorValorSessaoPadrao.notifier),
      logsAuditoria: ref.read(provedorLogsAuditoria.notifier),
      planilhaId: ref.read(provedorPlanilhaId.notifier),
      planilhasDuplicadas: ref.read(provedorPlanilhasDuplicadas.notifier),
      carregamento: ref.read(provedorCarregamentoDados.notifier),
    );
  }
}

Future<void> carregarDadosReais(WidgetRef ref) async {
  final carregamento = ref.read(provedorCarregamentoDados.notifier);
  carregamento.carregando();

  final _DependenciasCarregamento deps;
  try {
    deps = _DependenciasCarregamento.ler(ref);
  } catch (erro) {
    // `_repositorio` lança quando não há sessão autenticada.
    carregamento.erro(erro);
    return;
  }

  try {
    await _executarCarregamento(deps);
  } catch (erro) {
    if (erro.toString().contains('404')) {
      deps.repositorio.limparCache();
      try {
        await _executarCarregamento(deps);
        return;
      } catch (e2) {
        deps.carregamento.erro(e2);
        return;
      }
    }
    deps.carregamento.erro(erro);
  }
}

const _versaoTermosAceitos = '2026-06-29';

Future<void> _executarCarregamento(_DependenciasCarregamento deps) async {
  if (deps.auth.termosAceitos) {
    final email = deps.auth.sessao?.email ?? 'desconhecido';
    await deps.repositorio.registrarAuditoria(
      'ACEITE_TERMOS',
      'Versao=$_versaoTermosAceitos; Email=$email',
    );
  }

  final dados = await deps.repositorio.carregarTudo();
  deps.listaPacientes.definir(dados.pacientes);
  deps.listaAgendamentos.definir(dados.agendamentos);
  deps.listaEvolucoes.definir(dados.evolucoes);
  deps.valorSessaoPadrao.definir(dados.valorSessaoPadrao);
  deps.logsAuditoria.definir(dados.logsAuditoria);
  deps.planilhaId.definir(dados.planilhaId);
  deps.planilhasDuplicadas.definir(dados.planilhasDuplicadas);
  deps.carregamento.sucesso();
}

Future<void> salvarPacienteReal(WidgetRef ref, Paciente paciente) async {
  await _repositorio(ref).salvarPaciente(paciente);
  final pacientes = ref.read(provedorListaPacientes);
  ref.read(provedorListaPacientes.notifier).definir([...pacientes, paciente]);
  registrarLog(
    ref,
    'CADASTRO_PACIENTE',
    'Paciente ${paciente.idPaciente} cadastrado.',
  );
}

Future<void> atualizarPacienteReal(
  WidgetRef ref,
  Paciente pacienteAtualizado,
) async {
  await _repositorio(ref).atualizarPaciente(pacienteAtualizado);
  final pacientes = ref.read(provedorListaPacientes);
  ref.read(provedorListaPacientes.notifier).definir([
    for (final paciente in pacientes)
      if (paciente.idPaciente == pacienteAtualizado.idPaciente)
        pacienteAtualizado
      else
        paciente,
  ]);
  registrarLog(
    ref,
    'EDITAR_PACIENTE',
    'Paciente ${pacienteAtualizado.idPaciente} atualizado.',
  );
}

Future<void> salvarAgendamentoReal(
  WidgetRef ref,
  Agendamento agendamento,
) async {
  await _repositorio(ref).salvarAgendamento(agendamento);
  final agendamentos = ref.read(provedorListaAgendamentos);
  ref.read(provedorListaAgendamentos.notifier).definir([
    ...agendamentos,
    agendamento,
  ]);
  registrarLog(
    ref,
    'AGENDAMENTO_SESSAO',
    'Sessão ${agendamento.idAgendamento} agendada.',
  );
}

Future<void> salvarEvolucaoReal(WidgetRef ref, Evolucao evolucao) async {
  await _repositorio(ref).salvarEvolucao(evolucao);
  final evolucoes = ref.read(provedorListaEvolucoes);
  ref.read(provedorListaEvolucoes.notifier).definir([...evolucoes, evolucao]);
  registrarLog(
    ref,
    'REGISTRO_EVOLUCAO',
    'Evolução ${evolucao.idEvolucao} criada.',
  );
}

Future<void> atualizarEvolucaoReal(WidgetRef ref, Evolucao evolucao) async {
  await _repositorio(ref).atualizarEvolucao(evolucao);
  final evolucoes = ref.read(provedorListaEvolucoes);
  ref.read(provedorListaEvolucoes.notifier).definir([
    for (final e in evolucoes)
      if (e.idEvolucao == evolucao.idEvolucao) evolucao else e,
  ]);
  registrarLog(
    ref,
    'EDITAR_EVOLUCAO',
    'Evolução ${evolucao.idEvolucao} atualizada.',
  );
}

Future<void> atualizarAgendamentoReal(
  WidgetRef ref,
  Agendamento agendamentoAtualizado,
) async {
  await _repositorio(ref).atualizarAgendamento(agendamentoAtualizado);
  final agendamentos = ref.read(provedorListaAgendamentos);
  ref.read(provedorListaAgendamentos.notifier).definir([
    for (final agendamento in agendamentos)
      if (agendamento.idAgendamento == agendamentoAtualizado.idAgendamento)
        agendamentoAtualizado
      else
        agendamento,
  ]);
  registrarLog(
    ref,
    'EDITAR_AGENDAMENTO',
    'Sessão ${agendamentoAtualizado.idAgendamento} atualizada.',
  );
}

Future<void> marcarAgendamentoRealizadoReal(
  WidgetRef ref,
  String idAgendamento,
) async {
  await atualizarSituacaoAgendamentoReal(
    ref,
    idAgendamento,
    Agendamento.situacaoRealizado,
  );
}

Future<void> atualizarSituacaoAgendamentoReal(
  WidgetRef ref,
  String idAgendamento,
  String situacao,
) async {
  await _repositorio(ref).atualizarSituacaoAgendamento(idAgendamento, situacao);
  final agendamentos = ref.read(provedorListaAgendamentos);
  ref.read(provedorListaAgendamentos.notifier).definir([
    for (final agendamento in agendamentos)
      if (agendamento.idAgendamento == idAgendamento)
        agendamento.copiarCom(situacao: situacao)
      else
        agendamento,
  ]);
  registrarLog(
    ref,
    'ATUALIZAR_AGENDAMENTO',
    'Sessão $idAgendamento atualizada para $situacao.',
  );
}

Future<void> arquivarPacienteReal(WidgetRef ref, String idPaciente) async {
  await _repositorio(ref).arquivarPaciente(idPaciente);
  final pacientes = ref.read(provedorListaPacientes);
  ref.read(provedorListaPacientes.notifier).definir([
    for (final paciente in pacientes)
      if (paciente.idPaciente == idPaciente)
        paciente.copiarCom(situacao: 'Arquivado')
      else
        paciente,
  ]);
  registrarLog(ref, 'ARQUIVAMENTO_PACIENTE', 'Paciente $idPaciente arquivado.');
}

Future<void> restaurarPacienteReal(WidgetRef ref, String idPaciente) async {
  await _repositorio(ref).restaurarPaciente(idPaciente);
  final pacientes = ref.read(provedorListaPacientes);
  ref.read(provedorListaPacientes.notifier).definir([
    for (final paciente in pacientes)
      if (paciente.idPaciente == idPaciente)
        paciente.copiarCom(situacao: 'Ativo')
      else
        paciente,
  ]);
  registrarLog(ref, 'RESTAURACAO_PACIENTE', 'Paciente $idPaciente restaurado.');
}

Future<void> salvarValorSessaoPadraoReal(WidgetRef ref, String valor) async {
  await _repositorio(ref).salvarValorSessaoPadrao(valor);
  ref.read(provedorValorSessaoPadrao.notifier).definir(valor);
  registrarLog(
    ref,
    'CONFIGURACAO',
    'Valor padrão da sessão atualizado para R\$ $valor.',
  );
}

void registrarLog(WidgetRef ref, String operacao, String detalhes) {
  final agora = DateTime.now();
  final data =
      '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} '
      '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

  ref
      .read(provedorLogsAuditoria.notifier)
      .adicionar('$data - $operacao - $detalhes');
}

RepositorioDadosGoogle _repositorio(WidgetRef ref) {
  final repositorio = ref.read(provedorRepositorioDados);
  if (repositorio == null) {
    throw StateError('Autorize Drive e Sheets antes de acessar os dados.');
  }
  return repositorio;
}
