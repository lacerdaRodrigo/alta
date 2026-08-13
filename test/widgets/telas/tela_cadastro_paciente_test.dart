import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/telas/tela_cadastro_paciente.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';

class FakeRepositorioDadosGoogle extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarPaciente(Paciente paciente) async {}
}

class RepositorioQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarPaciente(Paciente paciente) async {
    throw Exception('falha simulada ao salvar');
  }
}

class PacientesComDados extends ListaPacientesNotifier {
  final List<Paciente> _dados;

  PacientesComDados(this._dados);

  @override
  List<Paciente> build() => _dados;
}

Paciente _pacienteExistente({
  String id = 'P005',
  String cpf = '11144477735',
}) {
  return Paciente(
    idPaciente: id,
    nome: 'Paciente Existente',
    telefone: '11999999999',
    dataNascimento: DateTime(1980, 5, 10),
    cpf: cpf,
    endereco: 'Rua Velha',
    situacao: 'Ativo',
  );
}

/// Monta a tela numa superfície alta (todos os campos renderizados, sem
/// scroll) e injeta lista de pacientes e repositório.
Future<void> _montarTela(
  WidgetTester tester, {
  List<Paciente> pacientes = const [],
  RepositorioDadosGoogle? repositorio,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        provedorListaPacientes.overrideWith(() => PacientesComDados(pacientes)),
        if (repositorio != null)
          provedorRepositorioDados.overrideWith((ref) => repositorio),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('pt', 'BR'), Locale('en', 'US')],
        home: TelaCadastroPaciente(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Preenche os campos obrigatórios (nome, telefone, data, endereço, dor) e,
/// por conveniência, também o CPF — que não é obrigatório, mas a maioria dos
/// testes quer um paciente realista.
Future<void> _preencherObrigatorios(
  WidgetTester tester, {
  String cpf = '52998224725',
  String telefone = '11987654321',
}) async {
  await tester.enterText(find.byKey(const Key('campo_nome')), 'João Teste');
  await tester.enterText(find.byKey(const Key('campo_cpf')), cpf);
  await tester.enterText(find.byKey(const Key('campo_telefone')), telefone);
  await tester.enterText(find.byKey(const Key('campo_escala_dor')), '5');

  await tester.tap(find.byKey(const Key('campo_data_nascimento')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('campo_endereco')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo_rua')), 'Rua A');
  await tester.enterText(find.byKey(const Key('campo_bairro')), 'Centro');
  await tester.enterText(find.byKey(const Key('campo_cidade')), 'São Paulo');
  await tester.tap(find.byKey(const Key('btn_confirmar_endereco')));
  await tester.pumpAndSettle();
}

/// Confirma o popup "campos definitivos" exibido após tocar em Salvar.
Future<void> _confirmarCamposDefinitivos(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('btn_confirmar_cadastro')));
  await tester.pumpAndSettle();
}

Widget criarAppTeste() {
 return ProviderScope(
 overrides: [
 provedorListaPacientes.overrideWith(
 () => ListaPacientesNotifier(),
 ),
 ],
 child: const MaterialApp(
 localizationsDelegates: [
 GlobalMaterialLocalizations.delegate,
 GlobalWidgetsLocalizations.delegate,
 ],
 home: TelaCadastroPaciente(),
  supportedLocales: [Locale('en', 'US')],
 ),
 );
}

void main() {
 TestWidgetsFlutterBinding.ensureInitialized();

group('TelaCadastroPaciente - Endereço', () {
 testWidgets('deve exibir "Toque para preencher endereço" quando vazio', (
 tester,
 ) async {
 await tester.pumpWidget(criarAppTeste());
 await tester.pumpAndSettle();

      expect(find.text('Toque para preencher endereço'), findsOneWidget);
    });

    testWidgets('tocar no endereço abre o modal com 4 campos', (tester) async {
      await tester.pumpWidget(criarAppTeste());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Toque para preencher endereço'));
 await tester.pumpAndSettle();

 expect(find.text('Editar Endereço'), findsOneWidget);
 expect(find.text('Rua/Avenida *'), findsOneWidget);
 expect(find.text('Número'), findsOneWidget);
 expect(find.text('Bairro *'), findsOneWidget);
 expect(find.text('Cidade *'), findsOneWidget);
 expect(find.text('Cancelar'), findsOneWidget);
 expect(find.text('Confirmar'), findsOneWidget);
});

testWidgets('preencher campos e confirmar atualiza o endereço exibido', (
 tester,
 ) async {
 await tester.pumpWidget(criarAppTeste());
 await tester.pumpAndSettle();

  await tester.tap(find.text('Toque para preencher endereço'));
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextFormField, 'Rua/Avenida *'), 'Rua Belém');
 await tester.enterText(find.widgetWithText(TextFormField, 'Número'), '105');
 await tester.enterText(find.widgetWithText(TextFormField, 'Bairro *'), 'Centro');
 await tester.enterText(find.widgetWithText(TextFormField, 'Cidade *'), 'São Paulo');

 await tester.tap(find.text('Confirmar'));
 await tester.pumpAndSettle();

 expect(find.text('Rua Belém, 105, Centro, São Paulo'), findsOneWidget);
});

testWidgets('campos obrigatórios impedem confirmar sem preenchimento', (
 tester,
 ) async {
 await tester.pumpWidget(criarAppTeste());
 await tester.pumpAndSettle();

  await tester.tap(find.text('Toque para preencher endereço'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Confirmar'));
 await tester.pumpAndSettle();

 expect(find.text('Editar Endereço'), findsOneWidget);
 expect(find.text('Informe a rua/avenida.'), findsOneWidget);
 expect(find.text('Informe o bairro.'), findsOneWidget);
 expect(find.text('Informe a cidade.'), findsOneWidget);
});

testWidgets('endereço com apenas rua e cidade é composto corretamente', (
 tester,
 ) async {
 await tester.pumpWidget(criarAppTeste());
 await tester.pumpAndSettle();

  await tester.tap(find.text('Toque para preencher endereço'));
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextFormField, 'Rua/Avenida *'), 'Av Paulista');
 await tester.enterText(find.widgetWithText(TextFormField, 'Bairro *'), 'Bela Vista');
 await tester.enterText(find.widgetWithText(TextFormField, 'Cidade *'), 'São Paulo');
 // Número vazio

 await tester.tap(find.text('Confirmar'));
 await tester.pumpAndSettle();

 expect(find.text('Av Paulista, Bela Vista, São Paulo'), findsOneWidget);
});

testWidgets('cancelar não altera o endereço', (tester) async {
 await tester.pumpWidget(criarAppTeste());
 await tester.pumpAndSettle();

  expect(find.text('Toque para preencher endereço'), findsOneWidget);

  await tester.tap(find.text('Toque para preencher endereço'));
 await tester.pumpAndSettle();

 await tester.enterText(find.widgetWithText(TextFormField, 'Rua/Avenida *'), 'Rua X');
 await tester.enterText(find.widgetWithText(TextFormField, 'Bairro *'), 'Bairro Y');
 await tester.enterText(find.widgetWithText(TextFormField, 'Cidade *'), 'Cidade Z');

 await tester.tap(find.text('Cancelar'));
 await tester.pumpAndSettle();

  expect(find.text('Toque para preencher endereço'), findsOneWidget);
  expect(find.text('Rua X'), findsNothing);
});
});

group('TelaCadastroPaciente - Anamnese Clínica', () {
 testWidgets('deve exibir seção de Anamnese Clínica com todos os campos', (
 tester,
 ) async {
 await tester.pumpWidget(criarAppTeste());
 await tester.pumpAndSettle();

 // Scroll down to make the Anamnese section visible (ListView lazy rendering)
 await tester.scrollUntilVisible(
  find.text('Anamnese Clínica'),
  200,
  scrollable: find.byType(Scrollable).first,
 );
 await tester.pumpAndSettle();
 expect(find.text('Anamnese Clínica'), findsOneWidget);
 expect(find.text('Queixa Principal (QP)'), findsOneWidget);

 await tester.scrollUntilVisible(
  find.text('Histórico da Doença Atual (HDA)'),
  200,
  scrollable: find.byType(Scrollable).first,
 );
 await tester.pumpAndSettle();
 expect(find.text('Histórico da Doença Atual (HDA)'), findsOneWidget);

 await tester.scrollUntilVisible(
  find.text('Gênero'),
  200,
  scrollable: find.byType(Scrollable).first,
 );
 await tester.pumpAndSettle();
        expect(find.text('Gênero'), findsOneWidget);

 await tester.scrollUntilVisible(
  find.text('Escala de dor (0-10)'),
  200,
  scrollable: find.byType(Scrollable).first,
 );
 await tester.pumpAndSettle();
        expect(find.text('Escala de dor (0-10)'), findsOneWidget);
 });

testWidgets('deve permitir salvar paciente sem preencher campos de anamnese', (
  tester,
) async {
  final container = ProviderContainer(
    overrides: [
      provedorListaPacientes.overrideWith(() => ListaPacientesNotifier()),
      provedorRepositorioDados.overrideWith((ref) => FakeRepositorioDadosGoogle()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TelaCadastroPaciente(),
        supportedLocales: [Locale('en', 'US')],
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Preencher apenas dados pessoais obrigatórios
  await tester.enterText(find.widgetWithText(TextFormField, 'Nome Completo *'), 'João Souza');
  await tester.enterText(find.widgetWithText(TextFormField, 'CPF'), '52998224725');
  await tester.enterText(find.widgetWithText(TextFormField, 'Telefone *'), '31987654321');

  // Preencher data de nascimento
  await tester.tap(find.text('Selecionar data'));
  await tester.pumpAndSettle();
  // Confirmar a seleção padrão (1990-01-01) sem mudar a data
  final okButton = find.widgetWithText(TextButton, 'OK');
  if (okButton.evaluate().isNotEmpty) {
    await tester.tap(okButton);
  } else {
    // Se não encontrar "OK", tenta fechar o diálogo
    await tester.tapAt(const Offset(100, 100));
  }
  await tester.pumpAndSettle();

  // Preencher endereço
  await tester.tap(find.text('Toque para preencher endereço'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Rua/Avenida *'), 'Rua B');
  await tester.enterText(find.widgetWithText(TextFormField, 'Bairro *'), 'Bairro C');
  await tester.enterText(find.widgetWithText(TextFormField, 'Cidade *'), 'Cidade D');
  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle();

  // Preencher escala de dor (que agora é obrigatório)
  await tester.scrollUntilVisible(
    find.widgetWithText(TextFormField, 'Escala de dor (0-10)'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Escala de dor (0-10)'), '5');
  await tester.pumpAndSettle();

  // Scroll até o botão Salvar e clicar
  await tester.scrollUntilVisible(
    find.text('Salvar Paciente'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Salvar Paciente'));
  await tester.pumpAndSettle();
  await _confirmarCamposDefinitivos(tester);

  // Verificar se os dados básicos foram salvos
  final pacientes = container.read(provedorListaPacientes);
  expect(pacientes, isNotEmpty);
  final pacienteSalvo = pacientes.first;
  expect(pacienteSalvo.nome, 'João Souza');
  expect(pacienteSalvo.queixaPrincipal, isNull);
  expect(pacienteSalvo.histDoencaAtual, isNull);
  expect(pacienteSalvo.comorbidades, isNull);
  expect(pacienteSalvo.medicamentos, isNull);
  expect(pacienteSalvo.alergias, isNull);
  expect(pacienteSalvo.cirurgias, isNull);
  expect(pacienteSalvo.habitosVida, isNull);
});

testWidgets('deve bloquear digitação de valor acima de 10 na escala de dor', (
  tester,
) async {
  await tester.pumpWidget(criarAppTeste());
  await tester.pumpAndSettle();

  // Scroll até o campo de dor
  await tester.scrollUntilVisible(
    find.widgetWithText(TextFormField, 'Escala de dor (0-10)'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  // Tentar digitar 11 - deve ser bloqueado e manter vazio
  await tester.enterText(find.widgetWithText(TextFormField, 'Escala de dor (0-10)'), '11');
  await tester.pumpAndSettle();

  // O campo deve permanecer vazio (valor rejeitado pelo Formatter)
  final dorField = find.widgetWithText(TextFormField, 'Escala de dor (0-10)');
  final TextFormField dorWidget = tester.widget(dorField);
  expect(dorWidget.controller?.text, isEmpty);

  // Digitar valor válido (5) - deve aceitar
  await tester.enterText(find.widgetWithText(TextFormField, 'Escala de dor (0-10)'), '5');
  await tester.pumpAndSettle();
  expect(dorWidget.controller?.text, equals('5'));

  // Tentar digitar 99 - deve ser bloqueado e manter 5
  await tester.enterText(find.widgetWithText(TextFormField, 'Escala de dor (0-10)'), '99');
  await tester.pumpAndSettle();
  expect(dorWidget.controller?.text, equals('5'));
});
});

group('TelaCadastroPaciente - Campos obrigatorios', () {
  testWidgets('CT-F1: todos os campos obrigatórios vazios mostra dialog com 4 itens', (
    tester,
  ) async {
    await tester.pumpWidget(criarAppTeste());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar Paciente'));
    await tester.pumpAndSettle();

    expect(find.text('Campos obrigatórios'), findsOneWidget);
    expect(find.text('Nome Completo'), findsOneWidget);
    // CPF não é mais obrigatório: nunca aparece na lista de pendências.
    expect(find.text('CPF'), findsNothing);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.text('Data de Nascimento'), findsWidgets);
    expect(find.text('Endereço'), findsWidgets);

    // Fecha o dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Campos obrigatórios'), findsNothing);
  });

  testWidgets('CT-F2: apenas Nome preenchido mostra dialog com 3 itens', (
    tester,
  ) async {
    await tester.pumpWidget(criarAppTeste());
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome Completo *'), 'João');

    await tester.tap(find.text('Salvar Paciente'));
    await tester.pumpAndSettle();

    expect(find.text('Campos obrigatórios'), findsOneWidget);
    expect(find.text('Nome Completo'), findsNothing);
    expect(find.text('CPF'), findsNothing);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.text('Data de Nascimento'), findsWidgets);
    expect(find.text('Endereço'), findsWidgets);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'CT-F3: CPF em branco não aparece nos campos obrigatórios e o cadastro segue normalmente',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          provedorListaPacientes.overrideWith(() => ListaPacientesNotifier()),
          provedorRepositorioDados.overrideWith(
            (ref) => FakeRepositorioDadosGoogle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: TelaCadastroPaciente(),
            supportedLocales: [Locale('en', 'US')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preenche tudo, menos o CPF (fica em branco de propósito).
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome Completo *'),
        'Sem CPF',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone *'),
        '31987654321',
      );

      await tester.tap(find.text('Selecionar data'));
      await tester.pumpAndSettle();
      final okButton = find.widgetWithText(TextButton, 'OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('Toque para preencher endereço'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Rua/Avenida *'),
        'Rua A',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bairro *'),
        'Bairro B',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cidade *'),
        'Cidade C',
      );
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Escala de dor (0-10)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escala de dor (0-10)'),
        '5',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Salvar Paciente'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar Paciente'));
      await tester.pumpAndSettle();

      // Sem CPF, o dialog de campos obrigatórios não aparece.
      expect(find.text('Campos obrigatórios'), findsNothing);
      expect(find.text('Atenção: campos definitivos'), findsOneWidget);
      await _confirmarCamposDefinitivos(tester);

      final pacientes = container.read(provedorListaPacientes);
      expect(pacientes, isNotEmpty);
      expect(pacientes.first.cpf, isEmpty);
    },
  );

  testWidgets('CT-F4: Nome+Telefone preenchidos mostra dialog com 2 itens', (
    tester,
  ) async {
    await tester.pumpWidget(criarAppTeste());
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome Completo *'), 'Maria');
    await tester.enterText(find.widgetWithText(TextFormField, 'Telefone *'), '(11) 91234-5678');

    await tester.tap(find.text('Salvar Paciente'));
    await tester.pumpAndSettle();

    expect(find.text('Campos obrigatórios'), findsOneWidget);
    expect(find.text('Nome Completo'), findsNothing);
    expect(find.text('CPF'), findsNothing);
    expect(find.text('Telefone'), findsNothing);
    expect(find.text('Data de Nascimento'), findsWidgets);
    expect(find.text('Endereço'), findsWidgets);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('CT-F5: todos preenchidos salva sem dialog', (tester) async {
    final container = ProviderContainer(
      overrides: [
        provedorListaPacientes.overrideWith(() => ListaPacientesNotifier()),
        provedorRepositorioDados.overrideWith((ref) => FakeRepositorioDadosGoogle()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TelaCadastroPaciente(),
          supportedLocales: [Locale('en', 'US')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Preencher todos os campos obrigatórios
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome Completo *'), 'João Teste');
    await tester.enterText(find.widgetWithText(TextFormField, 'CPF'), '52998224725');
    await tester.enterText(find.widgetWithText(TextFormField, 'Telefone *'), '31987654321');

    // Data de nascimento
    await tester.tap(find.text('Selecionar data'));
    await tester.pumpAndSettle();
    final okButton = find.widgetWithText(TextButton, 'OK');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton);
    }
    await tester.pumpAndSettle();

    // Endereço
    await tester.tap(find.text('Toque para preencher endereço'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Rua/Avenida *'), 'Rua A');
    await tester.enterText(find.widgetWithText(TextFormField, 'Bairro *'), 'Bairro B');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cidade *'), 'Cidade C');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    // Escala de dor
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Escala de dor (0-10)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Escala de dor (0-10)'), '5');
    await tester.pumpAndSettle();

    // Salvar
    await tester.scrollUntilVisible(
      find.text('Salvar Paciente'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar Paciente'));
    await tester.pumpAndSettle();

    // Dialog de campos obrigatórios NÃO deve aparecer
    expect(find.text('Campos obrigatórios'), findsNothing);
    // Mas o aviso de campos definitivos aparece; confirmar para salvar.
    expect(find.text('Atenção: campos definitivos'), findsOneWidget);
    await _confirmarCamposDefinitivos(tester);
    final pacientes = container.read(provedorListaPacientes);
    expect(pacientes, isNotEmpty);
    final pacienteSalvo = pacientes.first;
    expect(pacienteSalvo.nome, 'João Teste');
  });

  testWidgets('CT-F6: dialog fecha ao clicar OK', (tester) async {
    await tester.pumpWidget(criarAppTeste());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar Paciente'));
    await tester.pumpAndSettle();

    expect(find.text('Campos obrigatórios'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Campos obrigatórios'), findsNothing);
  });
});

group('TelaCadastroPaciente - Cobertura adicional', () {
  testWidgets('botão fechar (X) aciona o retorno', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          provedorListaPacientes.overrideWith(() => ListaPacientesNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaCadastroPaciente(),
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
    expect(find.text('Novo Paciente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_fechar')));
    await tester.pumpAndSettle();

    expect(find.text('Novo Paciente'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('selecionar gênero no dropdown atualiza a seleção', (
    tester,
  ) async {
    await _montarTela(tester);

    await tester.tap(find.byKey(const Key('dropdown_genero')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feminino').last);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('dropdown_genero')),
    );
    expect(dropdown.initialValue, 'Feminino');
  });

  testWidgets('validação do formulário aceita o gênero selecionado', (
    tester,
  ) async {
    await _montarTela(tester);

    // O validador do dropdown só roda via Form.validate(); com um gênero
    // selecionado (padrão "Masculino") a validação passa.
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isTrue);
  });

  testWidgets('telefone com menos de 10 dígitos é sinalizado', (tester) async {
    await _montarTela(tester);

    await tester.enterText(find.byKey(const Key('campo_telefone')), '119999');
    await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
    await tester.pumpAndSettle();

    expect(find.text('Campos obrigatórios'), findsOneWidget);
    expect(
      find.text('Telefone inválido (mínimo 10 dígitos)'),
      findsOneWidget,
    );
  });

  testWidgets('CPF já cadastrado exibe snackbar de erro', (tester) async {
    await _montarTela(
      tester,
      pacientes: [_pacienteExistente(cpf: '52998224725')],
      repositorio: FakeRepositorioDadosGoogle(),
    );

    await _preencherObrigatorios(tester, cpf: '52998224725');

    await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
    await tester.pumpAndSettle();

    expect(find.text('Este CPF já está cadastrado.'), findsOneWidget);
  });

  testWidgets(
    'CPF sem dígito verificador válido (ex.: 11111111111) é aceito, mas duplicado é bloqueado',
    (tester) async {
      // Não valida mais o algoritmo do CPF, mas duplicidade continua sendo
      // comparação de texto — então mesmo uma sequência "inválida" repetida
      // precisa ser barrada igual a qualquer outro CPF.
      await _montarTela(
        tester,
        pacientes: [_pacienteExistente(cpf: '11111111111')],
        repositorio: FakeRepositorioDadosGoogle(),
      );

      await _preencherObrigatorios(tester, cpf: '11111111111');

      await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
      await tester.pumpAndSettle();

      expect(find.text('Campos obrigatórios'), findsNothing);
      expect(find.text('Este CPF já está cadastrado.'), findsOneWidget);
    },
  );

  testWidgets(
    'CPF com sequência qualquer (sem checksum válido) é salvo como digitado',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          provedorListaPacientes.overrideWith(() => ListaPacientesNotifier()),
          provedorRepositorioDados.overrideWith(
            (ref) => FakeRepositorioDadosGoogle(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('pt', 'BR'), Locale('en', 'US')],
            home: TelaCadastroPaciente(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "123" não passa em nenhum algoritmo de CPF real — nem em dígitos
      // suficientes. Precisa ser aceito do mesmo jeito.
      await _preencherObrigatorios(tester, cpf: '123');

      await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
      await tester.pumpAndSettle();

      expect(find.text('Campos obrigatórios'), findsNothing);
      await _confirmarCamposDefinitivos(tester);

      final pacientes = container.read(provedorListaPacientes);
      expect(pacientes, isNotEmpty);
      // Compara só os dígitos: a máscara pode ou não anexar pontuação a um
      // trecho parcial, o que não é o que este teste quer verificar.
      expect(
        pacientes.first.cpf.replaceAll(RegExp(r'[^\d]'), ''),
        '123',
      );
    },
  );

  testWidgets(
    'CPF em branco não gera falso positivo de duplicidade entre dois pacientes',
    (tester) async {
      await _montarTela(
        tester,
        pacientes: [_pacienteExistente(cpf: '')],
        repositorio: FakeRepositorioDadosGoogle(),
      );

      await _preencherObrigatorios(tester, cpf: '');

      await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
      await tester.pumpAndSettle();

      expect(find.text('Este CPF já está cadastrado.'), findsNothing);
      expect(find.text('Atenção: campos definitivos'), findsOneWidget);
    },
  );

  testWidgets(
    'salvar com todos os campos gera próximo ID e persiste a anamnese',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          provedorListaPacientes.overrideWith(
            () => PacientesComDados([_pacienteExistente(id: 'P005')]),
          ),
          provedorRepositorioDados.overrideWith(
            (ref) => FakeRepositorioDadosGoogle(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(1000, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('pt', 'BR'), Locale('en', 'US')],
            home: TelaCadastroPaciente(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _preencherObrigatorios(tester);

      // Preencher todos os campos opcionais de anamnese.
      await tester.enterText(
        find.byKey(const Key('campo_queixa')),
        'Dor lombar',
      );
      await tester.enterText(find.byKey(const Key('campo_hda')), 'HDA texto');
      await tester.enterText(find.byKey(const Key('campo_hp')), 'HP texto');
      await tester.enterText(
        find.byKey(const Key('campo_ocupacao')),
        'Professor',
      );
      await tester.enterText(
        find.byKey(const Key('campo_comorbidades')),
        'Hipertensão',
      );
      await tester.enterText(
        find.byKey(const Key('campo_medicamentos')),
        'Losartana',
      );
      await tester.enterText(
        find.byKey(const Key('campo_alergias')),
        'Dipirona',
      );
      await tester.enterText(
        find.byKey(const Key('campo_cirurgias')),
        'Apendicectomia',
      );
      await tester.enterText(
        find.byKey(const Key('campo_habitos')),
        'Sedentário',
      );

      await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
      await tester.pumpAndSettle();
      await _confirmarCamposDefinitivos(tester);

      final pacientes = container.read(provedorListaPacientes);
      expect(pacientes, hasLength(2));
      final novo = pacientes.last;
      expect(novo.idPaciente, 'P006'); // próximo ID após P005
      expect(novo.queixaPrincipal, 'Dor lombar');
      expect(novo.histDoencaAtual, 'HDA texto');
      expect(novo.histPregresso, 'HP texto');
      expect(novo.ocupacao, 'Professor');
      expect(novo.comorbidades, 'Hipertensão');
      expect(novo.medicamentos, 'Losartana');
      expect(novo.alergias, 'Dipirona');
      expect(novo.cirurgias, 'Apendicectomia');
      expect(novo.habitosVida, 'Sedentário');
    },
  );

  testWidgets('falha ao salvar exibe snackbar de erro', (tester) async {
    await _montarTela(tester, repositorio: RepositorioQueFalha());

    await _preencherObrigatorios(tester);

    await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
    await tester.pumpAndSettle();
    await _confirmarCamposDefinitivos(tester);

    expect(
      find.text('Ocorreu um erro inesperado. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'popup de campos definitivos: Revisar cancela sem salvar',
    (tester) async {
      await _montarTela(tester, repositorio: FakeRepositorioDadosGoogle());

      await _preencherObrigatorios(tester);

      await tester.tap(find.byKey(const Key('btn_salvar_paciente')));
      await tester.pumpAndSettle();

      // Aviso aparece listando os campos definitivos.
      expect(find.text('Atenção: campos definitivos'), findsOneWidget);

      // Revisar fecha o aviso e não salva.
      await tester.tap(find.byKey(const Key('btn_revisar_cadastro')));
      await tester.pumpAndSettle();

      expect(find.text('Atenção: campos definitivos'), findsNothing);
      expect(find.text('Paciente cadastrado com sucesso!'), findsNothing);
    },
  );
});
}