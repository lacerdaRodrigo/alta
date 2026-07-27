import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import 'package:alta/telas/tela_editar_sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRepoEdicaoSessao extends Fake implements RepositorioDadosGoogle {
  Agendamento? capturado;

  @override
  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    capturado = agendamento;
  }
}

class RepoEdicaoSessaoQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> atualizarAgendamento(Agendamento agendamento) async =>
      throw Exception('falha simulada ao atualizar');
}

class AgendamentosComDados extends ListaAgendamentosNotifier {
  final List<Agendamento> _dados;
  AgendamentosComDados(this._dados);
  @override
  List<Agendamento> build() => _dados;
}

class PacientesComDados extends ListaPacientesNotifier {
  final List<Paciente> _dados;
  PacientesComDados(this._dados);
  @override
  List<Paciente> build() => _dados;
}

Agendamento _agendamento() {
  final amanha = DateTime.now().add(const Duration(days: 1));
  return Agendamento(
    idAgendamento: 'A010',
    idPaciente: 'P001',
    data: DateTime(amanha.year, amanha.month, amanha.day),
    horaInicio: '14:00',
    horaFim: '15:00',
    valorSessao: 200.0,
    observacoes: 'Levar TENS',
    situacao: Agendamento.situacaoAgendado,
    dataCriacao: DateTime(2026, 1, 1),
  );
}

Future<void> _montarTela(
  WidgetTester tester,
  Agendamento agendamento, {
  RepositorioDadosGoogle? repositorio,
  String nomePaciente = 'Maria Teste',
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        provedorListaAgendamentos.overrideWith(
          () => AgendamentosComDados([agendamento]),
        ),
        provedorListaPacientes.overrideWith(() => PacientesComDados([])),
        if (repositorio != null)
          provedorRepositorioDados.overrideWith((ref) => repositorio),
      ],
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
        home: TelaEditarSessao(
          agendamento: agendamento,
          nomePaciente: nomePaciente,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _campoHabilitado(WidgetTester tester, String chave) {
  final campo = tester.widget<TextField>(
    find.descendant(
      of: find.byKey(Key(chave)),
      matching: find.byType(TextField),
    ),
  );
  return campo.enabled ?? true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaEditarSessao', () {
    testWidgets('pré-preenche campos editáveis com o agendamento', (
      tester,
    ) async {
      await _montarTela(tester, _agendamento());

      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('200,00'), findsOneWidget);
      expect(find.text('Levar TENS'), findsOneWidget);
      // Nome do paciente aparece no campo travado e no subtítulo.
      expect(find.text('Maria Teste'), findsWidgets);
    });

    testWidgets('paciente aparece desabilitado', (tester) async {
      await _montarTela(tester, _agendamento());

      expect(_campoHabilitado(tester, 'campo_paciente'), isFalse);
    });

    testWidgets('salvar atualiza campos e preserva identidade', (
      tester,
    ) async {
      final repo = FakeRepoEdicaoSessao();
      await _montarTela(tester, _agendamento(), repositorio: repo);

      await tester.enterText(
        find.byKey(const Key('campo_valor')),
        '250,00',
      );
      await tester.enterText(
        find.byKey(const Key('campo_observacoes')),
        'Nova obs',
      );

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      final salvo = repo.capturado;
      expect(salvo, isNotNull);
      expect(salvo!.idAgendamento, 'A010');
      expect(salvo.idPaciente, 'P001');
      expect(salvo.situacao, Agendamento.situacaoAgendado);
      expect(salvo.dataCriacao, DateTime(2026, 1, 1));
      expect(salvo.valorSessao, 250.0);
      expect(salvo.observacoes, 'Nova obs');
    });

    testWidgets('valor vazio impede salvar', (tester) async {
      await _montarTela(
        tester,
        _agendamento(),
        repositorio: FakeRepoEdicaoSessao(),
      );

      await tester.enterText(find.byKey(const Key('campo_valor')), '');

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      expect(find.text('Campos obrigatórios'), findsOneWidget);
      expect(find.text('Valor da Sessão'), findsOneWidget);
    });

    testWidgets('falha ao atualizar exibe snackbar de erro', (tester) async {
      await _montarTela(
        tester,
        _agendamento(),
        repositorio: RepoEdicaoSessaoQueFalha(),
      );

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('botão voltar aciona o retorno', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final agendamento = _agendamento();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provedorListaAgendamentos.overrideWith(
              () => AgendamentosComDados([agendamento]),
            ),
            provedorListaPacientes.overrideWith(() => PacientesComDados([])),
          ],
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
                    MaterialPageRoute(
                      builder: (_) => TelaEditarSessao(
                        agendamento: agendamento,
                        nomePaciente: 'Maria Teste',
                      ),
                    ),
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
      expect(find.text('Editar Sessão'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_fechar')));
      await tester.pumpAndSettle();

      expect(find.text('Editar Sessão'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('observação vazia vira null no agendamento salvo', (
      tester,
    ) async {
      final repo = FakeRepoEdicaoSessao();
      await _montarTela(tester, _agendamento(), repositorio: repo);

      await tester.enterText(find.byKey(const Key('campo_observacoes')), '');

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      expect(repo.capturado, isNotNull);
      expect(repo.capturado!.observacoes, isNull);
    });
  });
}
