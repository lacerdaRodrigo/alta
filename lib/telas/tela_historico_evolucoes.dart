import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/design_system.dart';
import '../modelos/evolucao.dart';
import '../modelos/paciente.dart';
import '../provedores/provedores_dados.dart';
import '../utilitarios/utilitarios_data.dart';
import 'tela_registro_evolucao.dart';

class TelaHistoricoEvolucoes extends ConsumerWidget {
  final Paciente paciente;

  const TelaHistoricoEvolucoes({super.key, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evolucoes =
        ref
            .watch(provedorListaEvolucoes)
            .where((evolucao) => evolucao.idPaciente == paciente.idPaciente)
            .toList()
          ..sort((a, b) => b.dataAtendimento.compareTo(a.dataAtendimento));
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          FisioGradientHeader(
            padding: const EdgeInsets.fromLTRB(18, 50, 18, 22),
            titulo: 'Histórico Clínico',
            subtitulo: paciente.nome,
            leading: FisioHeaderIconButton(Icons.chevron_left_rounded,
                onTap: () => Navigator.pop(context)),
          ),
          Expanded(
            child: SafeArea(
              child: evolucoes.isEmpty
                  ? _EstadoVazio(theme: theme)
                  : FisioResponsiveCenter(
                      maxWidth: 700,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: evolucoes.length,
                        itemBuilder: (context, index) => _ItemTimeline(
                          paciente: paciente,
                          evolucao: evolucoes[index],
                          ultimo: index == evolucoes.length - 1,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final ThemeData theme;

  const _EstadoVazio({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_edu_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum registro clínico cadastrado para este paciente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTimeline extends StatelessWidget {
  final Paciente paciente;
  final Evolucao evolucao;
  final bool ultimo;

  const _ItemTimeline({
    required this.paciente,
    required this.evolucao,
    required this.ultimo,
  });

  Color _condicaoColor(String condicao) {
    switch (condicao) {
      case 'Melhora':
        return FisioCores.success;
      case 'Estável':
        return FisioCores.warning;
      case 'Piora':
        return FisioCores.danger;
      case 'Faltou':
        return FisioCores.textMuted;
      default:
        return FisioCores.info;
    }
  }

  String _formatHora(DateTime data) =>
      '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

  IconData _presencaIcon(String status) {
    switch (status) {
      case 'Presente':
        return Icons.person_pin_rounded;
      case 'Ausente com aviso':
        return Icons.person_off_outlined;
      case 'Ausente sem aviso':
        return Icons.person_off_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _presencaColor(String status) {
    switch (status) {
      case 'Presente':
        return FisioCores.success;
      case 'Ausente com aviso':
        return FisioCores.warning;
      case 'Ausente sem aviso':
        return FisioCores.danger;
      default:
        return FisioCores.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temSinaisVitais =
        (evolucao.pressaoArterial != null &&
            evolucao.pressaoArterial!.isNotEmpty) ||
        evolucao.frequenciaCardiaca != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _condicaoColor(evolucao.condicaoPaciente),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _condicaoColor(
                        evolucao.condicaoPaciente,
                      ).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: FisioDecoracoes.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          UtilitariosData.formatarDataBr(
                            evolucao.dataAtendimento,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _condicaoColor(
                            evolucao.condicaoPaciente,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          evolucao.condicaoPaciente,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _condicaoColor(evolucao.condicaoPaciente),
                          ),
                        ),
                      ),
                      if (evolucao.editavel)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TelaRegistroEvolucao(
                                  paciente: paciente,
                                  evolucaoExistente: evolucao,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Editar',
                            style: TextStyle(
                              color: FisioCores.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _LinhaInfo(
                    icone: _presencaIcon(evolucao.statusPresenca),
                    corIcone: _presencaColor(evolucao.statusPresenca),
                    texto: 'Status: ${evolucao.statusPresenca}',
                  ),
                  const SizedBox(height: 4),
                  _LinhaInfo(
                    icone: Icons.access_time_rounded,
                    texto:
                        '${_formatHora(evolucao.horarioInicioReal)} — ${_formatHora(evolucao.horarioFimReal)} (Real)',
                  ),
                  const SizedBox(height: 4),
                  _LinhaInfo(
                    icone: Icons.favorite_outline_rounded,
                    texto: 'Dor: ${evolucao.dorSessao}/10',
                  ),
                  const SizedBox(height: 4),
                  _LinhaInfo(
                    icone: Icons.location_on_outlined,
                    texto: evolucao.localAtendimento,
                  ),
                  if (temSinaisVitais) ...[
                    const SizedBox(height: 4),
                    _LinhaInfo(
                      icone: Icons.monitor_heart_outlined,
                      texto: [
                        if (evolucao.pressaoArterial != null &&
                            evolucao.pressaoArterial!.isNotEmpty)
                          'PA: ${evolucao.pressaoArterial}',
                        if (evolucao.frequenciaCardiaca != null)
                          'FC: ${evolucao.frequenciaCardiaca} bpm',
                      ].join(' | '),
                    ),
                  ],
                  if (evolucao.evolucaoTexto.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FisioCores.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        evolucao.evolucaoTexto,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color? corIcone;

  const _LinhaInfo({required this.icone, required this.texto, this.corIcone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: corIcone ?? Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
