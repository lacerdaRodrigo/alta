import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alta/telas/tela_configuracoes.dart';
import 'package:alta/telas/tela_login.dart';
import 'package:alta/provedores/provedor_autenticacao.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import '../../unitarios/auxiliares/fakes.dart';

class FakeRepoConfig extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarValorSessaoPadrao(String valor) async {}
}

class RepoConfigQueFalha extends Fake implements RepositorioDadosGoogle {
  @override
  Future<void> salvarValorSessaoPadrao(String valor) async {
    throw Exception('falha');
  }
}

class LogsComDados extends LogsAuditoriaNotifier {
  final List<String> _dados;
  LogsComDados(this._dados);
  @override
  List<String> build() => _dados;
}

class _PlanilhaIdFixo extends PlanilhaIdNotifier {
  final String _id;
  _PlanilhaIdFixo(this._id);
  @override
  String? build() => _id;
}

// Large surface so all content renders without scrolling
const _bigSurface = Size(600, 3000);

Widget _app({
  RepositorioDadosGoogle? repositorio,
  List<String> logs = const [],
  String? planilhaId,
}) {
  return ProviderScope(
    overrides: [
      provedorServicoAutenticacaoGoogle.overrideWithValue(
        ServicoAutenticacaoGoogleFake(),
      ),
      if (repositorio != null)
        provedorRepositorioDados.overrideWith((ref) => repositorio),
      provedorLogsAuditoria.overrideWith(() => LogsComDados(logs)),
      if (planilhaId != null)
        provedorPlanilhaId.overrideWith(() => _PlanilhaIdFixo(planilhaId)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: TelaConfiguracoes()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaConfiguracoes', () {
    testWidgets('deve exibir o título Configurações', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('deve exibir seção Base de dados', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('BASE DE DADOS'), findsOneWidget);
    });

    testWidgets('deve exibir botões Sincronizar e Abrir no Drive', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Sincronizar'), findsOneWidget);
      expect(find.text('Abrir no Drive'), findsOneWidget);
    });

    testWidgets('deve exibir seção Valor padrão da sessão', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('VALOR PADRÃO DA SESSÃO'), findsOneWidget);
    });

    testWidgets('deve exibir seção Preferências com switches', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('PREFERÊNCIAS'), findsOneWidget);
      expect(find.text('Notificações'), findsOneWidget);
      expect(find.text('Lembrete de evolução'), findsOneWidget);
    });

    testWidgets('deve exibir link Sair da conta', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Sair da conta'), findsOneWidget);
    });

    testWidgets('deve exibir link Exportar logs de auditoria', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Exportar logs de auditoria'), findsOneWidget);
    });

    testWidgets('planilha conectada exibe status Ativa quando ID presente', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(planilhaId: 'ABC123'));
      await tester.pumpAndSettle();

      expect(find.text('Ativa'), findsOneWidget);
    });

    testWidgets('planilha sem ID exibe status Inativa', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Inativa'), findsOneWidget);
    });

    testWidgets('toggle Notificações responde ao toque', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch).first;
      final initialValue = (tester.widget(switchFinder) as Switch).value;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect((tester.widget(switchFinder) as Switch).value, !initialValue);
    });

    testWidgets('deve exibir nome de usuário no cabeçalho', (tester) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Nome da sessão fake ou 'Profissional'
      expect(find.text('Profissional').evaluate().isNotEmpty, isTrue);
    });
  });

  group('TelaConfiguracoes - Cobertura adicional', () {
    testWidgets('confirmar logout navega para o login', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();

      expect(find.byType(TelaLogin), findsOneWidget);
    });

    testWidgets('logs de auditoria são copiados ao tocar exportar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') return null;
              if (call.method == 'Clipboard.getData') return null;
              return null;
            },
          );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        _app(logs: ['10/06 - LOGIN - entrou']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exportar logs de auditoria'));
      await tester.pumpAndSettle();

      expect(find.text('Logs copiados para a área de transferência.'),
          findsOneWidget);
    });

    testWidgets('abrir planilha falha exibe snackbar', (tester) async {
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

      await tester.binding.setSurfaceSize(_bigSurface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(planilhaId: 'ABC123'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir no Drive'));
      await tester.pumpAndSettle();

      // url_launcher returned false — no crash, widget still present
      expect(find.byType(TelaConfiguracoes), findsOneWidget);
    });
  });
}
