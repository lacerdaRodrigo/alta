import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alta/componentes/rodape_versao.dart';

void main() {
  group('appVersao', () {
    test('usa o valor padrão 0.0.0 quando APP_VERSION não é definido', () {
      // Em testes, APP_VERSION não é passado via --dart-define.
      expect(appVersao, 'v0.0.0');
    });
  });

  group('VersaoOverlay', () {
    testWidgets('exibe a versão sobre o conteúdo da tela', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VersaoOverlay(
            child: Scaffold(body: Center(child: Text('conteúdo'))),
          ),
        ),
      );

      // O conteúdo da tela e a versão coexistem (overlay por cima).
      expect(find.text('conteúdo'), findsOneWidget);
      expect(find.text(appVersao), findsOneWidget);
    });

    testWidgets('não intercepta toques (IgnorePointer)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VersaoOverlay(
            child: Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      // Existe um IgnorePointer ativo (ignoring: true) envolvendo a versão,
      // garantindo que o overlay não bloqueia toques na tela.
      final ignorePointers = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.text(appVersao),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointers.any((w) => w.ignoring), isTrue);
    });
  });
}
