import 'package:flutter/material.dart';

import 'design_system.dart';
import '../modelos/evolucao.dart';
import '../modelos/paciente.dart';
import '../telas/tela_registro_evolucao.dart';
import '../utilitarios/utilitarios_data.dart';

/// Cor de destaque da condição clínica. Fica aqui, e não na tela, porque tanto
/// o card da lista quanto este modal precisam pintar o mesmo registro igual.
Color corCondicaoEvolucao(String condicao) {
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

/// Visualização somente leitura de uma evolução.
///
/// O card da lista corta o texto clínico em 3 linhas; este modal é o único
/// lugar onde ele aparece inteiro. Por isso abre **sempre**, independente das
/// 24h de [Evolucao.janelaEdicao] — a janela só decide se o botão de editar
/// aparece, nunca se o registro pode ser lido.
///
/// [paciente] pode ser nulo quando o registro aponta para um paciente que não
/// está mais na lista carregada.
void mostrarModalDetalhesEvolucao(
  BuildContext context, {
  required Evolucao evolucao,
  required Paciente? paciente,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(FisioRaios.lg)),
    ),
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final cor = corCondicaoEvolucao(evolucao.condicaoPaciente);
      final alturaMaxima = MediaQuery.of(sheetContext).size.height * 0.72;
      // Sem paciente não dá para abrir a edição: `TelaRegistroEvolucao` exige
      // um `Paciente` não-nulo.
      final podeEditar = evolucao.editavel && paciente != null;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: alturaMaxima),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(FisioRaios.lg),
                ),
                border: Border.all(color: FisioCores.border),
                boxShadow: FisioSombras.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _Cabecalho(evolucao: evolucao, paciente: paciente, cor: cor),
                  const SizedBox(height: 16),
                  _Metadados(evolucao: evolucao),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Único bloco rolável: o texto clínico não tem limite de
                  // tamanho e é justamente o que o card da lista escondia.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FisioCores.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(
                          evolucao.evolucaoTexto.isEmpty
                              ? 'Registro sem descrição clínica.'
                              : evolucao.evolucaoTexto,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: evolucao.evolucaoTexto.isEmpty
                                ? FisioCores.textSecondary
                                : FisioCores.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (podeEditar)
                    FisioPrimaryButton(
                      'Editar',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TelaRegistroEvolucao(
                              paciente: paciente,
                              evolucaoExistente: evolucao,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const _RegistroFechado(),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Cabecalho extends StatelessWidget {
  final Evolucao evolucao;
  final Paciente? paciente;
  final Color cor;

  const _Cabecalho({
    required this.evolucao,
    required this.paciente,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: FisioDecoracoes.tinted(cor, radius: 16),
          child: Icon(Icons.edit_note_rounded, color: cor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paciente?.nome ?? 'Paciente não encontrado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FisioCores.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                UtilitariosData.formatarDataBr(evolucao.dataAtendimento),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        FisioBadge(label: evolucao.condicaoPaciente, color: cor),
      ],
    );
  }
}

class _Metadados extends StatelessWidget {
  final Evolucao evolucao;

  const _Metadados({required this.evolucao});

  String _formatHora(DateTime data) =>
      '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final sinaisVitais = [
      if (evolucao.pressaoArterial != null &&
          evolucao.pressaoArterial!.isNotEmpty)
        'PA: ${evolucao.pressaoArterial}',
      if (evolucao.frequenciaCardiaca != null)
        'FC: ${evolucao.frequenciaCardiaca} bpm',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LinhaInfo(
          icone: Icons.person_pin_rounded,
          texto: 'Status: ${evolucao.statusPresenca}',
        ),
        const SizedBox(height: 6),
        _LinhaInfo(
          icone: Icons.access_time_rounded,
          texto:
              '${_formatHora(evolucao.horarioInicioReal)} — ${_formatHora(evolucao.horarioFimReal)} (Real)',
        ),
        const SizedBox(height: 6),
        _LinhaInfo(
          icone: Icons.favorite_outline_rounded,
          texto: 'Dor: ${evolucao.dorSessao}/10',
        ),
        const SizedBox(height: 6),
        _LinhaInfo(
          icone: Icons.location_on_outlined,
          texto: evolucao.localAtendimento,
        ),
        if (sinaisVitais.isNotEmpty) ...[
          const SizedBox(height: 6),
          _LinhaInfo(
            icone: Icons.monitor_heart_outlined,
            texto: sinaisVitais.join(' | '),
          ),
        ],
      ],
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _LinhaInfo({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 17, color: FisioCores.textSecondary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FisioCores.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Explicita por que não há botão de editar, em vez de só omiti-lo.
class _RegistroFechado extends StatelessWidget {
  const _RegistroFechado();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FisioCores.inputFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: FisioCores.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: FisioCores.textSecondary,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Registro fechado — mais de 24h',
              style: TextStyle(
                fontSize: 13,
                color: FisioCores.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
