import 'package:alta/modelos/evolucao.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/telas/tela_historico_geral_evolucoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class PacientesNotifierComDados extends ListaPacientesNotifier {
  final List<Paciente> _dados;

  PacientesNotifierComDados(this._dados);

  @override
  List<Paciente> build() => _dados;
}

class EvolucoesNotifierComDados extends ListaEvolucoesNotifier {
  final List<Evolucao> _dados;

  EvolucoesNotifierComDados(this._dados);

  @override
  List<Evolucao> build() => _dados;
}

Paciente _paciente() => Paciente(
  idPaciente: 'P001',
  nome: 'Maria Evolução',
  telefone: '11999999999',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '12345678901',
  endereco: 'Rua A',
  situacao: 'Ativo',
);

Paciente _pacienteCom(String id, String nome) => Paciente(
  idPaciente: id,
  nome: nome,
  telefone: '11999999999',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '12345678901',
  endereco: 'Rua A',
  situacao: 'Ativo',
);

Evolucao _evolucao(
  String id,
  String texto,
  String condicao, {
  String idPaciente = 'P001',
  DateTime? dataRegistro,
}) {
  return Evolucao(
    idEvolucao: id,
    idPaciente: idPaciente,
    idAgendamento: 'A$id',
    dataAtendimento: DateTime(2026, 6, 10),
    evolucaoTexto: texto,
    dataRegistro: dataRegistro,
    horarioInicioReal: DateTime(2026, 6, 10, 8),
    horarioFimReal: DateTime(2026, 6, 10, 9),
    condicaoPaciente: condicao,
    dorSessao: 4,
  );
}

Widget _criarApp(List<Evolucao> evolucoes) {
  return _criarAppCom([_paciente()], evolucoes);
}

Widget _criarAppCom(List<Paciente> pacientes, List<Evolucao> evolucoes) {
  return ProviderScope(
    overrides: [
      provedorListaPacientes.overrideWith(
        () => PacientesNotifierComDados(pacientes),
      ),
      provedorListaEvolucoes.overrideWith(
        () => EvolucoesNotifierComDados(evolucoes),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      home: TelaHistoricoGeralEvolucoes(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaHistoricoGeralEvolucoes', () {
    testWidgets('deve buscar evolução por texto clínico', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _evolucao('001', 'Treino de marcha com apoio', 'Melhora'),
          _evolucao('002', 'Alongamento global', 'Estável'),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'marcha');
      await tester.pumpAndSettle();

      expect(find.text('Treino de marcha com apoio'), findsOneWidget);
      expect(find.text('Alongamento global'), findsNothing);
    });

    testWidgets('deve agrupar evoluções por paciente', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _evolucao('001', 'Treino de marcha com apoio', 'Melhora'),
          _evolucao('002', 'Alongamento global', 'Estável'),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Por paciente'));
      await tester.pumpAndSettle();

      expect(find.text('Maria Evolução'), findsOneWidget);
      expect(find.textContaining('2 evoluções'), findsOneWidget);
    });

    testWidgets('estado vazio quando não há evoluções', (tester) async {
      await tester.pumpWidget(_criarApp(const []));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma evolução registrada ainda.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history_edu_rounded), findsOneWidget);
    });

    testWidgets('botão limpar restaura a lista completa', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _evolucao('001', 'Treino de marcha', 'Melhora'),
          _evolucao('002', 'Alongamento global', 'Estável'),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'marcha');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
      expect(find.text('Alongamento global'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear_rounded), findsNothing);
      expect(find.text('Treino de marcha'), findsOneWidget);
      expect(find.text('Alongamento global'), findsOneWidget);
    });

    testWidgets('cores de condição (Piora e Faltou) são exibidas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _criarApp([
          _evolucao('001', 'Quadro piorou', 'Piora'),
          _evolucao('002', 'Paciente ausente', 'Faltou'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Piora'), findsOneWidget);
      expect(find.text('Faltou'), findsOneWidget);
    });

    testWidgets('visão por paciente ordena vários pacientes', (tester) async {
      await tester.pumpWidget(
        _criarAppCom(
          [_pacienteCom('P002', 'Bruno'), _pacienteCom('P001', 'Alice')],
          [
            _evolucao('001', 'Evolução A', 'Melhora', idPaciente: 'P001'),
            _evolucao('002', 'Evolução B', 'Estável', idPaciente: 'P002'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Por paciente'));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
    });

    testWidgets('tocar no card abre o modal de detalhes', (tester) async {
      // Regressão: o card era um FisioCard sem onTap, então o registro não
      // tinha porta de entrada nenhuma — o texto cortado em 3 linhas ficava
      // inacessível.
      await tester.pumpWidget(
        _criarApp([_evolucao('001', 'Treino de marcha com apoio', 'Melhora')]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsNothing);

      await tester.tap(find.text('Treino de marcha com apoio'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Status: Presente'), findsOneWidget);
    });

    testWidgets('tocar no card dentro da visão por paciente abre o modal', (
      tester,
    ) async {
      await tester.pumpWidget(
        _criarApp([_evolucao('001', 'Treino de marcha com apoio', 'Melhora')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Por paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maria Evolução'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Treino de marcha com apoio'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('modal abre para evolução com mais de 24h', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _evolucao(
            '001',
            'Registro antigo do paciente',
            'Melhora',
            dataRegistro: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registro antigo do paciente'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Registro fechado — mais de 24h'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('botão voltar aciona o retorno', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            provedorListaPacientes.overrideWith(
              () => PacientesNotifierComDados([_paciente()]),
            ),
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
            supportedLocales: const [Locale('pt', 'BR')],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TelaHistoricoGeralEvolucoes(),
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
      expect(find.text('Evoluções'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Evoluções'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });
  });
}
