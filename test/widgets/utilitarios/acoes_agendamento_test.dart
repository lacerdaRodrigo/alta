import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import 'package:alta/utilitarios/acoes_agendamento.dart';

class FakeRepoAcoes extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> atualizarSituacaoAgendamento(
    String idAgendamento,
    String situacao,
  ) async {}
}

class RepoAcoesQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> atualizarSituacaoAgendamento(
    String idAgendamento,
    String situacao,
  ) async => throw Exception('falha');
}

class AgendamentosComDados extends ListaAgendamentosNotifier {
  final List<Agendamento> _dados;
  AgendamentosComDados(this._dados);
  @override
  List<Agendamento> build() => _dados;
}

Agendamento _agendamento() => Agendamento(
  idAgendamento: 'A001',
  idPaciente: 'P001',
  data: DateTime(2026, 1, 10),
  horaInicio: '09:00',
  horaFim: '10:00',
  valorSessao: 150,
);

Paciente _paciente() => Paciente(
  idPaciente: 'P001',
  nome: 'João da Silva',
  telefone: '11999998888',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '52998224725',
  endereco: 'Rua A',
);

Widget _host({
  required AcaoAgendamento acao,
  Paciente? paciente,
  RepositorioDadosGoogle? repositorio,
}) {
  final ag = _agendamento();
  return ProviderScope(
    overrides: [
      provedorListaAgendamentos.overrideWith(() => AgendamentosComDados([ag])),
      if (repositorio != null)
        provedorRepositorioDados.overrideWith((ref) => repositorio),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: ElevatedButton(
              onPressed: () => executarAcaoAgendamento(
                context,
                ref,
                acao,
                ag,
                paciente,
              ),
              child: const Text('acao'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _acionar(WidgetTester tester) async {
  await tester.tap(find.text('acao'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('executarAcaoAgendamento', () {
    testWidgets('registrarEvolucao sem paciente não navega', (tester) async {
      await tester.pumpWidget(
        _host(acao: AcaoAgendamento.registrarEvolucao, paciente: null),
      );
      await _acionar(tester);

      expect(find.text('Registrar Evolução'), findsNothing);
      expect(find.text('acao'), findsOneWidget);
    });

    testWidgets('registrarEvolucao com paciente navega para a tela', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          acao: AcaoAgendamento.registrarEvolucao,
          paciente: _paciente(),
        ),
      );
      await _acionar(tester);

      expect(find.text('Registrar Evolução'), findsOneWidget);
    });

    testWidgets('ação de falta abre diálogo de confirmação', (tester) async {
      await tester.pumpWidget(
        _host(acao: AcaoAgendamento.faltouComAviso, repositorio: FakeRepoAcoes()),
      );
      await _acionar(tester);

      expect(find.text('Atualizar sessão?'), findsOneWidget);
      expect(find.textContaining('Faltou com aviso'), findsOneWidget);
    });

    testWidgets('cancelar o diálogo não atualiza a sessão', (tester) async {
      await tester.pumpWidget(
        _host(
          acao: AcaoAgendamento.canceladoPaciente,
          repositorio: FakeRepoAcoes(),
        ),
      );
      await _acionar(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Atualizar sessão?'), findsNothing);
      expect(find.textContaining('atualizada para'), findsNothing);
    });

    testWidgets('confirmar atualiza a situação e exibe snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          acao: AcaoAgendamento.canceladoProfissional,
          repositorio: FakeRepoAcoes(),
        ),
      );
      await _acionar(tester);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Cancelado pelo profissional'),
        findsOneWidget,
      );
    });

    testWidgets('falha ao atualizar exibe snackbar de erro', (tester) async {
      await tester.pumpWidget(
        _host(
          acao: AcaoAgendamento.faltouSemAviso,
          repositorio: RepoAcoesQueFalha(),
        ),
      );
      await _acionar(tester);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });
  });
}
