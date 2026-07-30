import 'package:alta/componentes/modal_detalhes_evolucao.dart';
import 'package:alta/modelos/evolucao.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Texto maior do que as 3 linhas que o card da lista mostra — é justamente o
/// conteúdo que ficava inacessível antes do modal existir.
const _textoLongo =
    'Sessão iniciada com mobilização passiva de tornozelo direito, '
    'seguida de fortalecimento isométrico de quadríceps em três séries '
    'de dez repetições. Paciente relatou desconforto leve no início, '
    'com melhora progressiva ao longo do atendimento. Orientada a '
    'manter as compressas mornas duas vezes ao dia e a evitar carga '
    'total no membro por mais 48 horas. Próxima sessão manterá o '
    'protocolo, acrescentando treino de equilíbrio unipodal.';

Paciente _paciente() => Paciente(
  idPaciente: 'P001',
  nome: 'Maria Evolução',
  telefone: '11999999999',
  dataNascimento: DateTime(1990, 1, 1),
  cpf: '12345678901',
  endereco: 'Rua A',
  situacao: 'Ativo',
);

Evolucao _evolucao({
  required int horasDesdeRegistro,
  String texto = _textoLongo,
}) {
  final agora = DateTime.now();
  return Evolucao(
    idEvolucao: 'E001',
    idPaciente: 'P001',
    idAgendamento: 'A001',
    dataAtendimento: DateTime(2026, 6, 10),
    evolucaoTexto: texto,
    dataRegistro: agora.subtract(Duration(hours: horasDesdeRegistro)),
    horarioInicioReal: DateTime(2026, 6, 10, 8),
    horarioFimReal: DateTime(2026, 6, 10, 9),
    condicaoPaciente: 'Melhora',
    dorSessao: 4,
    pressaoArterial: '120/80',
    frequenciaCardiaca: 72,
  );
}

Future<void> _abrirModal(
  WidgetTester tester, {
  required Evolucao evolucao,
  required Paciente? paciente,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => mostrarModalDetalhesEvolucao(
                  context,
                  evolucao: evolucao,
                  paciente: paciente,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mostrarModalDetalhesEvolucao', () {
    testWidgets('exibe o texto clínico completo, sem truncar', (tester) async {
      await _abrirModal(
        tester,
        evolucao: _evolucao(horasDesdeRegistro: 1),
        paciente: _paciente(),
      );

      final campo = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(campo.data, equals(_textoLongo));
      expect(campo.maxLines, isNull);
    });

    testWidgets('exibe paciente, data, condição e metadados', (tester) async {
      await _abrirModal(
        tester,
        evolucao: _evolucao(horasDesdeRegistro: 1),
        paciente: _paciente(),
      );

      expect(find.text('Maria Evolução'), findsOneWidget);
      expect(find.text('10/06/2026'), findsOneWidget);
      expect(find.text('Melhora'), findsOneWidget);
      expect(find.text('Status: Presente'), findsOneWidget);
      expect(find.text('08:00 — 09:00 (Real)'), findsOneWidget);
      expect(find.text('Dor: 4/10'), findsOneWidget);
      expect(find.text('PA: 120/80 | FC: 72 bpm'), findsOneWidget);
    });

    testWidgets('exibe botão Editar quando a evolução tem menos de 24h', (
      tester,
    ) async {
      await _abrirModal(
        tester,
        evolucao: _evolucao(horasDesdeRegistro: 1),
        paciente: _paciente(),
      );

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Registro fechado — mais de 24h'), findsNothing);
    });

    testWidgets('abre mesmo com mais de 24h, com registro fechado no rodapé', (
      tester,
    ) async {
      await _abrirModal(
        tester,
        evolucao: _evolucao(horasDesdeRegistro: 48),
        paciente: _paciente(),
      );

      // O ponto do modal: passadas as 24h o conteúdo continua legível.
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Registro fechado — mais de 24h'), findsOneWidget);
    });

    testWidgets('sem paciente não oferece edição, mesmo dentro das 24h', (
      tester,
    ) async {
      // TelaRegistroEvolucao exige um Paciente não-nulo.
      await _abrirModal(
        tester,
        evolucao: _evolucao(horasDesdeRegistro: 1),
        paciente: null,
      );

      expect(find.text('Paciente não encontrado'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('evolução sem texto mostra aviso no lugar do conteúdo', (
      tester,
    ) async {
      await _abrirModal(
        tester,
        evolucao: _evolucao(horasDesdeRegistro: 1, texto: ''),
        paciente: _paciente(),
      );

      final campo = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(campo.data, equals('Registro sem descrição clínica.'));
    });
  });
}
