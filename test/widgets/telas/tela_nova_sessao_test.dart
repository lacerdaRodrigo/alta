import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import 'package:alta/telas/tela_nova_sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes e notifiers de teste.
// ---------------------------------------------------------------------------

class FakeRepositorioDadosGoogle extends Fake
    implements RepositorioDadosGoogle {
  @override
  Future<void> salvarAgendamento(Agendamento agendamento) async {}
}

class RepositorioQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarAgendamento(Agendamento agendamento) async {
    throw Exception('falha simulada ao salvar');
  }
}

class PacientesComDados extends ListaPacientesNotifier {
  final List<Paciente> _dados;

  PacientesComDados(this._dados);

  @override
  List<Paciente> build() => _dados;
}

class AgendamentosComDados extends ListaAgendamentosNotifier {
  final List<Agendamento> _dados;

  AgendamentosComDados(this._dados);

  @override
  List<Agendamento> build() => _dados;
}

Paciente _paciente({
  String id = 'P001',
  String nome = 'João Teste',
  String situacao = 'Ativo',
}) {
  return Paciente(
    idPaciente: id,
    nome: nome,
    telefone: '11999999999',
    dataNascimento: DateTime(1990, 1, 1),
    cpf: '12345678901',
    endereco: 'Rua A',
    situacao: situacao,
  );
}

ProviderContainer _criarContainer({
  List<Paciente> pacientes = const [],
  List<Agendamento> agendamentos = const [],
  RepositorioDadosGoogle? repositorio,
}) {
  return ProviderContainer(
    overrides: [
      provedorListaPacientes.overrideWith(() => PacientesComDados(pacientes)),
      provedorListaAgendamentos.overrideWith(
        () => AgendamentosComDados(agendamentos),
      ),
      if (repositorio != null)
        provedorRepositorioDados.overrideWith((ref) => repositorio),
    ],
  );
}

