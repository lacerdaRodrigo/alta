import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fisio_home_care/telas/tela_dashboard.dart';
import 'package:fisio_home_care/telas/tela_login.dart';
import 'package:fisio_home_care/provedores/provedor_autenticacao.dart';
import 'package:fisio_home_care/servicos/servico_autenticacao_google.dart';
import '../../unitarios/auxiliares/fakes.dart';

/// Fake cujo [entrar] só completa quando o teste mandar, permitindo
/// inspecionar o estado de carregamento sem disparar a navegação real.
class ServicoAutenticacaoGoogleControlavel
    implements ServicoAutenticacaoGoogle {
  ServicoAutenticacaoGoogleControlavel({this.suportaLoginProgramatico = true});

  final _entrar = Completer<SessaoGoogle>();
  bool entrarFoiChamado = false;
  int vezesChamado = 0;

  @override
  Stream<ContaGoogleConectada> get contasConectadas => const Stream.empty();

  @override
  Stream<SessaoGoogle> get sessoesConectadas => const Stream.empty();

  /// `false` reproduz o web, onde o login parte do botão do Google.
  @override
  final bool suportaLoginProgramatico;

  @override
  Future<void> inicializar() async {}

  @override
  Future<SessaoGoogle?> tentarRestaurarSessao() async => null;

  @override
  Future<SessaoGoogle> entrar() {
    entrarFoiChamado = true;
    vezesChamado++;
    return _entrar.future;
  }

  @override
  Future<void> sair() async {}
}

/// Fake que reproduz fielmente o [ServicoAutenticacaoGoogleReal]: um único
/// login publica **duas** vezes — em `contasConectadas` e em
/// `sessoesConectadas` —, gerando duas mudanças de estado com
/// `estaAutenticado == true` para `TelaLogin` reagir.
class ServicoAutenticacaoGoogleDuplaEmissao
    implements ServicoAutenticacaoGoogle {
  final _contas = StreamController<ContaGoogleConectada>.broadcast();
  final _sessoes = StreamController<SessaoGoogle>.broadcast();

  @override
  Stream<ContaGoogleConectada> get contasConectadas => _contas.stream;

  @override
  Stream<SessaoGoogle> get sessoesConectadas => _sessoes.stream;

  @override
  bool get suportaLoginProgramatico => true;

  @override
  Future<void> inicializar() async {}

  @override
  Future<SessaoGoogle?> tentarRestaurarSessao() async => null;

  @override
  Future<SessaoGoogle> entrar() async {
    final sessao = SessaoGoogle(
      nomeUsuario: 'Dr. Teste',
      email: 'teste@example.com',
      // Falha rápido: evita que o carregamento do dashboard tente rede real.
      obterHeaders: () async => throw StateError('sem rede no teste'),
    );
    // Ordem deliberadamente invertida em relação ao serviço real: a sessão
    // (que liga `estaAutenticado`) vem primeiro, então a segunda emissão
    // também chega com `estaAutenticado == true`. É o pior caso, e garante que
    // `TelaLogin` seja imune a ele por conta própria.
    _sessoes.add(sessao);
    _contas.add(
      const ContaGoogleConectada(
        nomeUsuario: 'Dr. Teste',
        email: 'teste@example.com',
      ),
    );
    return sessao;
  }

  @override
  Future<void> sair() async {}

  void descartar() {
    _contas.close();
    _sessoes.close();
  }
}

