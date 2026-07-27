import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/telas/tela_financeiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Paciente _paciente({String id = 'P001', String nome = 'João Teste'}) {
  return Paciente(
    idPaciente: id,
    nome: nome,
    telefone: '11999999999',
    dataNascimento: DateTime(1990, 1, 1),
    cpf: '12345678901',
    endereco: 'Rua A',
    situacao: 'Ativo',
  );
}

Agendamento _sessao({
  String id = 'A001',
  String idPaciente = 'P001',
  required DateTime data,
  double valor = 150.0,
  String situacao = 'Agendado',
}) {
  return Agendamento(
    idAgendamento: id,
    idPaciente: idPaciente,
    data: data,
    horaInicio: '14:00',
    horaFim: '15:00',
    valorSessao: valor,
    situacao: situacao,
  );
}

Future<void> _montarTela(
  WidgetTester tester, {
  List<Agendamento> agendamentos = const [],
  List<Paciente> pacientes = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        provedorListaAgendamentos.overrideWith(
          () => AgendamentosComDados(agendamentos),
        ),
        provedorListaPacientes.overrideWith(
          () => PacientesComDados(pacientes),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('pt', 'BR')],
        home: Scaffold(body: TelaFinanceiro()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final agora = DateTime.now();
  final mesAtual = DateTime(agora.year, agora.month, 15);
  final mesAnterior = DateTime(agora.year, agora.month - 1, 15);

  group('TelaFinanceiro', () {
    testWidgets('exibe cards com totais corretos', (tester) async {
      await _montarTela(
        tester,
        pacientes: [_paciente()],
        agendamentos: [
          _sessao(id: 'A001', data: mesAtual, valor: 200.0, situacao: 'Realizado'),
          _sessao(id: 'A002', data: mesAtual, valor: 150.0, situacao: 'Realizado'),
          _sessao(id: 'A003', data: mesAtual, valor: 100.0, situacao: 'Agendado'),
        ],
      );

      expect(find.text('Faturado no mês'), findsOneWidget);
      expect(find.text('Previsto'), findsOneWidget);
      expect(find.text('Realizadas'), findsOneWidget);
      // Faturado = 350 — hero exibe número e "R$ " como widgets separados
      expect(find.text('350,00'), findsOneWidget);
      // Previsto = 100, aparece no tile + no card da sessão agendada
      expect(find.text('R\$ 100,00'), findsWidgets);
      expect(find.text('2'), findsOneWidget); // realizadas
    });

    testWidgets('filtra por mês ao trocar chip', (tester) async {
      await _montarTela(
        tester,
        pacientes: [_paciente()],
        agendamentos: [
          _sessao(id: 'A001', data: mesAtual, valor: 200.0, situacao: 'Realizado'),
          _sessao(id: 'A002', data: mesAnterior, valor: 300.0, situacao: 'Realizado'),
        ],
      );

      // Mês atual: faturado R$ 200 aparece no card da sessão
      expect(find.text('R\$ 200,00'), findsWidgets);

      // Trocar para o mês anterior via chevron esquerdo
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      // Agora R$ 300 aparece no card da sessão (mês anterior)
      expect(find.text('R\$ 300,00'), findsWidgets);
    });

    testWidgets('estado vazio quando não há sessões no mês', (tester) async {
      await _montarTela(tester, pacientes: [], agendamentos: []);

      expect(find.text('Nenhuma sessão neste mês.'), findsOneWidget);
    });

    testWidgets('lista sessões com nome do paciente e badge', (tester) async {
      await _montarTela(
        tester,
        pacientes: [_paciente(id: 'P001', nome: 'Maria Silva')],
        agendamentos: [
          _sessao(id: 'A001', data: mesAtual, valor: 180.0, situacao: 'Realizado'),
        ],
      );

      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('Realizado'), findsWidgets);
      expect(find.text('R\$ 180,00'), findsWidgets);
    });

    testWidgets('ignora cancelamentos e faltas nos totais', (tester) async {
      await _montarTela(
        tester,
        pacientes: [_paciente()],
        agendamentos: [
          _sessao(id: 'A001', data: mesAtual, valor: 200.0, situacao: 'Realizado'),
          _sessao(id: 'A002', data: mesAtual, valor: 150.0, situacao: 'Cancelado pelo paciente'),
          _sessao(id: 'A003', data: mesAtual, valor: 100.0, situacao: 'Faltou sem aviso'),
        ],
      );

      // Faturado = só o realizado (200) — aparece no card resumo + card sessão
      expect(find.text('R\$ 200,00'), findsWidgets);
      // Previsto = R$ 0,00 (nenhum agendado)
      expect(find.text('R\$ 0,00'), findsOneWidget);
      // Realizadas = 1
      expect(find.text('1'), findsOneWidget);
      // Canceladas e faltas NÃO aparecem na lista
      expect(find.text('R\$ 150,00'), findsNothing);
      expect(find.text('R\$ 100,00'), findsNothing);
    });

    testWidgets('exibe contagem de sessões realizadas', (tester) async {
      await _montarTela(
        tester,
        pacientes: [_paciente()],
        agendamentos: [
          _sessao(id: 'A001', data: mesAtual, valor: 100.0, situacao: 'Realizado'),
          _sessao(id: 'A002', data: mesAtual, valor: 100.0, situacao: 'Realizado'),
          _sessao(id: 'A003', data: mesAtual, valor: 100.0, situacao: 'Realizado'),
        ],
      );

      expect(find.text('3'), findsOneWidget); // 3 realizadas
      expect(find.text('300,00'), findsOneWidget); // faturado no hero (sem prefixo R$)
      expect(find.text('Realizadas'), findsOneWidget); // label do card
    });

    testWidgets('visualização por paciente agrupa sessões', (tester) async {
      await _montarTela(
        tester,
        pacientes: [
          _paciente(id: 'P001', nome: 'Ana Costa'),
          _paciente(id: 'P002', nome: 'Bruno Lima'),
        ],
        agendamentos: [
          _sessao(id: 'A001', idPaciente: 'P001', data: mesAtual, valor: 200.0, situacao: 'Realizado'),
          _sessao(id: 'A002', idPaciente: 'P001', data: mesAtual, valor: 150.0, situacao: 'Realizado'),
          _sessao(id: 'A003', idPaciente: 'P002', data: mesAtual, valor: 100.0, situacao: 'Agendado'),
        ],
      );

      // Trocar para "Por paciente"
      await tester.tap(find.text('Por paciente'));
      await tester.pumpAndSettle();

      // Grupos com nomes dos pacientes
      expect(find.text('Ana Costa'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
      // Subtítulos dos grupos com resumo
      expect(find.textContaining('2 realizadas'), findsOneWidget);
      expect(find.textContaining('1 agendadas'), findsOneWidget);
    });

    testWidgets('seletor de visualização alterna entre lista e por paciente', (tester) async {
      await _montarTela(
        tester,
        pacientes: [_paciente(id: 'P001', nome: 'Carlos Souza')],
        agendamentos: [
          _sessao(id: 'A001', data: mesAtual, valor: 100.0, situacao: 'Realizado'),
        ],
      );

      // Começa em Lista
      expect(find.text('Lista'), findsOneWidget);
      expect(find.text('Por paciente'), findsOneWidget);

      // Trocar para "Por paciente"
      await tester.tap(find.text('Por paciente'));
      await tester.pumpAndSettle();

      // Aparece o grupo com nome do paciente
      expect(find.text('Carlos Souza'), findsOneWidget);

      // Voltar para "Lista"
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();

      // Nome aparece no card da lista
      expect(find.text('Carlos Souza'), findsOneWidget);
    });
  });
}
