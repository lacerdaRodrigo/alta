import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/telas/tela_sessoes.dart';
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

class AgendamentosNotifierComDados extends ListaAgendamentosNotifier {
  final List<Agendamento> _dados;

  AgendamentosNotifierComDados(this._dados);

  @override
  List<Agendamento> build() => _dados;
}

Paciente _paciente() => Paciente(
  idPaciente: 'P001',
  nome: 'João Sessões',
  telefone: '11999999999',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '12345678901',
  endereco: 'Rua A',
  situacao: 'Ativo',
);

Agendamento _agendamento(String id, String situacao, DateTime data) {
  return Agendamento(
    idAgendamento: id,
    idPaciente: 'P001',
    data: data,
    horaInicio: '08:00',
    horaFim: '09:00',
    valorSessao: 150,
    situacao: situacao,
  );
}

Paciente _pacienteCom(String id, String nome) => Paciente(
  idPaciente: id,
  nome: nome,
  telefone: '11999999999',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '12345678901',
  endereco: 'Rua A',
  situacao: 'Ativo',
);

Agendamento _agendamentoPara(
  String id,
  String idPaciente,
  String situacao,
  DateTime data, {
  String horaInicio = '08:00',
}) {
  return Agendamento(
    idAgendamento: id,
    idPaciente: idPaciente,
    data: data,
    horaInicio: horaInicio,
    horaFim: '09:00',
    valorSessao: 150,
    situacao: situacao,
  );
}

Widget _criarApp(List<Agendamento> agendamentos) {
  return _criarAppCom([_paciente()], agendamentos);
}

