import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/design_system.dart';
import '../componentes/modal_detalhes_evolucao.dart';
import '../modelos/evolucao.dart';
import '../modelos/paciente.dart';
import '../provedores/provedores_dados.dart';
import '../utilitarios/utilitarios_data.dart';

enum VisualizacaoEvolucoes { lista, porPaciente }

class TelaHistoricoGeralEvolucoes extends ConsumerStatefulWidget {
  const TelaHistoricoGeralEvolucoes({super.key});

  @override
  ConsumerState<TelaHistoricoGeralEvolucoes> createState() =>
      _TelaHistoricoGeralEvolucoesState();
}

class _TelaHistoricoGeralEvolucoesState
    extends ConsumerState<TelaHistoricoGeralEvolucoes> {
  VisualizacaoEvolucoes _visualizacao = VisualizacaoEvolucoes.lista;
  final _buscaController = TextEditingController();
  String _termoBusca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evolucoes = [...ref.watch(provedorListaEvolucoes)]
      ..sort((a, b) => b.dataAtendimento.compareTo(a.dataAtendimento));
    final pacientes = {
      for (final paciente in ref.watch(provedorListaPacientes))
        paciente.idPaciente: paciente,
    };
    final evolucoesFiltradas = evolucoes
        .where((evolucao) => _aplicarBusca(evolucao, pacientes))
        .toList();
    final grupos = _agruparPorPaciente(evolucoesFiltradas);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(FisioRaios.lg),
                bottomRight: Radius.circular(FisioRaios.lg),
              ),
              boxShadow: FisioSombras.card,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Evoluções',
                        style: TextStyle(
                          color: FisioCores.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FisioBadge(
                      label: '${evolucoesFiltradas.length} registros',
                      color: FisioCores.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buscaController,
                  onChanged: (valor) => setState(() => _termoBusca = valor),
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente, texto, data ou condição...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _termoBusca.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _buscaController.clear();
                              setState(() => _termoBusca = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _seletorVisualizacao(),
              ],
            ),
          ),
          Expanded(
            child: evolucoesFiltradas.isEmpty
                ? const _EstadoVazio()
                : FisioResponsiveCenter(
                    maxWidth: 720,
                    child: _visualizacao == VisualizacaoEvolucoes.lista
                        ? _listaEvolucoes(evolucoesFiltradas, pacientes)
                        : _listaAgrupada(grupos, pacientes),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _seletorVisualizacao() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FisioCores.inputFill,
        borderRadius: BorderRadius.circular(FisioRaios.base),
        border: Border.all(color: FisioCores.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _botaoVisualizacao('Lista', VisualizacaoEvolucoes.lista),
          ),
          Expanded(
            child: _botaoVisualizacao(
              'Por paciente',
              VisualizacaoEvolucoes.porPaciente,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoVisualizacao(String label, VisualizacaoEvolucoes visualizacao) {
    final selecionado = _visualizacao == visualizacao;

    return GestureDetector(
      onTap: () => setState(() => _visualizacao = visualizacao),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selecionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selecionado ? FisioSombras.card : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selecionado ? FisioCores.primary : FisioCores.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _listaEvolucoes(
    List<Evolucao> evolucoes,
    Map<String, Paciente> pacientes,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      itemCount: evolucoes.length,
      itemBuilder: (context, index) {
        final evolucao = evolucoes[index];
        final paciente = pacientes[evolucao.idPaciente];
        return _CardEvolucaoGeral(
          evolucao: evolucao,
          paciente: paciente,
          onTap: () => mostrarModalDetalhesEvolucao(
            context,
            evolucao: evolucao,
            paciente: paciente,
          ),
        );
      },
    );
  }

  Widget _listaAgrupada(
    Map<String, List<Evolucao>> grupos,
    Map<String, Paciente> pacientes,
  ) {
    final idsPacientes = grupos.keys.toList()
      ..sort((a, b) {
        final nomeA = pacientes[a]?.nome ?? a;
        final nomeB = pacientes[b]?.nome ?? b;
        return nomeA.compareTo(nomeB);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      itemCount: idsPacientes.length,
      itemBuilder: (context, index) {
        final idPaciente = idsPacientes[index];
        final evolucoes = grupos[idPaciente]!;
        return _GrupoPacienteEvolucoes(
          paciente: pacientes[idPaciente],
          evolucoes: evolucoes,
        );
      },
    );
  }

  bool _aplicarBusca(Evolucao evolucao, Map<String, Paciente> pacientes) {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return true;

    final paciente = pacientes[evolucao.idPaciente];
    final data = UtilitariosData.formatarDataBr(evolucao.dataAtendimento);
    final alvo = [
      paciente?.nome,
      paciente?.cpf,
      data,
      evolucao.evolucaoTexto,
      evolucao.condicaoPaciente,
      evolucao.localAtendimento,
      evolucao.statusPresenca,
    ].whereType<String>().join(' ').toLowerCase();

    return alvo.contains(termo);
  }

  Map<String, List<Evolucao>> _agruparPorPaciente(List<Evolucao> evolucoes) {
    final grupos = <String, List<Evolucao>>{};
    for (final evolucao in evolucoes) {
      grupos.putIfAbsent(evolucao.idPaciente, () => []).add(evolucao);
    }
    for (final lista in grupos.values) {
      lista.sort((a, b) => b.dataAtendimento.compareTo(a.dataAtendimento));
    }
    return grupos;
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

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
              'Nenhuma evolução registrada ainda.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: FisioCores.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardEvolucaoGeral extends StatelessWidget {
  final Evolucao evolucao;
  final Paciente? paciente;
  final VoidCallback onTap;

  const _CardEvolucaoGeral({
    required this.evolucao,
    required this.paciente,
    required this.onTap,
  });

  Color get _corCondicao => corCondicaoEvolucao(evolucao.condicaoPaciente);

  @override
  Widget build(BuildContext context) {
    final nomePaciente = paciente?.nome ?? 'Paciente não encontrado';

    return FisioCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: FisioDecoracoes.tinted(_corCondicao, radius: 16),
                child: Icon(Icons.edit_note_rounded, color: _corCondicao),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomePaciente,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: FisioCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      UtilitariosData.formatarDataBr(evolucao.dataAtendimento),
                      style: const TextStyle(
                        color: FisioCores.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FisioBadge(label: evolucao.condicaoPaciente, color: _corCondicao),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            evolucao.evolucaoTexto.isEmpty
                ? 'Registro sem descrição clínica.'
                : evolucao.evolucaoTexto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: FisioCores.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.favorite_outline_rounded,
                label: 'Dor ${evolucao.dorSessao}/10',
              ),
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: evolucao.localAtendimento,
              ),
              _MetaChip(
                icon: Icons.person_pin_rounded,
                label: evolucao.statusPresenca,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrupoPacienteEvolucoes extends StatelessWidget {
  final Paciente? paciente;
  final List<Evolucao> evolucoes;

  const _GrupoPacienteEvolucoes({
    required this.paciente,
    required this.evolucoes,
  });

  @override
  Widget build(BuildContext context) {
    final nome = paciente?.nome ?? 'Paciente não encontrado';
    final cor = paciente == null
        ? FisioCores.primary
        : fisioAvatarColor(paciente!.nome);
    final ultima = evolucoes.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: FisioCores.card,
        borderRadius: BorderRadius.circular(FisioRaios.base),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cor.withValues(alpha: 0.16)),
              ),
              child: Center(
                child: Text(
                  paciente == null ? '??' : fisioIniciais(paciente!.nome),
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              nome,
              style: const TextStyle(
                color: FisioCores.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${evolucoes.length} evoluções • última: ${ultima.condicaoPaciente}',
              style: const TextStyle(color: FisioCores.textSecondary),
            ),
            children: [
              for (final evolucao in evolucoes)
                _CardEvolucaoGeral(
                  evolucao: evolucao,
                  paciente: paciente,
                  onTap: () => mostrarModalDetalhesEvolucao(
                    context,
                    evolucao: evolucao,
                    paciente: paciente,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FisioCores.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FisioCores.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FisioCores.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: FisioCores.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