/// Monta a tela numa superfície grande e em formato de 24h.
Future<void> _montar(WidgetTester tester, ProviderContainer container) async {
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: const TelaNovaSessao(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Seleciona um paciente via bottom sheet.
Future<void> _selecionarPaciente(WidgetTester tester, String nome) async {
  await tester.tap(find.text('Selecionar paciente'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nome).last);
  await tester.pumpAndSettle();
}

/// Abre o seletor de hora e confirma (mantém horário atual no picker).
Future<void> _selecionarHorario(
  WidgetTester tester,
  String hora,
  String minuto,
) async {
  // Tap on the time field card (labeled 'Início')
  await tester.tap(find.text('Início'));
  await tester.pumpAndSettle();
  // Switch to keyboard input mode
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  // Enter hour and minute inside the dialog
  final campos = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(campos.at(0), hora);
  await tester.enterText(campos.at(1), minuto);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaNovaSessao — renderização', () {
    testWidgets('exibe título, campos e valor padrão preenchido', (
      tester,
    ) async {
      await _montar(tester, _criarContainer(pacientes: [_paciente()]));

      expect(find.text('Nova sessão'), findsOneWidget);
      expect(find.text('Agendar atendimento'), findsOneWidget);
      // Patient card
      expect(find.text('Selecionar paciente'), findsOneWidget);
      // Action button
      expect(find.text('Agendar sessão'), findsOneWidget);

      // O valor é pré-preenchido com o padrão (150,00).
      final valor = tester.widget<TextField>(
        find.widgetWithText(TextField, '150,00').first,
      );
      expect(valor.controller?.text, '150,00');
    });

    testWidgets('sem pacientes ativos exibe aviso no bottom sheet', (tester) async {
      await _montar(
        tester,
        _criarContainer(
          pacientes: [_paciente(situacao: 'Arquivado')],
        ),
      );

      // Open patient selector bottom sheet
      await tester.tap(find.text('Selecionar paciente'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum paciente ativo. Cadastre um paciente antes.'),
        findsOneWidget,
      );
    });
  });

  group('TelaNovaSessao — validação', () {
    testWidgets('agendar sem selecionar paciente mostra erro de validação', (
      tester,
    ) async {
      await _montar(tester, _criarContainer(pacientes: [_paciente()]));

      await tester.tap(find.text('Agendar sessão'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione um paciente.'), findsOneWidget);
    });

    testWidgets('paciente selecionado com data futura padrão agenda sem erro', (
      tester,
    ) async {
      final container = _criarContainer(
        pacientes: [_paciente()],
        repositorio: FakeRepositorioDadosGoogle(),
      );
      await _montar(tester, container);

      await _selecionarPaciente(tester, 'João Teste');

      // Default _data is tomorrow at 09:00 — future, valid
      await tester.tap(find.text('Agendar sessão'));
      await tester.pump(); // capture state before pumpAndSettle clears snackbar

      // Agendamento salvo — snackbar de sucesso OR agendamentos atualizado
      final agendamentos = container.read(provedorListaAgendamentos);
      expect(agendamentos, hasLength(1));
      expect(agendamentos.first.idPaciente, 'P001');
    });
  });

  group('TelaNovaSessao — seletores e agendamento', () {
    testWidgets('selecionar horário preenche o campo de hora', (tester) async {
      await _montar(tester, _criarContainer(pacientes: [_paciente()]));

      expect(find.text('09:00'), findsOneWidget);
      await _selecionarHorario(tester, '14', '30');

      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('data/horário retroativo exibe mensagem de erro', (
      tester,
    ) async {
      await _montar(
        tester,
        _criarContainer(
          pacientes: [_paciente()],
          repositorio: FakeRepositorioDadosGoogle(),
        ),
      );

      await _selecionarPaciente(tester, 'João Teste');
      // Select midnight via time picker — combined with today's date, this is past
      await _selecionarHorario(tester, '00', '00');

      // Tap on date field to open date picker
      final dataLabel = find.text('Data');
      await tester.tap(dataLabel);
      await tester.pumpAndSettle();
      // Navigate to today in the date picker (it starts on tomorrow)
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      // Tap today's day number
      final hoje = DateTime.now().day.toString();
      await tester.tap(find.text(hoje).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agendar sessão'));
      await tester.pumpAndSettle();

      expect(
        find.text('Selecione uma data e horário futuros.'),
        findsOneWidget,
      );
    });

    testWidgets('agendamento válido salva e volta para a tela anterior', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = _criarContainer(
        pacientes: [_paciente()],
        repositorio: FakeRepositorioDadosGoogle(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR')],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaNovaSessao()),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Select patient from bottom sheet
      await tester.tap(find.text('Selecionar paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('João Teste').last);
      await tester.pumpAndSettle();

      // Default date is tomorrow at 09:00 — valid future date/time
      await tester.tap(find.text('Agendar sessão'));
      await tester.pumpAndSettle();

      // Voltou para a tela anterior e o agendamento foi salvo.
      expect(find.text('Nova sessão'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);

      final agendamentos = container.read(provedorListaAgendamentos);
      expect(agendamentos, hasLength(1));
      expect(agendamentos.first.idPaciente, 'P001');
      expect(agendamentos.first.horaInicio, '09:00');
    });

    testWidgets('falha ao salvar exibe snackbar de erro', (tester) async {
      await _montar(
        tester,
        _criarContainer(
          pacientes: [_paciente()],
          repositorio: RepositorioQueFalha(),
        ),
      );

      await _selecionarPaciente(tester, 'João Teste');

      await tester.tap(find.text('Agendar sessão'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });
  });

  group('TelaNovaSessao — navegação', () {
    testWidgets('botão fechar aciona o retorno', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = _criarContainer(pacientes: [_paciente()]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR')],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaNovaSessao()),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Nova sessão'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_fechar')));
      await tester.pumpAndSettle();

      // Voltou para a tela anterior.
      expect(find.text('Nova sessão'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });
  });
}
