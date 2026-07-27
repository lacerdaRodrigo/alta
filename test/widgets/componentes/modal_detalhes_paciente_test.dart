import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alta/componentes/modal_detalhes_paciente.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/modelos/evolucao.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';

class FakeRepoModal extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> arquivarPaciente(String idPaciente) async {}
  @override
  Future<void> restaurarPaciente(String idPaciente) async {}
}

class RepoModalQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> arquivarPaciente(String idPaciente) async =>
      throw Exception('falha');
  @override
  Future<void> restaurarPaciente(String idPaciente) async =>
      throw Exception('falha');
}

class EvolucoesComDados extends ListaEvolucoesNotifier {
  final List<Evolucao> _dados;
  EvolucoesComDados(this._dados);
  @override
  List<Evolucao> build() => _dados;
}

Paciente _pacienteCompleto({String situacao = 'Ativo'}) => Paciente(
  idPaciente: 'P001',
  nome: 'João da Silva',
  telefone: '11999998888',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '52998224725',
  endereco: 'Rua das Flores, 100',
  queixaPrincipal: 'Dor lombar',
  histDoencaAtual: 'Início há 2 semanas',
  genero: 'Masculino',
  dor: '7',
  comorbidades: 'Hipertensão',
  medicamentos: 'Losartana',
  alergias: 'Dipirona',
  cirurgias: 'Apendicectomia',
  habitosVida: 'Sedentário',
  situacao: situacao,
);

Widget _host(
  Paciente paciente, {
  List<Evolucao> evolucoes = const [],
  RepositorioDadosGoogle? repositorio,
}) {
  return ProviderScope(
    overrides: [
      provedorListaEvolucoes.overrideWith(() => EvolucoesComDados(evolucoes)),
      if (repositorio != null)
        provedorRepositorioDados.overrideWith((ref) => repositorio),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => mostrarModalDetalhesPaciente(context, paciente),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _abrirModal(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mostrarModalDetalhesPaciente', () {
    testWidgets('exibe nome, telefone, endereço e seções clínicas', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(_pacienteCompleto()));
      await _abrirModal(tester);

      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('Telefone'), findsOneWidget);
      expect(find.text('Endereço'), findsOneWidget);
      expect(find.text('Queixa principal'), findsOneWidget);
      expect(find.text('Comorbidades'), findsOneWidget);
      expect(find.text('Medicamentos em Uso'), findsOneWidget);
      expect(find.text('Alergias'), findsOneWidget);
    });

    testWidgets('mostra ação Editar Paciente', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(_pacienteCompleto()));
      await _abrirModal(tester);

      expect(find.text('Editar Paciente'), findsOneWidget);
    });

    testWidgets('paciente ativo mostra ação Arquivar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(_pacienteCompleto()));
      await _abrirModal(tester);

      expect(find.text('Arquivar Paciente'), findsOneWidget);
      expect(find.text('Restaurar Paciente'), findsNothing);
    });

    testWidgets('paciente arquivado mostra ação Restaurar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(_pacienteCompleto(situacao: 'Arquivado')),
      );
      await _abrirModal(tester);

      expect(find.text('Restaurar Paciente'), findsOneWidget);
      expect(find.text('Arquivar Paciente'), findsNothing);
    });

    testWidgets('última evolução é exibida para paciente ativo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final evolucao = Evolucao(
        idEvolucao: 'E001',
        idPaciente: 'P001',
        idAgendamento: 'A001',
        dataAtendimento: DateTime(2026, 1, 10),
        evolucaoTexto: 'Sessão realizada',
        condicaoPaciente: 'Melhora',
        dorSessao: 3,
        horarioInicioReal: DateTime(2026, 1, 10, 9),
        horarioFimReal: DateTime(2026, 1, 10, 10),
      );

      await tester.pumpWidget(
        _host(_pacienteCompleto(), evolucoes: [evolucao]),
      );
      await _abrirModal(tester);

      expect(find.text('Última evolução'), findsOneWidget);
      expect(find.textContaining('Condição: Melhora'), findsOneWidget);
    });

    testWidgets('abrir opções de rota mostra Google Maps e Waze', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(_pacienteCompleto()));
      await _abrirModal(tester);

      await tester.ensureVisible(find.byTooltip('Como chegar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Como chegar'));
      await tester.pumpAndSettle();

      expect(find.text('Como chegar'), findsOneWidget);
      expect(find.text('Abrir no Google Maps'), findsOneWidget);
      expect(find.text('Abrir no Waze'), findsOneWidget);
    });

    testWidgets('abrir rota com falha exibe snackbar', (tester) async {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            (call) async => false,
          );
      addTearDown(() {
        TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/url_launcher'),
              null,
            );
      });

      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(_pacienteCompleto()));
      await _abrirModal(tester);

      await tester.ensureVisible(find.byTooltip('Como chegar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Como chegar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir no Google Maps'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível abrir o aplicativo de rotas.'),
        findsOneWidget,
      );
    });

    testWidgets('cancelar o diálogo de arquivar mantém o modal', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(_pacienteCompleto()));
      await _abrirModal(tester);

      await tester.tap(find.text('Arquivar Paciente'));
      await tester.pumpAndSettle();
      expect(find.text('Arquivar paciente?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Arquivar paciente?'), findsNothing);
      expect(find.text('Arquivar Paciente'), findsOneWidget);
    });

    testWidgets('arquivar com sucesso fecha o modal e mostra confirmação', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(_pacienteCompleto(), repositorio: FakeRepoModal()),
      );
      await _abrirModal(tester);

      await tester.tap(find.text('Arquivar Paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arquivar'));
      await tester.pumpAndSettle();

      expect(find.text('Paciente arquivado.'), findsOneWidget);
    });

    testWidgets('arquivar com erro exibe snackbar de erro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(_pacienteCompleto(), repositorio: RepoModalQueFalha()),
      );
      await _abrirModal(tester);

      await tester.tap(find.text('Arquivar Paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arquivar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('restaurar com sucesso fecha o modal e mostra confirmação', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(
          _pacienteCompleto(situacao: 'Arquivado'),
          repositorio: FakeRepoModal(),
        ),
      );
      await _abrirModal(tester);

      await tester.tap(find.text('Restaurar Paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();

      expect(find.text('Paciente restaurado.'), findsOneWidget);
    });

    testWidgets('restaurar com erro exibe snackbar de erro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(
          _pacienteCompleto(situacao: 'Arquivado'),
          repositorio: RepoModalQueFalha(),
        ),
      );
      await _abrirModal(tester);

      await tester.tap(find.text('Restaurar Paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });
  });
}
