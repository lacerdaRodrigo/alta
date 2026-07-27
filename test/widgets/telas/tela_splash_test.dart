import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alta/telas/tela_splash.dart';

/// Destino simples para não arrastar autenticação/Google para dentro do teste.
class _TelaDestino extends StatelessWidget {
  const _TelaDestino();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('destino')));
}

Widget _app({bool reduzirMovimento = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduzirMovimento),
      child: TelaSplash(construirDestino: (_) => const _TelaDestino()),
    ),
  );
}

void main() {
  group('TelaSplash', () {
    testWidgets('mostra logotipo, título e subtítulo da marca', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('splash_logotipo')), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(
        find.text('Gestão de atendimentos\ndomiciliares de fisioterapia'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('desenha o traçado de ECG durante a abertura', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(const Key('splash_ecg')), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('não navega antes de terminar a animação', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(kDuracaoSplash - const Duration(milliseconds: 200));

      expect(find.text('destino'), findsNothing);
      expect(find.text('Alta'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('vai para o destino ao fim da animação', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('destino'), findsOneWidget);
      expect(find.byKey(const Key('splash_logotipo')), findsNothing);
    });

    testWidgets('substitui a rota: não dá para voltar para a splash', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final navegador = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navegador.canPop(), isFalse);
    });

    testWidgets('com "reduzir movimento" pula direto para o destino', (
      tester,
    ) async {
      await tester.pumpWidget(_app(reduzirMovimento: true));
      await tester.pump();
      await tester.pump(kDuracaoTransicaoSplash);

      expect(find.text('destino'), findsOneWidget);
    });

    testWidgets('descartar a tela no meio da animação não quebra', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(const MaterialApp(home: _TelaDestino()));
      await tester.pump(kDuracaoSplash);

      expect(tester.takeException(), isNull);
      expect(find.text('destino'), findsOneWidget);
    });
  });
}
