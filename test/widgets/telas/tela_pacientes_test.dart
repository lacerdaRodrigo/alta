import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisio_home_care/modelos/paciente.dart';
import 'package:fisio_home_care/modelos/evolucao.dart';
import 'package:fisio_home_care/provedores/provedores_dados.dart';
import 'package:fisio_home_care/telas/tela_pacientes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

Paciente _pacienteAtivo(String id, String nome) => Paciente(
      idPaciente: id,
      nome: nome,
      telefone: '11999999999',
      dataNascimento: DateTime(1990, 1, 1),
      cpf: '$id$id${id}1'.padRight(11, '0').substring(0, 11),
      endereco: 'Rua A',
      situacao: 'Ativo',
    );

Paciente _pacienteArquivado(String id, String nome) => Paciente(
      idPaciente: id,
      nome: nome,
      telefone: '11999999999',
      dataNascimento: DateTime(1990, 1, 1),
      cpf: '$id$id${id}2'.padRight(11, '0').substring(0, 11),
      endereco: 'Rua B',
      situacao: 'Arquivado',
    );

Widget _criarApp(
  List<Paciente> pacientes, {
  void Function(Paciente)? onAbrir,
  List<Evolucao> evolucoes = const [],
}) {
  return ProviderScope(
    overrides: [
      provedorListaPacientes.overrideWith(
        () => PacientesNotifierComDados(pacientes),
      ),
      provedorListaEvolucoes.overrideWith(
        () => EvolucoesNotifierComDados(evolucoes),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: TelaPacientes(onAbrir: onAbrir),
      supportedLocales: const [Locale('en', 'US')],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaPacientes - Filtro', () {
    testWidgets('deve exibir apenas pacientes ativos por padrão', (
      tester,
    ) async {
      await tester.pumpWidget(_criarApp([
        _pacienteAtivo('P001', 'João Ativo'),
        _pacienteArquivado('P002', 'Maria Arquivada'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('João Ativo'), findsOneWidget);
      expect(find.text('Maria Arquivada'), findsNothing);
    });

    testWidgets('deve exibir apenas arquivados ao selecionar o filtro', (
      tester,
    ) async {
      await tester.pumpWidget(_criarApp([
        _pacienteAtivo('P001', 'João Ativo'),
        _pacienteArquivado('P002', 'Maria Arquivada'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Arquivados'));
      await tester.pumpAndSettle();

      expect(find.text('João Ativo'), findsNothing);
      expect(find.text('Maria Arquivada'), findsOneWidget);
    });

    testWidgets('deve voltar a exibir apenas ativos ao reselecionar o filtro', (
      tester,
    ) async {
      await tester.pumpWidget(_criarApp([
        _pacienteAtivo('P001', 'João Ativo'),
        _pacienteArquivado('P002', 'Maria Arquivada'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Arquivados'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ativos'));
      await tester.pumpAndSettle();

      expect(find.text('João Ativo'), findsOneWidget);
      expect(find.text('Maria Arquivada'), findsNothing);
    });

    testWidgets('filtro "Todos" exibe ativos e arquivados', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _pacienteAtivo('P001', 'João Ativo'),
          _pacienteArquivado('P002', 'Maria Arquivada'),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();

      expect(find.text('João Ativo'), findsOneWidget);
      expect(find.text('Maria Arquivada'), findsOneWidget);
    });
  });

  group('TelaPacientes - Cabeçalho', () {
    testWidgets('exibe o total de pacientes cadastrados', (tester) async {
      await tester.pumpWidget(_criarApp([
        _pacienteAtivo('P001', 'João Ativo'),
        _pacienteAtivo('P002', 'Pedro Ativo'),
        _pacienteArquivado('P003', 'Maria Arquivada'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('no total'), findsOneWidget);
    });

    testWidgets('paciente arquivado exibe o rótulo "Arquivado"', (
      tester,
    ) async {
      await tester.pumpWidget(_criarApp([
        _pacienteArquivado('P001', 'Maria Arquivada'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Arquivados'));
      await tester.pumpAndSettle();

      expect(find.text('Arquivado'), findsOneWidget);
    });
  });

  group('TelaPacientes - Busca', () {
    testWidgets('busca filtra por nome', (tester) async {
      await tester.pumpWidget(
        _criarApp([
          _pacienteAtivo('P001', 'João Ativo'),
          _pacienteAtivo('P002', 'Pedro Ativo'),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'João');
      await tester.pumpAndSettle();

      expect(find.text('João Ativo'), findsOneWidget);
      expect(find.text('Pedro Ativo'), findsNothing);
    });

    testWidgets('busca por CPF filtra a lista', (tester) async {
      final joao = Paciente(
        idPaciente: 'P001',
        nome: 'João Ativo',
        telefone: '11999999999',
        dataNascimento: DateTime(1990, 1, 1),
        cpf: '52998224725',
        endereco: 'Rua A',
        situacao: 'Ativo',
      );
      await tester.pumpWidget(
        _criarApp([joao, _pacienteAtivo('P002', 'Pedro Ativo')]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '5299822');
      await tester.pumpAndSettle();

      expect(find.text('João Ativo'), findsOneWidget);
      expect(find.text('Pedro Ativo'), findsNothing);
    });

    testWidgets('lista vazia exibe estado vazio', (tester) async {
      await tester.pumpWidget(_criarApp(const []));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum paciente encontrado'), findsOneWidget);
      expect(find.byIcon(Icons.person_search_rounded), findsOneWidget);
    });

    testWidgets('busca sem resultado exibe estado vazio', (tester) async {
      await tester.pumpWidget(
        _criarApp([_pacienteAtivo('P001', 'João Ativo')]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum paciente encontrado'), findsOneWidget);
    });
  });

  group('TelaPacientes - Interação', () {
    testWidgets('tocar no card aciona onAbrir com o paciente selecionado', (
      tester,
    ) async {
      Paciente? aberto;
      final joao = _pacienteAtivo('P001', 'João Ativo');
      await tester.pumpWidget(
        _criarApp([joao], onAbrir: (p) => aberto = p),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('João Ativo'));
      await tester.pumpAndSettle();

      expect(aberto, joao);
    });

    testWidgets('botão Evoluções abre o histórico geral de evoluções', (
      tester,
    ) async {
      await tester.pumpWidget(
        _criarApp([_pacienteAtivo('P001', 'João Ativo')]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evoluções'), findsOneWidget);
      await tester.tap(find.text('Evoluções'));
      await tester.pumpAndSettle();

      // Tela de histórico geral aberta (sem evoluções → estado vazio)
      expect(find.text('Nenhuma evolução registrada ainda.'), findsOneWidget);
    });
  });
}
