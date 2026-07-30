import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../componentes/design_system.dart';
import '../modelos/agendamento.dart';
import '../utilitarios/formatters.dart';
import '../utilitarios/gerador_id.dart';
import '../modelos/evolucao.dart';
import '../modelos/paciente.dart';
import '../provedores/provedores_dados.dart';
import '../utilitarios/utilitarios_data.dart';

class TelaRegistroEvolucao extends ConsumerStatefulWidget {
  final Paciente paciente;
  final Agendamento? agendamento;
  final Evolucao? evolucaoExistente;

  const TelaRegistroEvolucao({
    super.key,
    required this.paciente,
    this.agendamento,
    this.evolucaoExistente,
  });

  @override
  ConsumerState<TelaRegistroEvolucao> createState() =>
      _TelaRegistroEvolucaoState();
}

class _TelaRegistroEvolucaoState extends ConsumerState<TelaRegistroEvolucao> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _evolucaoController = TextEditingController();
  final _paController = TextEditingController();
  final _fcController = TextEditingController();
  final _speech = stt.SpeechToText();
  bool _ouvindo = false;
  bool _salvando = false;

  String _statusPresenca = 'Presente';
  String _localAtendimento = 'Domicílio';
  int _dorSessao = 0;
  String _condicaoClinica = 'Melhora';
  TimeOfDay _horarioInicio = TimeOfDay.now();
  TimeOfDay _horarioFim = TimeOfDay.now();

  final _statusOpcoes = ['Presente', 'Ausente com aviso', 'Ausente sem aviso'];
  final _localOpcoes = ['Domicílio', 'Clínica', 'Teleatendimento'];

  bool get _editando => widget.evolucaoExistente != null;

  bool get _editavel {
    if (!_editando) return true;
    return widget.evolucaoExistente!.editavel;
  }

  TimeOfDay _dateToTimeOfDay(DateTime data) =>
      TimeOfDay(hour: data.hour, minute: data.minute);

  @override
  void initState() {
    super.initState();

    final evol = widget.evolucaoExistente;

    if (evol != null) {
      _statusPresenca = evol.statusPresenca;
      _localAtendimento = evol.localAtendimento;
      _dorSessao = evol.dorSessao;
      _condicaoClinica = evol.condicaoPaciente == 'Faltou'
          ? 'Melhora'
          : evol.condicaoPaciente;
      _horarioInicio = _dateToTimeOfDay(evol.horarioInicioReal);
      _horarioFim = _dateToTimeOfDay(evol.horarioFimReal);
      _evolucaoController.text = evol.evolucaoTexto;
      _paController.text = evol.pressaoArterial ?? '';
      _fcController.text = evol.frequenciaCardiaca?.toString() ?? '';
    } else {
      final agora = TimeOfDay.now();
      _horarioInicio = widget.agendamento != null
          ? _parseTimeOfDay(widget.agendamento!.horaInicio)
          : agora;
      _horarioFim = widget.agendamento != null
          ? _parseTimeOfDay(widget.agendamento!.horaFim)
          : TimeOfDay(
              hour: agora.hour + 1 > 23 ? 23 : agora.hour + 1,
              minute: agora.minute,
            );
    }
  }

  TimeOfDay _parseTimeOfDay(String hora) {
    final partes = hora.split(':');
    if (partes.length != 2) return TimeOfDay.now();
    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 0,
      minute: int.tryParse(partes[1]) ?? 0,
    );
  }

  @override
  void dispose() {
    _evolucaoController.dispose();
    _paController.dispose();
    _fcController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAtendimento = widget.agendamento?.data ?? DateTime.now();
    final horario = widget.agendamento?.horaInicio;

    return Scaffold(
      body: Column(
        children: [
          FisioGradientHeader(
            padding: const EdgeInsets.fromLTRB(18, 50, 18, 22),
            titulo: _editando ? 'Editar Evolução' : 'Registrar Evolução',
            subtitulo: widget.paciente.nome,
            leading: FisioHeaderIconButton(Icons.chevron_left_rounded,
                key: const Key('btn_fechar'),
                onTap: () => Navigator.pop(context)),
          ),
          Expanded(
            child: Form(
              key: _chaveFormulario,
              child: FisioResponsiveCenter(
                maxWidth: 680,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
                  children: [
                    if (!_editavel && _editando) _buildBloqueioBanner(theme),
                    _buildHeader(theme, dataAtendimento, horario),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      'Informações Básicas',
                      Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusPresenca(theme),
                    const SizedBox(height: 12),
                    _buildHorariosReais(theme),
                    const SizedBox(height: 12),
                    _buildLocalAtendimento(theme),
                    const SizedBox(height: 12),
                    _buildDorSessao(theme),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      'Sinais Vitais (Opcional)',
                      Icons.favorite_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildSinaisVitais(theme),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      'Evolução Clínica',
                      Icons.edit_note_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildEvolucaoTexto(theme),
                    if (_ouvindo) _buildOuvindoIndicator(),
                    const SizedBox(height: 24),
                    _buildCondicaoClinica(theme),
                    const SizedBox(height: 32),
                    if (_editavel) _buildSaveButton(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueioBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FisioCores.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FisioCores.warning.withValues(alpha: 0.32)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF92400E),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Evolução bloqueada — mais de 24h do registro',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    DateTime dataAtendimento,
    String? horario,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FisioRaios.base),
        border: Border.all(color: FisioCores.border),
        boxShadow: FisioSombras.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: FisioCores.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_rounded,
                  color: FisioCores.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.paciente.nome,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.paciente.calcularIdade()} anos',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                UtilitariosData.formatarDataBr(dataAtendimento),
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (horario != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(horario, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titulo, IconData icone) {
    return FisioSectionTitle(title: titulo, icon: icone);
  }

  Widget _buildStatusPresenca(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _statusPresenca,
      decoration: const InputDecoration(
        labelText: 'Status de Presença *',
        prefixIcon: Icon(Icons.person_pin_rounded),
      ),
      items: _statusOpcoes.map((v) {
        return DropdownMenuItem(value: v, child: Text(v));
      }).toList(),
      onChanged: _editavel
          ? (v) {
              if (v != null) setState(() => _statusPresenca = v);
            }
          : null,
      validator: (v) => v == null ? 'Selecione o status de presença' : null,
    );
  }

  Widget _buildHorariosReais(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildTimePicker(
            label: 'Início Real *',
            value: _horarioInicio,
            onPicked: (t) => setState(() => _horarioInicio = t),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimePicker(
            label: 'Fim Real *',
            value: _horarioFim,
            onPicked: (t) => setState(() => _horarioFim = t),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay value,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _editavel
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value,
              );
              if (picked != null) onPicked(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_rounded),
        ),
        child: Text(
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildLocalAtendimento(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _localAtendimento,
      decoration: const InputDecoration(
        labelText: 'Local de Atendimento *',
        prefixIcon: Icon(Icons.home_rounded),
      ),
      items: _localOpcoes.map((v) {
        return DropdownMenuItem(value: v, child: Text(v));
      }).toList(),
      onChanged: _editavel
          ? (v) {
              if (v != null) setState(() => _localAtendimento = v);
            }
          : null,
      validator: (v) => v == null ? 'Selecione o local' : null,
    );
  }

  Widget _buildDorSessao(ThemeData theme) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Escala de Dor (0-10) *',
        prefixIcon: Icon(Icons.favorite_border_rounded),
        hintText: '0 a 10',
      ),
      keyboardType: TextInputType.number,
      readOnly: !_editavel,
      inputFormatters: [
        if (_editavel) FilteringTextInputFormatter.digitsOnly,
        if (_editavel) FormatterEscalaDor(),
      ],
      onChanged: _editavel
          ? (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed >= 0 && parsed <= 10) {
                _dorSessao = parsed;
              }
            }
          : null,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Informe a intensidade da dor';
        final dor = int.tryParse(v);
        if (dor == null || dor < 0 || dor > 10) {
          return 'A dor deve ser entre 0 e 10';
        }
        return null;
      },
    );
  }

  Widget _buildSinaisVitais(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _paController,
            decoration: const InputDecoration(
              labelText: 'Pressão Arterial',
              hintText: '120/80',
              prefixIcon: Icon(Icons.monitor_heart_outlined),
            ),
            keyboardType: TextInputType.text,
            readOnly: !_editavel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fcController,
            decoration: const InputDecoration(
              labelText: 'FC (bpm)',
              hintText: '72',
              prefixIcon: Icon(Icons.favorite_border_rounded),
            ),
            keyboardType: TextInputType.number,
            readOnly: !_editavel,
          ),
        ),
      ],
    );
  }

  Widget _buildEvolucaoTexto(ThemeData theme) {
    return TextFormField(
      controller: _evolucaoController,
      readOnly: !_editavel,
      decoration: InputDecoration(
        labelText: 'Evolução técnica *',
        hintText: 'Descreva exercícios, resposta do paciente e orientações...',
        alignLabelWithHint: true,
        suffixIcon: _editavel
            ? Container(
                decoration: BoxDecoration(
                  color: _ouvindo
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _alternarMicrofone,
                  tooltip: _ouvindo
                      ? 'Parar transcrição'
                      : 'Transcrever por voz',
                  icon: Icon(
                    _ouvindo ? Icons.mic_rounded : Icons.mic_none_rounded,
                  ),
                  color: _ouvindo
                      ? const Color(0xFFE11D48)
                      : FisioCores.primary,
                ),
              )
            : null,
      ),
      minLines: 6,
      maxLines: 12,
      textCapitalization: TextCapitalization.sentences,
      validator: (valor) => valor == null || valor.trim().isEmpty
          ? 'Informe a evolução clínica.'
          : null,
    );
  }

  Widget _buildOuvindoIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.graphic_eq_rounded, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Text('Ouvindo...', style: TextStyle(color: Colors.red.shade400)),
        ],
      ),
    );
  }

  Widget _buildCondicaoClinica(ThemeData theme) {
    final isAusente = _statusPresenca != 'Presente';

    if (isAusente) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Text(
              'Condição: Faltou',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _condicaoClinica,
      decoration: const InputDecoration(
        labelText: 'Condição Clínica *',
        prefixIcon: Icon(Icons.trending_up_rounded),
      ),
      items: ['Melhora', 'Estável', 'Piora'].map((v) {
        return DropdownMenuItem(value: v, child: Text(v));
      }).toList(),
      onChanged: _editavel
          ? (v) {
              if (v != null) setState(() => _condicaoClinica = v);
            }
          : null,
      validator: (v) => v == null ? 'Selecione a condição' : null,
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _salvando ? null : _salvarEvolucao,
        icon: _salvando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(
          _salvando
              ? 'Salvando...'
              : _editando
              ? 'Atualizar Evolução'
              : 'Salvar Evolução',
        ),
      ),
    );
  }

  Future<void> _alternarMicrofone() async {
    if (_ouvindo) {
      await _speech.stop();
      if (mounted) setState(() => _ouvindo = false);
      return;
    }

    final disponivel = await _speech.initialize();
    if (!mounted) return;

    if (!disponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de microfone necessária para transcrição por voz.',
          ),
        ),
      );
      return;
    }

    setState(() => _ouvindo = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'pt_BR'),
      onResult: (resultado) {
        if (!resultado.finalResult ||
            resultado.recognizedWords.trim().isEmpty) {
          return;
        }
        final atual = _evolucaoController.text.trim();
        final texto = resultado.recognizedWords.trim();
        _evolucaoController.text = [
          atual,
          texto,
        ].where((parte) => parte.isNotEmpty).join(' ');
        _evolucaoController.selection = TextSelection.collapsed(
          offset: _evolucaoController.text.length,
        );
      },
    );
  }

  Future<void> _salvarEvolucao() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    if (!_editavel) return;

    setState(() => _salvando = true);

    final evolucoes = ref.read(provedorListaEvolucoes);
    final dataAtendimento = widget.agendamento?.data ?? DateTime.now();

    final isAusente = _statusPresenca != 'Presente';
    final condicao = isAusente ? 'Faltou' : _condicaoClinica;

    final idEvolucao = _editando
        ? widget.evolucaoExistente!.idEvolucao
        : GeradorId.proximo('E', evolucoes.map((e) => e.idEvolucao));

    final evolucao = Evolucao(
      idEvolucao: idEvolucao,
      idPaciente: widget.paciente.idPaciente,
      dataRegistro: widget.evolucaoExistente?.dataRegistro,
      idAgendamento:
          widget.agendamento?.idAgendamento ??
          'AVULSA-${DateTime.now().millisecondsSinceEpoch}',
      dataAtendimento: dataAtendimento,
      evolucaoTexto: _evolucaoController.text.trim(),
      localAtendimento: _localAtendimento,
      statusPresenca: _statusPresenca,
      dorSessao: _dorSessao,
      horarioInicioReal: DateTime(
        dataAtendimento.year,
        dataAtendimento.month,
        dataAtendimento.day,
        _horarioInicio.hour,
        _horarioInicio.minute,
      ),
      horarioFimReal: DateTime(
        dataAtendimento.year,
        dataAtendimento.month,
        dataAtendimento.day,
        _horarioFim.hour,
        _horarioFim.minute,
      ),
      condicaoPaciente: condicao,
      pressaoArterial: _paController.text.trim().isEmpty
          ? null
          : _paController.text.trim(),
      frequenciaCardiaca: int.tryParse(_fcController.text.trim()),
    );

    try {
      if (_editando) {
        await atualizarEvolucaoReal(ref, evolucao);
      } else {
        await salvarEvolucaoReal(ref, evolucao);
        if (widget.agendamento != null) {
          await marcarAgendamentoRealizadoReal(
            ref,
            widget.agendamento!.idAgendamento,
          );
        }
      }

      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Evolução atualizada com sucesso!'
                : 'Evolução salva com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro inesperado. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
