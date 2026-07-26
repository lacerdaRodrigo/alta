import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../componentes/design_system.dart';
import '../modelos/paciente.dart';
import '../provedores/provedores_dados.dart';
import 'tela_historico_geral_evolucoes.dart';

class TelaPacientes extends ConsumerStatefulWidget {
  final void Function(Paciente)? onAbrir;
  final VoidCallback? onNovo;
  const TelaPacientes({super.key, this.onAbrir, this.onNovo});

  @override
  ConsumerState<TelaPacientes> createState() => _TelaPacientesState();
}

enum FiltroPacientes { ativos, todos, arquivados }

class _TelaPacientesState extends ConsumerState<TelaPacientes> {
  String _busca = '';
  FiltroPacientes _filtro = FiltroPacientes.ativos;

  @override
  Widget build(BuildContext context) {
    final pacientes = ref.watch(provedorListaPacientes);

    final filtrados = pacientes.where((p) {
      final passaFiltro = switch (_filtro) {
        FiltroPacientes.ativos => p.estaAtivo,
        FiltroPacientes.arquivados => !p.estaAtivo,
        FiltroPacientes.todos => true,
      };
      if (!passaFiltro) return false;
      if (_busca.isEmpty) return true;
      final q = _busca.toLowerCase();
      final qDigitos = q.replaceAll(RegExp(r'\D'), '');
      return p.nome.toLowerCase().contains(q) ||
          (qDigitos.isNotEmpty &&
              p.cpf.replaceAll(RegExp(r'\D'), '').contains(qDigitos));
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    final grupos = <String, List<Paciente>>{};
    for (final p in filtrados) {
      final letra = p.nome.isEmpty ? '#' : p.nome[0].toUpperCase();
      grupos.putIfAbsent(letra, () => []).add(p);
    }
    final letras = grupos.keys.toList()..sort();

    return Material(
      color: FisioCores.surface,
      child: FisioResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FisioGradientHeader(
              eyebrow: 'Cadastro',
              titulo: 'Pacientes',
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pacientes.length}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1)),
                  Text('no total',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
              bottom: FisioSearchField(
                hint: 'Buscar por nome ou CPF…',
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: FisioFilterChips(
                filtros: const ['Ativos', 'Todos', 'Arquivados'],
                selecionado: _filtro.index,
                onChanged: (i) =>
                    setState(() => _filtro = FiltroPacientes.values[i]),
                trailing: _botaoHistorico(),
              ),
            ),
            Expanded(
              child: filtrados.isEmpty
                  ? const FisioEmptyState(
                      icone: Icons.person_search_rounded,
                      titulo: 'Nenhum paciente encontrado',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                      itemCount: letras.length,
                      itemBuilder: (context, gi) {
                        final letra = letras[gi];
                        final itens = grupos[letra]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 0, 0, 9),
                              child: Text(letra,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: FisioCores.primary)),
                            ),
                            ...itens.map(_linhaPaciente),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoHistorico() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const TelaHistoricoGeralEvolucoes()),
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: FisioCores.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Evoluções',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: FisioCores.textSecondary)),
      ),
    );
  }

  Widget _linhaPaciente(Paciente p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: FisioCard(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        onTap: () => widget.onAbrir?.call(p),
        child: Row(
          children: [
            FisioAvatar(p.nome, size: 46, radius: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: FisioCores.textPrimary)),
                  const SizedBox(height: 1),
                  Text(p.estaAtivo ? 'Em tratamento' : 'Arquivado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: FisioCores.textMuted)),
                ],
              ),
            ),
            if (p.estaAtivo)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: FisioCores.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: FisioCores.success.withValues(alpha: 0.18),
                        blurRadius: 0,
                        spreadRadius: 4),
                  ],
                ),
              ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}
