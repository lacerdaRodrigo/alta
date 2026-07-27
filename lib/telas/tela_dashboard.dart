import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modelos/agendamento.dart';
import '../componentes/design_system.dart';
import '../componentes/modal_detalhes_paciente.dart';
import '../provedores/provedores_dados.dart';
import '../utilitarios/utilitarios_data.dart';
import '../utilitarios/acoes_agendamento.dart';
import 'tela_cadastro_paciente.dart';
import 'tela_nova_sessao.dart';
import 'tela_pacientes.dart';
import 'tela_sessoes.dart';
import 'tela_configuracoes.dart';
import 'tela_financeiro.dart';

class TelaDashboard extends ConsumerStatefulWidget {
  final String nomeUsuario;
  const TelaDashboard({super.key, required this.nomeUsuario});

  @override
  ConsumerState<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends ConsumerState<TelaDashboard> {
  int _indiceSelecionado = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final carregamento = ref.read(provedorCarregamentoDados);
      if (carregamento.carregouComSucesso ||
          carregamento.status == StatusCarregamentoDados.carregando) {
        return;
      }
      carregarDadosReais(ref);
    });
  }

  void _abrirNovaSessao() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaNovaSessao()),
    );
  }

  void _abrirNovoPaciente() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaCadastroPaciente()),
    );
  }

  void _fabAction() {
    if (_indiceSelecionado == 2) {
      _abrirNovoPaciente();
    } else {
      _abrirNovaSessao();
    }
  }

  @override
  Widget build(BuildContext context) {
    final carregamento = ref.watch(provedorCarregamentoDados);

    Widget corpo;
    if (_indiceSelecionado == 0) {
      if (carregamento.carregouComSucesso) {
        corpo = _HomeTab(
          nomeUsuario: widget.nomeUsuario,
          onNavegar: (i) => setState(() => _indiceSelecionado = i),
          onConfiguracoes: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
          ),
        );
      } else if (carregamento.possuiErro) {
        corpo = _ErroTab(mensagem: carregamento.mensagemErro);
      } else {
        corpo = const _CarregandoTab();
      }
    } else if (_indiceSelecionado == 1) {
      corpo = TelaSessoes(
        onAbrir: (a) => _abrirAcoesAgendamento(context, a),
      );
    } else if (_indiceSelecionado == 2) {
      corpo = TelaPacientes(
        onAbrir: (p) => mostrarModalDetalhesPaciente(context, p),
      );
    } else {
      corpo = const TelaFinanceiro();
    }

    return Scaffold(
      body: Stack(
        children: [
          corpo,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FisioBottomNav(
              index: _indiceSelecionado,
              onChanged: (i) => setState(() => _indiceSelecionado = i),
              onFab: _fabAction,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirAcoesAgendamento(BuildContext context, Agendamento a) {
    final pacientes = ref.read(provedorListaPacientes);
    final paciente = pacientes.cast<dynamic>().firstWhere(
          (p) => p.idPaciente == a.idPaciente,
          orElse: () => null,
        );
    executarAcaoAgendamento(
        context, ref, AcaoAgendamento.registrarEvolucao, a, paciente);
  }
}

// ─── Home tab ───────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final String nomeUsuario;
  final ValueChanged<int>? onNavegar;
  final VoidCallback? onConfiguracoes;

  const _HomeTab({
    required this.nomeUsuario,
    this.onNavegar,
    this.onConfiguracoes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendamentos = ref.watch(provedorListaAgendamentos);
    final pacientes = ref.watch(provedorListaPacientes);
    final hoje = DateTime.now();

    final doDia = agendamentos
        .where((a) => UtilitariosData.mesmoDia(a.data, hoje))
        .toList()
      ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

    final ativos = pacientes.where((p) => p.estaAtivo).length;
    final pendencias = agendamentos
        .where((a) => a.estaAgendado && a.data.isBefore(hoje))
        .length;

    final saudacao = _saudacao(hoje.hour);
    final mapaPacientes = {for (final p in pacientes) p.idPaciente: p.nome};

    return ColoredBox(
      color: FisioCores.surface,
      child: FisioResponsiveCenter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FisioGradientHeader(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 30),
                eyebrow: saudacao,
                titulo: nomeUsuario,
                trailing: GestureDetector(
                  onTap: onConfiguracoes,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(fisioIniciais(nomeUsuario),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
                bottom: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você tem hoje, ${UtilitariosData.formatarDataExtensa(hoje)}',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${doDia.length}',
                            style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                                letterSpacing: -1)),
                        const SizedBox(width: 9),
                        Text(doDia.length == 1 ? 'sessão' : 'sessões',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -38),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FisioStatTile(
                              icone: Icons.people_alt_rounded,
                              cor: FisioCores.primary,
                              titulo: 'Pacientes ativos',
                              valor: '$ativos',
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: FisioStatTile(
                              icone: Icons.warning_amber_rounded,
                              cor: FisioCores.warning,
                              titulo: 'Pendências',
                              valor: '$pendencias',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Agenda de hoje',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: FisioCores.textPrimary)),
                          GestureDetector(
                            onTap: () => onNavegar?.call(1),
                            child: const Text('Ver tudo',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: FisioCores.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (doDia.isEmpty)
                        const FisioEmptyState(
                          icone: Icons.event_available_rounded,
                          titulo: 'Nenhuma sessão hoje',
                          subtitulo: 'Aproveite para revisar evoluções.',
                        )
                      else
                        ...doDia.map((s) => _linhaAgenda(
                            s, mapaPacientes[s.idPaciente] ?? 'Paciente')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaAgenda(Agendamento s, String nome) {
    final cor = s.foiRealizado ? FisioCores.success : FisioCores.info;
    final status = s.foiRealizado ? 'Realizado' : 'Agendado';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FisioCard(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(s.horaInicio,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: FisioCores.textPrimary)),
            ),
            Container(
              width: 3,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: cor, borderRadius: BorderRadius.circular(99)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FisioCores.textPrimary)),
                  const SizedBox(height: 1),
                  const Text('Atendimento domiciliar',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: FisioCores.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FisioStatusPill(label: status, cor: cor),
          ],
        ),
      ),
    );
  }

  String _saudacao(int hora) {
    if (hora < 12) return 'Bom dia,';
    if (hora < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}

// ─── Loading / Error tabs ────────────────────────────────────────────────────

class _CarregandoTab extends StatelessWidget {
  const _CarregandoTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 24),
            Text('Carregando dados…',
                style: TextStyle(fontSize: 14, color: FisioCores.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ErroTab extends ConsumerWidget {
  final String? mensagem;
  const _ErroTab({this.mensagem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Não foi possível carregar os dados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FisioCores.textPrimary)),
              const SizedBox(height: 8),
              Text(
                mensagem ??
                    'Verifique sua conexão e as permissões da planilha.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: FisioCores.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => carregarDadosReais(ref),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

