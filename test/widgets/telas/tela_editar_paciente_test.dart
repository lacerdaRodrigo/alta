import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import 'package:alta/telas/tela_editar_paciente.dart';

/// Captura o paciente enviado para `atualizarPaciente`.
class FakeRepoEdicao extends Fake implements RepositorioDadosGoogle {
  Paciente? capturado;

  @override
  Future<void> atualizarPaciente(Paciente paciente) async {
    capturado = paciente;
  }
}

class RepoEdicaoQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> atualizarPaciente(Paciente paciente) async =>
      throw Exception('falha simulada ao atualizar');
}

class PacientesComDados extends ListaPacientesNotifier {
  final List<Paciente> _dados;
  PacientesComDados(this._dados);
  @override
  List<Paciente> build() => _dados;
}

Paciente _paciente() => Paciente(
  idPaciente: 'P007',
  nome: 'Maria Souza',
  telefone: '11988887777',
  dataNascimento: DateTime(1985, 3, 20),
  cpf: '529.982.247-25',
  endereco: 'Rua Antiga, 10, Centro, São Paulo',
  queixaPrincipal: 'Dor no ombro',
  histDoencaAtual: 'Há 1 mês',
  genero: 'Feminino',
  dor: '6',
  comorbidades: 'Diabetes',
  medicamentos: 'Metformina',
  alergias: 'Nenhuma',
  cirurgias: 'Nenhuma',
  habitosVida: 'Ativa',
  situacao: 'Ativo',
);

Future<void> _montarTela(
  WidgetTester tester,
  Paciente paciente, {
  RepositorioDadosGoogle? repositorio,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        provedorListaPacientes.overrideWith(() => PacientesComDados([paciente])),
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
        home: TelaEditarPaciente(paciente: paciente),
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

  group('TelaEditarPaciente', () {
    testWidgets('pré-preenche os campos editáveis com o paciente', (
      tester,
    ) async {
      await _montarTela(tester, _paciente());

      expect(find.text('11988887777'), findsOneWidget); // telefone
      expect(
        find.text('Rua Antiga, 10, Centro, São Paulo'),
        findsOneWidget,
      ); // endereço
      expect(find.text('Dor no ombro'), findsOneWidget); // queixa
      expect(find.text('Diabetes'), findsOneWidget); // comorbidades
      // Nome (travado) aparece no campo e no subtítulo do cabeçalho.
      expect(find.text('Maria Souza'), findsWidgets);
    });

    testWidgets('nome, CPF, nascimento e gênero estão desabilitados', (
      tester,
    ) async {
      await _montarTela(tester, _paciente());

      expect(_campoHabilitado(tester, 'campo_nome'), isFalse);
      expect(_campoHabilitado(tester, 'campo_cpf'), isFalse);
      expect(_campoHabilitado(tester, 'campo_data_nascimento'), isFalse);
      expect(_campoHabilitado(tester, 'campo_genero'), isFalse);

      // Campos editáveis seguem habilitados.
      expect(_campoHabilitado(tester, 'campo_telefone'), isTrue);
      expect(_campoHabilitado(tester, 'campo_endereco'), isTrue);
    });

    testWidgets(
      'salvar atualiza editáveis e preserva identidade do paciente',
      (tester) async {
        final repo = FakeRepoEdicao();
        await _montarTela(tester, _paciente(), repositorio: repo);

        await tester.enterText(
          find.byKey(const Key('campo_endereco')),
          'Rua Nova, 50, Bairro, São Paulo',
        );
        await tester.enterText(
          find.byKey(const Key('campo_comorbidades')),
          'Hipertensão',
        );
        // Limpa a queixa para verificar que vira null.
        await tester.enterText(find.byKey(const Key('campo_queixa')), '');

        await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
        await tester.pumpAndSettle();

        final salvo = repo.capturado;
        expect(salvo, isNotNull);
        // Identidade preservada.
        expect(salvo!.idPaciente, 'P007');
        expect(salvo.nome, 'Maria Souza');
        expect(salvo.cpf, '529.982.247-25');
        expect(salvo.genero, 'Feminino');
        expect(salvo.dataNascimento, DateTime(1985, 3, 20));
        // Telefone não editado permanece igual.
        expect(salvo.telefone, '11988887777');
        expect(salvo.endereco, 'Rua Nova, 50, Bairro, São Paulo');
        expect(salvo.comorbidades, 'Hipertensão');
        // Campo limpo vira null.
        expect(salvo.queixaPrincipal, isNull);
      },
    );

    testWidgets('endereço vazio impede salvar', (tester) async {
      await _montarTela(tester, _paciente(), repositorio: FakeRepoEdicao());

      await tester.enterText(find.byKey(const Key('campo_endereco')), '');

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      expect(find.text('Campos obrigatórios'), findsOneWidget);
      expect(find.text('Endereço'), findsOneWidget);
    });

    testWidgets('telefone com menos de 10 dígitos é sinalizado', (
      tester,
    ) async {
      await _montarTela(tester, _paciente(), repositorio: FakeRepoEdicao());

      await tester.enterText(find.byKey(const Key('campo_telefone')), '119999');

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      expect(find.text('Campos obrigatórios'), findsOneWidget);
      expect(
        find.text('Telefone inválido (mínimo 10 dígitos)'),
        findsOneWidget,
      );
    });

    testWidgets('falha ao atualizar exibe snackbar de erro', (tester) async {
      await _montarTela(tester, _paciente(), repositorio: RepoEdicaoQueFalha());

      await tester.tap(find.byKey(const Key('btn_salvar_edicao')));
      await tester.pumpAndSettle();

      expect(
        find.text('Ocorreu um erro inesperado. Tente novamente.'),
        findsOneWidget,
      );
    });
  });
}