/// Conta as substituições de rota. `pushReplacement` troca a rota no lugar,
/// então contar `TelaDashboard` na árvore não distingue uma navegação de duas —
/// só o observador revela a navegação duplicada.
class ContadorDeNavegacoes extends NavigatorObserver {
  int substituicoes = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    substituicoes++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

Widget criarAppTeste(
  ServicoAutenticacaoGoogle servico, {
  NavigatorObserver? observador,
}) {
  return ProviderScope(
    overrides: [
      provedorServicoAutenticacaoGoogle.overrideWithValue(servico),
    ],
    child: MaterialApp(
      home: const TelaLogin(),
      navigatorObservers: observador == null ? const [] : [observador],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TelaLogin', () {
    testWidgets('deve exibir título, subtítulo e botão Entrar com Google', (
      tester,
    ) async {
      await tester.pumpWidget(criarAppTeste(ServicoAutenticacaoGoogleFake()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Fisio', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Care', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Gestão', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('deve exibir checkbox de termos e os links legais', (
      tester,
    ) async {
      await tester.pumpWidget(criarAppTeste(ServicoAutenticacaoGoogleFake()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkbox_termos')), findsOneWidget);
      expect(
        find.textContaining('Termos de Uso', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Política de Privacidade', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('checkbox começa desmarcado e sem mensagem de erro', (
      tester,
    ) async {
      await tester.pumpWidget(criarAppTeste(ServicoAutenticacaoGoogleFake()));
      await tester.pumpAndSettle();

      // Checkbox custom: inicialmente sem ícone de confirmação
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('tocar no checkbox marca os termos como aceitos', (
      tester,
    ) async {
      await tester.pumpWidget(criarAppTeste(ServicoAutenticacaoGoogleFake()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkbox_termos')));
      await tester.pumpAndSettle();

      // Após marcar, ícone de check aparece
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets(
      'entrar sem aceitar os termos não chama o serviço',
      (tester) async {
        final servico = ServicoAutenticacaoGoogleControlavel();
        await tester.pumpWidget(criarAppTeste(servico));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_entrar_google')));
        await tester.pumpAndSettle();

        expect(servico.entrarFoiChamado, isFalse);
      },
    );

    testWidgets(
      'aceitar termos e entrar chama o serviço e exibe indicador de carregamento',
      (tester) async {
        final servico = ServicoAutenticacaoGoogleControlavel();
        await tester.pumpWidget(criarAppTeste(servico));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('checkbox_termos')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_entrar_google')));
        await tester.pump();

        expect(servico.entrarFoiChamado, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'tocar de novo enquanto carrega não chama o serviço uma segunda vez',
      (tester) async {
        final servico = ServicoAutenticacaoGoogleControlavel();
        await tester.pumpWidget(criarAppTeste(servico));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('checkbox_termos')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_entrar_google')));
        await tester.pump();
        // Segundo toque enquanto o primeiro login ainda está em andamento.
        await tester.tap(find.byKey(const Key('btn_entrar_google')));
        await tester.pump();

        expect(servico.vezesChamado, 1);
      },
    );

    testWidgets(
      'onde o login não é programático (web) não chama entrar nem trava o botão',
      (tester) async {
        final servico = ServicoAutenticacaoGoogleControlavel(
          suportaLoginProgramatico: false,
        );
        await tester.pumpWidget(criarAppTeste(servico));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('checkbox_termos')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_entrar_google')));
        await tester.pumpAndSettle();

        // No web o GIS exige que o login parta do botão que ele renderiza, então
        // `entrar()` não pode ser chamado — e o estado de carregamento precisa
        // ser desfeito, senão o botão do Google ficaria coberto por um
        // `IgnorePointer` para sempre.
        expect(servico.entrarFoiChamado, isFalse);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'login que emite conta e sessão navega para o Dashboard uma única vez',
      (tester) async {
        final servico = ServicoAutenticacaoGoogleDuplaEmissao();
        addTearDown(servico.descartar);
        final navegacoes = ContadorDeNavegacoes();

        await tester.pumpWidget(
          criarAppTeste(servico, observador: navegacoes),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('checkbox_termos')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_entrar_google')));
        await tester.pumpAndSettle();

        // Duas notificações com `estaAutenticado == true`, mas apenas um
        // `pushReplacement`: um segundo empurraria uma `TelaDashboard` por cima
        // da primeira, desmontando-a com o carregamento de dados em andamento
        // ("Bad state: Using 'ref' ... unmounted").
        expect(navegacoes.substituicoes, 1);
        expect(find.byType(TelaDashboard), findsOneWidget);
        expect(find.byType(TelaLogin), findsNothing);
      },
    );
  });
}
