import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../componentes/design_system.dart';
import '../modelos/agendamento.dart';
import '../provedores/provedores_dados.dart';
import '../utilitarios/utilitarios_data.dart';

class TelaSessoes extends ConsumerStatefulWidget {
  final void Function(Agendamento)? onAbrir;
  const TelaSessoes({super.key, this.onAbrir});

  @override
  ConsumerState<TelaSessoes> createState() => _TelaSessoesState();
}

enum _FiltroSessao { todas, hoje, futuras, vencidas, realizadas }

class _TelaSessoesState extends ConsumerState<TelaSessoes> {
  late DateTime _mes;
  int _filtro = 0;
  String _busca = '';

  static const _labels = ['Todas', 'Hoje', 'Futuras', 'Vencidas', 'Realizadas'];

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mes = DateTime(agora.year, agora.month);
  }

  void _mudarMes(int d) =>
      setState(() => _mes = DateTime(_mes.year, _mes.month + d));

  bool _passaFiltro(Agendamento a) {
    final hoje = DateTime.now();
    switch (_FiltroSessao.values[_filtro]) {
      case _FiltroSessao.todas:
        return true;
      case _FiltroSessao.hoje:
        return UtilitariosData.mesmoDia(a.data, hoje) && !a.estaAtrasado(hoje);
      case _FiltroSessao.futuras:
        return a.data.isAfter(hoje);
      case _FiltroSessao.vencidas:
        // `estaAtrasado` compara data + hora: a sessão de hoje às 14h só entra
        // aqui depois das 14h, não desde a meia-noite.
        return a.estaAtrasado(hoje);
      case _FiltroSessao.realizadas:
        return a.foiRealizado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final agendamentos = ref.watch(provedorListaAgendamentos);
    final pacientes = ref.watch(provedorListaPacientes);
    final mapaNomes = {for (final p in pacientes) p.idPaciente: p.nome};

    final lista = agendamentos
        .where((a) => UtilitariosData.mesmoMesAno(a.data, _mes))
        .where(_passaFiltro)
        .where((a) {
          if (_busca.isEmpty) return true;
          final nome = (mapaNomes[a.idPaciente] ?? '').toLowerCase();
          return nome.contains(_busca.toLowerCase());
        })
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    final grupos = <String, List<Agendamento>>{};
    for (final a in lista) {
      final chave = UtilitariosData.rotuloDiaRelativo(a.data);
      grupos.putIfAbsent(chave, () => []).add(a);
    }

    return Material(
      color: FisioCores.surface,
      child: FisioResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FisioGradientHeader(
              eyebrow: 'Agenda',
              titulo: 'Sessões',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FisioHeaderIconButton(Icons.chevron_left_rounded,
                      size: 32, onTap: () => _mudarMes(-1)),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: Text(UtilitariosData.formatarMesAno(_mes),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  FisioHeaderIconButton(Icons.chevron_right_rounded,
                      size: 32, onTap: () => _mudarMes(1)),
                ],
              ),
              bottom: FisioSearchField(
                hint: 'Buscar paciente…',
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FisioFilterChips(
                filtros: _labels,
                selecionado: _filtro,
                onChanged: (i) => setState(() => _filtro = i),
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const FisioEmptyState(
                      icone: Icons.event_busy_rounded,
                      titulo: 'Nenhuma sessão',
                      subtitulo: 'Ajuste o filtro ou o mês selecionado.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                      children: [
                        for (final entry in grupos.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Text(entry.key.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: FisioCores.textMuted,
                                    letterSpacing: 0.5)),
                          ),
                          ...entry.value.map(
                              (a) => _linha(a, mapaNomes[a.idPaciente] ?? 'Paciente')),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(Agendamento a, String nome) {
    final status = a.foiRealizado
        ? 'Realizado'
        : (a.estaAtrasado(DateTime.now())
            ? 'Vencida'
            : a.estaAgendado
                ? 'Agendado'
                : a.situacao);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: FisioCard(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        onTap: () => widget.onAbrir?.call(a),
        child: Row(
          children: [
            FisioAvatar(nome, size: 42, radius: 13),
            const SizedBox(width: 12),
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
                  Text(
                      '${a.horaInicio} · R\$ ${a.valorSessao.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: FisioCores.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FisioStatusPill.sessao(status),
          ],
        ),
      ),
    );
  }
}
