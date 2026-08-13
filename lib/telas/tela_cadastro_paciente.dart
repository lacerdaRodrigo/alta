import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../componentes/design_system.dart';
import '../modelos/paciente.dart';
import '../provedores/provedores_dados.dart';
import '../utilitarios/formatters.dart';

class TelaCadastroPaciente extends ConsumerStatefulWidget {
  const TelaCadastroPaciente({super.key});

  @override
  ConsumerState<TelaCadastroPaciente> createState() =>
      _TelaCadastroPacienteState();
}

class _TelaCadastroPacienteState extends ConsumerState<TelaCadastroPaciente> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _queixaController = TextEditingController();
  String _genero = 'Masculino';
  final _dorController = TextEditingController();
  final _historicoController = TextEditingController();
  final _histPregressoController = TextEditingController();
  final _ocupacaoController = TextEditingController();
  final _comorbidadesController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _cirurgiasController = TextEditingController();
  final _habitosVidaController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  String _rua = '';
  String _bairro = '';
  String _numero = '';
  String _cidade = '';

  String get _enderecoCompleto {
    final partes = <String>[
      if (_rua.isNotEmpty) _rua,
      if (_numero.isNotEmpty) _numero,
      if (_bairro.isNotEmpty) _bairro,
      if (_cidade.isNotEmpty) _cidade,
    ];
    return partes.isEmpty ? '' : partes.join(', ');
  }

  DateTime? _dataNascimento;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _queixaController.dispose();
    _dorController.dispose();
    _historicoController.dispose();
    _histPregressoController.dispose();
    _ocupacaoController.dispose();
    _comorbidadesController.dispose();
    _medicamentosController.dispose();
    _alergiasController.dispose();
    _cirurgiasController.dispose();
    _habitosVidaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FisioGradientHeader(
            padding: const EdgeInsets.fromLTRB(18, 50, 18, 22),
            titulo: 'Novo Paciente',
            subtitulo: 'Dados pessoais e anamnese clínica',
            leading: FisioHeaderIconButton(Icons.chevron_left_rounded,
                key: const Key('btn_fechar'),
                onTap: () => Navigator.pop(context)),
          ),
          Expanded(
            child: Form(
              key: _chaveFormulario,
              child: FisioResponsiveCenter(
                maxWidth: 680,
                child: AbsorbPointer(
                  absorbing: _salvando,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    children: [
                      // Seção: Dados Pessoais
                      _construirTituloSecao(
                        'Dados Pessoais',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_nome'),
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_cpf'),
                        controller: _cpfController,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.fingerprint_rounded),
                          hintText: '000.000.000-00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _cpfFormatter,
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_telefone'),
                        controller: _telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '(00) 00000-0000',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _telefoneFormatter,
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Data de Nascimento
                      InkWell(
                        key: const Key('campo_data_nascimento'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showDatePicker(
                            context: context,
                            initialDate: _dataNascimento ?? DateTime(1990),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            locale: const Locale('pt', 'BR'),
                          ).then((data) {
                            if (data != null) {
                              setState(() => _dataNascimento = data);
                            }
                          });
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data de Nascimento',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            _dataNascimento != null
                                ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'
                                : 'Selecionar data',
                            style: TextStyle(
                              color: _dataNascimento != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      InkWell(
                        key: const Key('campo_endereco'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _mostrarModalEndereco(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Endereço *',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            suffixIcon: Icon(
                              Icons.edit_location_alt_rounded,
                            ),
                          ),
                          child: Text(
                            _enderecoCompleto.isEmpty
                                ? 'Toque para preencher endereço'
                                : _enderecoCompleto,
                            style: TextStyle(
                              color: _enderecoCompleto.isNotEmpty
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Seção: Anamnese Clínica
                      _construirTituloSecao(
                        'Anamnese Clínica',
                        Icons.medical_information_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Subseção: Sintomas e Queixas
                      _construirSubtituloSecao('Sintomas e Queixas'),
                      const SizedBox(height: 8),

                      TextFormField(
                        key: const Key('campo_queixa'),
                        controller: _queixaController,
                        decoration: const InputDecoration(
                          labelText: 'Queixa Principal (QP)',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_hda'),
                        controller: _historicoController,
                        decoration: const InputDecoration(
                          labelText: 'Histórico da Doença Atual (HDA)',
                          hintText: 'EVA, fatores de piora/melhora...',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_hp'),
                        controller: _histPregressoController,
                        decoration: const InputDecoration(
                          labelText: 'História Pregressa (HP)',
                          hintText: 'Antecedentes, comorbidades prévias...',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_ocupacao'),
                        controller: _ocupacaoController,
                        decoration: const InputDecoration(
                          labelText: 'Ocupação / Profissão',
                          prefixIcon: Icon(Icons.work_outline),
                          hintText: 'Ex: Professor, Motorista, Aposentado...',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        key: const Key('dropdown_genero'),
                        initialValue: _genero,
                        decoration: const InputDecoration(
                          labelText: 'Gênero',
                          prefixIcon: Icon(Icons.transgender),
                        ),
                        items: ['Masculino', 'Feminino', 'Outro'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _genero = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione o gênero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_escala_dor'),
                        controller: _dorController,
                        decoration: const InputDecoration(
                          labelText: 'Escala de dor (0-10)',
                          hintText: '0 a 10',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          FormatterEscalaDor(),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Subseção: Histórico Clínico
                      _construirSubtituloSecao('Histórico Clínico'),
                      const SizedBox(height: 8),

                      TextFormField(
                        key: const Key('campo_comorbidades'),
                        controller: _comorbidadesController,
                        decoration: const InputDecoration(
                          labelText: 'Comorbidades/Doenças Prévias',
                          hintText:
                              'Ex: Hipertensão, Diabetes, Cardiopatias...',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_medicamentos'),
                        controller: _medicamentosController,
                        decoration: const InputDecoration(
                          labelText: 'Medicamentos em Uso',
                          hintText: 'Liste os medicamentos atuais...',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_alergias'),
                        controller: _alergiasController,
                        decoration: const InputDecoration(
                          labelText: 'Alergias',
                          hintText: 'Ex: Dipirona, Látex, Iodo...',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        key: const Key('campo_cirurgias'),
                        controller: _cirurgiasController,
                        decoration: const InputDecoration(
                          labelText: 'Cirurgias/Traumas Prévios',
                          hintText:
                              'Ex: Fraturas, implantes metálicos, cirurgias...',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),

                      // Subseção: Estilo de Vida
                      _construirSubtituloSecao('Estilo de Vida'),
                      const SizedBox(height: 8),

                      TextFormField(
                        key: const Key('campo_habitos'),
                        controller: _habitosVidaController,
                        decoration: const InputDecoration(
                          labelText: 'Hábitos de Vida / Atividade Física',
                          hintText:
                              'Sedentarismo, frequência de exercícios, profissão...',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Botão Salvar fixo no final da tela
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  key: const Key('btn_salvar_paciente'),
                  onPressed: _salvando ? null : _salvarPaciente,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar Paciente'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTituloSecao(String titulo, IconData icone) {
    return FisioSectionTitle(title: titulo, icon: icone);
  }

  Widget _construirSubtituloSecao(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: FisioCores.primary,
      ),
    );
  }

  Future<void> _mostrarModalEndereco() async {
    final rua = _rua;
    final bairro = _bairro;
    final numero = _numero;
    final cidade = _cidade;

    final resultado = await showDialog<_Endereco>(
      context: context,
      builder: (ctx) => _ModalEndereco(
        rua: rua,
        bairro: bairro,
        numero: numero,
        cidade: cidade,
      ),
    );

    if (resultado != null) {
      setState(() {
        _rua = resultado.rua;
        _bairro = resultado.bairro;
        _numero = resultado.numero;
        _cidade = resultado.cidade;
      });
    }
  }

  List<String> _listarCamposFaltando() {
    final faltando = <String>[];

    if (_nomeController.text.trim().isEmpty) faltando.add('Nome Completo');

    final digitosTel = _telefoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digitosTel.isEmpty) {
      faltando.add('Telefone');
    } else if (digitosTel.length < 10) {
      faltando.add('Telefone inválido (mínimo 10 dígitos)');
    }

    if (_dataNascimento == null) faltando.add('Data de Nascimento');
    if (_enderecoCompleto.isEmpty) faltando.add('Endereço');
    if (_dorController.text.trim().isEmpty) faltando.add('Escala de dor (0-10)');

    return faltando;
  }

  void _mostrarDialogCamposFaltando(List<String> campos) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Campos obrigatórios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verifique os seguintes campos:'),
            const SizedBox(height: 12),
            ...campos.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(c),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Avisa que Nome, CPF, Data de Nascimento e Gênero não poderão ser editados
  /// depois do cadastro. Retorna `true` se o usuário confirmar.
  Future<bool> _confirmarCamposDefinitivos() async {
    const camposDefinitivos = [
      'Nome',
      'CPF',
      'Data de Nascimento',
      'Gênero',
    ];
    final confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('dialog_campos_definitivos'),
        title: const Text('Atenção: campos definitivos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Os campos abaixo NÃO poderão ser alterados depois do cadastro:',
            ),
            const SizedBox(height: 12),
            ...camposDefinitivos.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(c),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Deseja confirmar e salvar?'),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('btn_revisar_cadastro'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            key: const Key('btn_confirmar_cadastro'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar e salvar'),
          ),
        ],
      ),
    );
    return confirmou ?? false;
  }

  Future<void> _salvarPaciente() async {
    final faltando = _listarCamposFaltando();
    if (faltando.isNotEmpty) {
      _mostrarDialogCamposFaltando(faltando);
      return;
    }

    final pacientes = ref.read(provedorListaPacientes);
    final cpfLimpo = _cpfController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    // CPF não é mais obrigatório: com o campo em branco, `cpfLimpo` fica vazio
    // e não pode contar como duplicata — senão o segundo paciente sem CPF
    // já seria barrado pelo primeiro.
    final cpfJaCadastrado =
        cpfLimpo.isNotEmpty &&
        pacientes.any(
          (p) => p.cpf.replaceAll(RegExp(r'[^\d]'), '') == cpfLimpo,
        );

    if (cpfJaCadastrado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este CPF já está cadastrado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirma antes de marcar como "salvando" para que o spinner não anime
    // enquanto o diálogo de aviso está aberto.
    final confirmou = await _confirmarCamposDefinitivos();
    if (!confirmou || !mounted) return;

    setState(() => _salvando = true);

    final novoPaciente = Paciente(
      idPaciente: () {
        final maxId = pacientes.isEmpty
            ? 0
            : pacientes
                  .map(
                    (p) => int.tryParse(p.idPaciente.replaceAll('P', '')) ?? 0,
                  )
                  .reduce((a, b) => a > b ? a : b);
        return 'P${(maxId + 1).toString().padLeft(3, '0')}';
      }(),
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      dataNascimento: _dataNascimento!,
      cpf: _cpfController.text.trim(),
      endereco: _enderecoCompleto,
      queixaPrincipal: _queixaController.text.trim().isEmpty
          ? null
          : _queixaController.text.trim(),
      histDoencaAtual: _historicoController.text.trim().isEmpty
          ? null
          : _historicoController.text.trim(),
      histPregresso: _histPregressoController.text.trim().isEmpty
          ? null
          : _histPregressoController.text.trim(),
      ocupacao: _ocupacaoController.text.trim().isEmpty
          ? null
          : _ocupacaoController.text.trim(),
      comorbidades: _comorbidadesController.text.trim().isEmpty
          ? null
          : _comorbidadesController.text.trim(),
      medicamentos: _medicamentosController.text.trim().isEmpty
          ? null
          : _medicamentosController.text.trim(),
      alergias: _alergiasController.text.trim().isEmpty
          ? null
          : _alergiasController.text.trim(),
      cirurgias: _cirurgiasController.text.trim().isEmpty
          ? null
          : _cirurgiasController.text.trim(),
      habitosVida: _habitosVidaController.text.trim().isEmpty
          ? null
          : _habitosVidaController.text.trim(),
      genero: _genero,
      dor: _dorController.text.trim().isEmpty
          ? null
          : _dorController.text.trim(),
    );

    try {
      await salvarPacienteReal(ref, novoPaciente);
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente cadastrado com sucesso!'),
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

class _Endereco {
  final String rua;
  final String bairro;
  final String numero;
  final String cidade;

  _Endereco({
    required this.rua,
    required this.bairro,
    required this.numero,
    required this.cidade,
  });
}

class _ModalEndereco extends StatefulWidget {
  final String rua;
  final String bairro;
  final String numero;
  final String cidade;

  const _ModalEndereco({
    required this.rua,
    required this.bairro,
    required this.numero,
    required this.cidade,
  });

  @override
  State<_ModalEndereco> createState() => _ModalEnderecoState();
}

class _ModalEnderecoState extends State<_ModalEndereco> {
  late final TextEditingController _ruaController;
  late final TextEditingController _bairroController;
  late final TextEditingController _numeroController;
  late final TextEditingController _cidadeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ruaController = TextEditingController(text: widget.rua);
    _bairroController = TextEditingController(text: widget.bairro);
    _numeroController = TextEditingController(text: widget.numero);
    _cidadeController = TextEditingController(text: widget.cidade);
  }

  @override
  void dispose() {
    _ruaController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FisioRaios.base)),
      title: Row(
        children: [
          Icon(
            Icons.edit_location_alt_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Editar Endereço'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('campo_rua'),
                controller: _ruaController,
                decoration: const InputDecoration(labelText: 'Rua/Avenida *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a rua/avenida.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo_numero'),
                controller: _numeroController,
                decoration: const InputDecoration(labelText: 'Número'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo_bairro'),
                controller: _bairroController,
                decoration: const InputDecoration(labelText: 'Bairro *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o bairro.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo_cidade'),
                controller: _cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a cidade.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancelar_endereco'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const Key('btn_confirmar_endereco'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _Endereco(
                rua: _ruaController.text.trim(),
                bairro: _bairroController.text.trim(),
                numero: _numeroController.text.trim(),
                cidade: _cidadeController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}