Widget _criarAppCom(
  List<Paciente> pacientes,
  List<Agendamento> agendamentos,
) {
  return ProviderScope(
    overrides: [
      provedorListaPacientes.overrideWith(
        () => PacientesNotifierComDados(pacientes),
      ),
      provedorListaAgendamentos.overrideWith(
        () => AgendamentosNotifierComDados(agendamentos),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      home: TelaSessoes(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaSessoes', () {
    testWidgets('deve listar sessões realizadas pelo filtro Realizadas', (
      tester,
    ) async {
      final hoje = DateTime.now();
      await tester.pumpWidget(
        _criarApp([
          _agendamento('A001', Agendamento.situacaoRealizado, hoje),
          _agendamento('A002', Agendamento.situacaoAgendado, hoje),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Realizadas'));
      await tester.pumpAndSettle();

      expect(find.text('Realizado'), findsOneWidget);
    });

    testWidgets('deve listar sessões vencidas pelo filtro Vencidas', (tester) async {
      // Past date that is always in the current month (midnight of today = before now)
      final hoje = DateTime.now();
      final passadoMesAtual = DateTime(hoje.year, hoje.month, hoje.day);
      await tester.pumpWidget(
        _criarApp([
          _agendamento('A001', Agendamento.situacaoAgendado, passadoMesAtual),
          _agendamento('A002', Agendamento.situacaoRealizado, passadoMesAtual),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vencidas'));
      await tester.pumpAndSettle();

      expect(find.text('Vencida'), findsOneWidget);
    });

    testWidgets('deve buscar sessões por nome do paciente', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _agendamento(
            'A001',
            Agendamento.situacaoRealizado,
            DateTime.now(),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'João Sessões');
      await tester.pumpAndSettle();

      expect(find.text('João Sessões'), findsWidgets);
    });
  });

  group('TelaSessoes — busca e estado vazio', () {
    testWidgets('busca por texto que não existe oculta resultados', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _agendamento('A001', Agendamento.situacaoAgendado, DateTime.now()),
        ]),
      );
      await tester.pumpAndSettle();

      // Search term that matches nobody
      await tester.enterText(find.byType(TextField), 'XYZ_nao_existe');
      await tester.pumpAndSettle();

      // No session should appear
      expect(find.text('João Sessões'), findsNothing);
      expect(find.text('Nenhuma sessão'), findsOneWidget);
    });

    testWidgets('estado vazio exibe mensagem quando não há sessões', (tester) async {
      await tester.pumpWidget(_criarApp(const []));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma sessão'), findsOneWidget);
      expect(
        find.text('Ajuste o filtro ou o mês selecionado.'),
        findsOneWidget,
      );
    });

    testWidgets('cada filtro ativo exibe mensagem de estado vazio', (
      tester,
    ) async {
      await tester.pumpWidget(_criarApp(const []));
      await tester.pumpAndSettle();

      for (final filtro in ['Hoje', 'Futuras', 'Vencidas', 'Realizadas']) {
        await tester.ensureVisible(find.text(filtro));
        await tester.tap(find.text(filtro));
        await tester.pumpAndSettle();
        expect(find.text('Nenhuma sessão'), findsOneWidget);
      }
    });
  });

  group('TelaSessoes — filtros por período e status', () {
    Future<void> montar(WidgetTester tester) async {
      final hoje = DateTime.now();
      // Sessão de hoje que JÁ venceu. O horário precisa ser derivado de `hoje`,
      // não fixo: o filtro "Hoje" compara `inicioPrevisto` com o relógio, então
      // uma hora fixa (o padrão '08:00' de `_agendamentoPara`) fazia o teste
      // passar só quando a suíte rodava depois dessa hora — o CI em UTC de
      // madrugada via a sessão como ainda não vencida e o teste falhava.
      // O clamp evita cair no dia anterior quando são 00:00.
      final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
      final umMinutoAtras = hoje.subtract(const Duration(minutes: 1));
      final vencida =
          umMinutoAtras.isBefore(inicioDoDia) ? inicioDoDia : umMinutoAtras;
      final ontem = DateTime(vencida.year, vencida.month, vencida.day);
      final horaVencida =
          '${vencida.hour.toString().padLeft(2, '0')}:'
          '${vencida.minute.toString().padLeft(2, '0')}';
      // Future date always in current month: tonight at 23:59
      final amanha = DateTime(hoje.year, hoje.month, hoje.day, 23, 59);

      await tester.pumpWidget(
        _criarAppCom(
          [
            _pacienteCom('P001', 'João Hoje'),
            _pacienteCom('P002', 'Maria Futura'),
            _pacienteCom('P003', 'Pedro Pendente'),
            _pacienteCom('P004', 'Ana Realizada'),
          ],
          [
            _agendamentoPara(
              'A001',
              'P001',
              Agendamento.situacaoAgendado,
              hoje,
              horaInicio: '23:59',
            ),
            _agendamentoPara(
              'A002',
              'P002',
              Agendamento.situacaoAgendado,
              amanha,
            ),
            _agendamentoPara(
              'A003',
              'P003',
              Agendamento.situacaoAgendado,
              ontem,
              horaInicio: horaVencida,
            ),
            _agendamentoPara(
              'A004',
              'P004',
              Agendamento.situacaoRealizado,
              hoje,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('filtro Futuras mostra apenas sessões futuras', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Futuras'));
      await tester.pumpAndSettle();

      // Pedro (yesterday = pendente) and Ana (today = realizado) should be hidden
      expect(find.text('Pedro Pendente'), findsNothing);
      expect(find.text('Ana Realizada'), findsNothing);
    });

    testWidgets('filtro Vencidas mostra sessões atrasadas/anteriores', (
      tester,
    ) async {
      await montar(tester);

      await tester.tap(find.text('Vencidas'));
      await tester.pumpAndSettle();

      expect(find.text('Pedro Pendente'), findsOneWidget);
      expect(find.text('Ana Realizada'), findsNothing);
    });

    testWidgets('filtro Realizadas mostra apenas sessões realizadas', (
      tester,
    ) async {
      await montar(tester);

      await tester.ensureVisible(find.text('Realizadas'));
      await tester.tap(find.text('Realizadas'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Realizada'), findsOneWidget);
      expect(find.text('Pedro Pendente'), findsNothing);
    });

    testWidgets('filtro Hoje mostra sessões do dia', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();

      expect(find.text('João Hoje'), findsOneWidget);
      expect(find.text('Pedro Pendente'), findsNothing);
    });
  });
}
