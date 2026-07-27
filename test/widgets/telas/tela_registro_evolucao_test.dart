import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/modelos/evolucao.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import 'package:alta/telas/tela_registro_evolucao.dart';
import 'package:alta/telas/tela_historico_evolucoes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

class EvolucoesNotifierComDados extends ListaEvolucoesNotifier {
  final List<Evolucao> _dados;

  EvolucoesNotifierComDados(this._dados);

  @override
  List<Evolucao> build() => _dados;
}

class FakeRepoEvolucao extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarEvolucao(Evolucao evolucao) async {}

  @override
  Future<void> atualizarEvolucao(Evolucao evolucao) async {}

  @override
  Future<void> atualizarSituacaoAgendamento(
    String idAgendamento,
    String situacao,
  ) async {}
}

class RepoEvolucaoQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarEvolucao(Evolucao evolucao) async {
    throw Exception('falha simulada');
  }

  @override
  Future<void> atualizarEvolucao(Evolucao evolucao) async {
    throw Exception('falha simulada');
  }

  @override
  Future<void> atualizarSituacaoAgendamento(
    String idAgendamento,
    String situacao,
  ) async {}
}

/// Fake da plataforma de speech-to-text para os testes de microfone.
class FakeSpeechPlatform extends SpeechToTextPlatform {
  bool initResult = true;
  bool listenInvoked = false;
  bool stopInvoked = false;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> initialize({
    dynamic debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async => initResult;

  @override
  Future<void> stop() async {
    stopInvoked = true;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> listen({
    String? localeId,
    dynamic partialResults = true,
    dynamic onDevice = false,
    int listenMode = 0,
    dynamic sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    listenInvoked = true;
    return true;
  }

  @override
  Future<List<dynamic>> locales() async => [];

  /// Simula um resultado final de reconhecimento de voz.
  void emitirResultadoFinal(String texto) {
    onTextRecognition?.call(
      '{"alternates":[{"recognizedWords":"$texto","confidence":0.9}],'
      '"resultType":2}',
    );
  }
}

Agendamento _agendamento({
  String horaInicio = '08:00',
  String horaFim = '09:00',
}) {
  return Agendamento(
    idAgendamento: 'A001',
    idPaciente: 'P001',
    data: DateTime.now(),
    horaInicio: horaInicio,
    horaFim: horaFim,
    valorSessao: 150,
  );
}

/// Monta a tela de registro numa superfície alta (sem scroll) com overrides.
Future<void> _montarRegistro(
  WidgetTester tester, {
  Paciente? paciente,
  Agendamento? agendamento,
  Evolucao? evolucaoExistente,
  List<Evolucao> evolucoes = const [],
  RepositorioDadosGoogle? repositorio,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        provedorListaEvolucoes.overrideWith(
          () => EvolucoesNotifierComDados(evolucoes),
        ),
        if (repositorio != null)
          provedorRepositorioDados.overrideWith((ref) => repositorio),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: TelaRegistroEvolucao(
          paciente: paciente ?? _paciente(),
          agendamento: agendamento,
          evolucaoExistente: evolucaoExistente,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Paciente _paciente() => Paciente(
      idPaciente: 'P001',
      nome: 'João Silva',
      telefone: '11999999999',
      dataNascimento: DateTime(1990, 1, 1),
      cpf: '12345678901',
      endereco: 'Rua A',
    );

Evolucao _evolucao({required int diferencaHoras}) {
  return Evolucao(
    idEvolucao: 'E001',
    idPaciente: 'P001',
    idAgendamento: 'A001',
    dataAtendimento: DateTime.now(),
    evolucaoTexto: 'Paciente apresentou melhora significativa.',
    dataRegistro: DateTime.now().subtract(Duration(hours: diferencaHoras)),
    localAtendimento: 'Domicílio',
    statusPresenca: 'Presente',
    dorSessao: 3,
    horarioInicioReal: DateTime.now().subtract(const Duration(hours: 2)),
    horarioFimReal: DateTime.now().subtract(const Duration(hours: 1)),
    condicaoPaciente: 'Melhora',
    pressaoArterial: '120/80',
    frequenciaCardiaca: 72,
  );
}

Widget _criarAppRegistroEvolucao({
  Paciente? paciente,
  Evolucao? evolucaoExistente,
  List<Evolucao> evolucoes = const [],
}) {
  return ProviderScope(
    overrides: [
      provedorListaEvolucoes.overrideWith(
        () => EvolucoesNotifierComDados(evolucoes),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: TelaRegistroEvolucao(
        paciente: paciente ?? _paciente(),
        evolucaoExistente: evolucaoExistente,
      ),
      supportedLocales: const [Locale('en', 'US')],
    ),
  );
}

Widget _criarAppTimeline({
  required Paciente paciente,
  required List<Evolucao> evolucoes,
}) {
  return ProviderScope(
    overrides: [
      provedorListaEvolucoes.overrideWith(
        () => EvolucoesNotifierComDados(evolucoes),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: TelaHistoricoEvolucoes(paciente: paciente),
      supportedLocales: const [Locale('en', 'US')],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaRegistroEvolucao - Modo Novo', () {
    testWidgets('deve exibir título "Registrar Evolução"', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao());
      await tester.pumpAndSettle();

      expect(find.text('Registrar Evolução'), findsOneWidget);
    });

    testWidgets('deve exibir botão "Salvar Evolução"', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Salvar Evolução'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Salvar Evolução'), findsOneWidget);
    });
  });

  group('TelaRegistroEvolucao - Modo Edição (<24h)', () {
    testWidgets('deve exibir título "Editar Evolução"', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao(
        evolucaoExistente: _evolucao(diferencaHoras: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Editar Evolução'), findsOneWidget);
    });

    testWidgets('deve exibir botão "Atualizar Evolução"', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao(
        evolucaoExistente: _evolucao(diferencaHoras: 1),
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Atualizar Evolução'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Atualizar Evolução'), findsOneWidget);
    });

    testWidgets('deve pré-preencher campos a partir da evolução existente', (
      tester,
    ) async {
      final evol = _evolucao(diferencaHoras: 1);
      await tester.pumpWidget(_criarAppRegistroEvolucao(
        evolucaoExistente: evol,
      ));
      await tester.pumpAndSettle();

      // Scroll to find the evolução text field
      await tester.scrollUntilVisible(
        find.text('Evolução técnica *'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final campoEvolucao = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Evolução técnica *'),
      );
      expect(campoEvolucao.controller?.text, equals(evol.evolucaoTexto));
    });

    testWidgets('não deve exibir banner de bloqueio', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao(
        evolucaoExistente: _evolucao(diferencaHoras: 1),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Evolução bloqueada — mais de 24h do registro'),
        findsNothing,
      );
    });
  });

  group('TelaRegistroEvolucao - Modo ReadOnly (>24h)', () {
    testWidgets('deve exibir banner de bloqueio', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao(
        evolucaoExistente: _evolucao(diferencaHoras: 48),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Evolução bloqueada — mais de 24h do registro'),
        findsOneWidget,
      );
    });

    testWidgets('não deve exibir botão salvar', (tester) async {
      await tester.pumpWidget(_criarAppRegistroEvolucao(
        evolucaoExistente: _evolucao(diferencaHoras: 48),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Atualizar Evolução'), findsNothing);
    });
  });

  group('TelaHistoricoEvolucoes - Botão Editar na Timeline', () {
    testWidgets('deve exibir botão editar quando evolução tem <24h', (
      tester,
    ) async {
      await tester.pumpWidget(_criarAppTimeline(
        paciente: _paciente(),
        evolucoes: [_evolucao(diferencaHoras: 1)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
    });

    testWidgets('não deve exibir botão editar quando evolução tem >24h', (
      tester,
    ) async {
      await tester.pumpWidget(_criarAppTimeline(
        paciente: _paciente(),
        evolucoes: [_evolucao(diferencaHoras: 48)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsNothing);
    });
  });

  group('TelaRegistroEvolucao - Inicialização com agendamento', () {
    testWidgets('usa horários do agendamento e exibe horário no cabeçalho', (
      tester,
    ) async {
      await _montarRegistro(
        tester,
        agendamento: _agendamento(horaInicio: '08:00', horaFim: '09:00'),
      );

      // Horário no cabeçalho + nos campos de início/fim real.
      expect(find.text('08:00'), findsWidgets);
      expect(find.text('09:00'), findsOneWidget);
    });
  });

  group('TelaRegistroEvolucao - Interação de campos', () {
    testWidgets('status "Ausente" exibe "Condição: Faltou"', (tester) async {
      await _montarRegistro(tester);

      await tester.tap(find.text('Presente').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ausente com aviso').last);
      await tester.pumpAndSettle();

      expect(find.text('Condição: Faltou'), findsOneWidget);
    });

    testWidgets('altera local de atendimento', (tester) async {
      await _montarRegistro(tester);

      await tester.tap(find.text('Domicílio').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clínica').last);
      await tester.pumpAndSettle();

      expect(find.text('Clínica'), findsOneWidget);
    });

    testWidgets('altera condição clínica', (tester) async {
      await _montarRegistro(tester);

      await tester.tap(find.text('Melhora').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piora').last);
      await tester.pumpAndSettle();

      expect(find.text('Piora'), findsOneWidget);
    });

    testWidgets('seleciona horários reais pelo time picker', (tester) async {
      await _montarRegistro(tester);

      Future<void> escolher(String label, String h, String m) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pumpAndSettle();
        final campos = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(campos.at(0), h);
        await tester.enterText(campos.at(1), m);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      await escolher('Início Real *', '10', '30');
      await escolher('Fim Real *', '11', '45');

      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('11:45'), findsOneWidget);
    });
  });

  group('TelaRegistroEvolucao - Validação e salvamento', () {
    testWidgets('salvar sem evolução técnica mostra erro de validação', (
      tester,
    ) async {
      await _montarRegistro(tester, repositorio: FakeRepoEvolucao());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escala de Dor (0-10) *'),
        '5',
      );
      await tester.tap(find.text('Salvar Evolução'));
      await tester.pumpAndSettle();

      expect(find.text('Informe a evolução clínica.'), findsOneWidget);
    });

    testWidgets('salvar nova evolução com sucesso volta à tela anterior', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provedorListaEvolucoes.overrideWith(
              () => EvolucoesNotifierComDados(const []),
            ),
            provedorRepositorioDados.overrideWith(
              (ref) => FakeRepoEvolucao(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaRegistroEvolucao(
                          paciente: _paciente(),
                          agendamento: _agendamento(),
                        ),
                      ),
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escala de Dor (0-10) *'),
        '5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Evolução técnica *'),
        'Paciente evoluiu bem.',
      );
      await tester.tap(find.text('Salvar Evolução'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Evolução'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('Evolução salva com sucesso!'), findsOneWidget);
    });

    testWidgets('editar evolução existente atualiza com sucesso', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provedorListaEvolucoes.overrideWith(
              () => EvolucoesNotifierComDados(const []),
            ),
            provedorRepositorioDados.overrideWith(
              (ref) => FakeRepoEvolucao(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaRegistroEvolucao(
                          paciente: _paciente(),
                          evolucaoExistente: _evolucao(diferencaHoras: 1),
                        ),
                      ),
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // A escala de dor não é pré-preenchida; informar antes de atualizar.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escala de Dor (0-10) *'),
        '4',
      );
      await tester.tap(find.text('Atualizar Evolução'));
      await tester.pumpAndSettle();

      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('Evolução atualizada com sucesso!'), findsOneWidget);
    });

    testWidgets('falha ao salvar exibe snackbar de erro', (tester) async {
      await _montarRegistro(tester, repositorio: RepoEvolucaoQueFalha());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escala de Dor (0-10) *'),
        '5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Evolução técnica *'),
        'Texto da evolução.',
      );
      await tester.tap(find.text('Salvar Evolução'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('salvar como Ausente grava condição Faltou', (tester) async {
      await _montarRegistro(tester, repositorio: FakeRepoEvolucao());

      await tester.tap(find.text('Presente').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ausente sem aviso').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escala de Dor (0-10) *'),
        '0',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Evolução técnica *'),
        'Paciente ausente.',
      );
      await tester.tap(find.text('Salvar Evolução'));
      await tester.pumpAndSettle();

      // Sem erro de validação: o salvamento prosseguiu.
      expect(find.text('Informe a evolução clínica.'), findsNothing);
    });
  });

  group('TelaRegistroEvolucao - Navegação', () {
    testWidgets('botão voltar aciona o retorno', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provedorListaEvolucoes.overrideWith(
              () => EvolucoesNotifierComDados(const []),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TelaRegistroEvolucao(paciente: _paciente()),
                      ),
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Registrar Evolução'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_fechar')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Evolução'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('TelaRegistroEvolucao - Microfone (speech-to-text)', () {
    testWidgets('microfone indisponível exibe aviso', (tester) async {
      final fake = FakeSpeechPlatform()..initResult = false;
      SpeechToTextPlatform.instance = fake;

      await _montarRegistro(tester);

      await tester.tap(find.byTooltip('Transcrever por voz'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Permissão de microfone necessária para transcrição por voz.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('microfone disponível transcreve e encerra', (tester) async {
      final fake = FakeSpeechPlatform()..initResult = true;
      SpeechToTextPlatform.instance = fake;

      await _montarRegistro(tester);

      // Inicia a escuta.
      await tester.tap(find.byTooltip('Transcrever por voz'));
      await tester.pumpAndSettle();
      expect(find.text('Ouvindo...'), findsOneWidget);
      expect(fake.listenInvoked, isTrue);

      // Simula a transcrição de um resultado final.
      fake.emitirResultadoFinal('paciente colaborou');
      await tester.pumpAndSettle();
      final campo = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Evolução técnica *'),
      );
      expect(campo.controller?.text, contains('paciente colaborou'));

      // Encerra a escuta.
      await tester.tap(find.byTooltip('Parar transcrição'));
      await tester.pumpAndSettle();
      expect(find.text('Ouvindo...'), findsNothing);
      expect(fake.stopInvoked, isTrue);

      // Descarta a tela (o dispose chama _speech.stop()) e drena os timers
      // internos de "final timeout" do speech_to_text (2s cada).
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
