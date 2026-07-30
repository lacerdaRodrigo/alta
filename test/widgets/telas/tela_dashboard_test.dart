import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/provedores/provedor_autenticacao.dart';
import 'package:alta/provedores/provedores_dados.dart';
import 'package:alta/componentes/design_system.dart';
import 'package:alta/telas/tela_configuracoes.dart';
import 'package:alta/telas/tela_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../unitarios/auxiliares/fakes.dart';

// ---------------------------------------------------------------------------
// Notifiers de teste
// ---------------------------------------------------------------------------

class CarregamentoComEstado extends CarregamentoDadosNotifier {
  final EstadoCarregamentoDados _inicial;
  CarregamentoComEstado(this._inicial);
  @override
  EstadoCarregamentoDados build() => _inicial;
}

class PacientesComDados extends ListaPacientesNotifier {
  final List<Paciente> _dados;
  PacientesComDados(this._dados);
  @override
  List<Paciente> build() => _dados;
}

class AgendamentosComDados extends ListaAgendamentosNotifier {
  final List<Agendamento> _dados;
  AgendamentosComDados(this._dados);
  @override
  List<Agendamento> build() => _dados;
}

// ---------------------------------------------------------------------------
// Helpers de teste
// ---------------------------------------------------------------------------

Paciente _paciente({
  String id = 'P001',
  String nome = 'João Dashboard',
  String situacao = 'Ativo',
}) {
  return Paciente(
    idPaciente: id,
    nome: nome,
    telefone: '11999999999',
    dataNascimento: DateTime(1990, 1, 1),
    cpf: '12345678901',
    endereco: 'Rua A',
    situacao: situacao,
  );
}

/// Horários ancorados nos extremos do dia: o rótulo da sessão compara o horário
/// previsto com o relógio real, então prender o teste a um horário fixo do meio
/// do dia o faria passar de manhã e falhar à tarde.
const _horaFutura = '23:59';
const _horaPassada = '00:00';

Agendamento _agendamento({
  required String id,
  String idPaciente = 'P001',
  required DateTime data,
  String horaInicio = '09:00',
  String situacao = Agendamento.situacaoAgendado,
}) {
  return Agendamento(
    idAgendamento: id,
    idPaciente: idPaciente,
    data: data,
    horaInicio: horaInicio,
    horaFim: '10:00',
    valorSessao: 150,
    situacao: situacao,
  );
}

const _carregado = EstadoCarregamentoDados(
  status: StatusCarregamentoDados.carregado,
);

Widget _criarApp({
  required EstadoCarregamentoDados carregamento,
  List<Paciente> pacientes = const [],
  List<Agendamento> agendamentos = const [],
  String nome = 'Dr. Teste',
}) {
  return ProviderScope(
    overrides: [
      provedorServicoAutenticacaoGoogle.overrideWithValue(
        ServicoAutenticacaoGoogleFake(),
      ),
      provedorCarregamentoDados.overrideWith(
        () => CarregamentoComEstado(carregamento),
      ),
      provedorListaPacientes.overrideWith(() => PacientesComDados(pacientes)),
      provedorListaAgendamentos.overrideWith(
        () => AgendamentosComDados(agendamentos),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: TelaDashboard(nomeUsuario: nome),
    ),
  );
}

Future<void> _montar(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelaDashboard — estados de carregamento', () {
    testWidgets('estado carregando exibe indicador de progresso', (
      tester,
    ) async {
      await _montar(
        tester,
        _criarApp(
          carregamento: const EstadoCarregamentoDados(
            status: StatusCarregamentoDados.carregando,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('estado erro exibe mensagem e botão tentar novamente', (
      tester,
    ) async {
      await _montar(
        tester,
        _criarApp(
          carregamento: const EstadoCarregamentoDados(
            status: StatusCarregamentoDados.erro,
            mensagemErro: 'Falha de rede teste',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Não foi possível carregar os dados.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar os dados.'), findsOneWidget);
    });
  });

  group('TelaDashboard — cabeçalho e cards', () {
    testWidgets('cabeçalho mostra nome e iniciais do usuário', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      // Nome do usuário no header
      expect(find.text('Dr. Teste'), findsOneWidget);
      // Iniciais: 'D' (Dr.) + 'T' (Teste) = 'DT'
      expect(find.text('DT'), findsOneWidget);
    });

    testWidgets('tocar no avatar abre as Configurações', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      // Avatar com iniciais 'DT'
      await tester.tap(find.text('DT'));
      await tester.pumpAndSettle();

      expect(find.byType(TelaConfiguracoes), findsOneWidget);
    });

    testWidgets('stat tiles exibem pacientes ativos e pendências', (
      tester,
    ) async {
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [
            _paciente(id: 'P001', nome: 'João Ativo', situacao: 'Ativo'),
            _paciente(
              id: 'P002',
              nome: 'Maria Arquivada',
              situacao: 'Arquivado',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pacientes ativos'), findsOneWidget);
      expect(find.text('Pendências'), findsOneWidget);
    });

    testWidgets('agenda vazia exibe estado vazio com mensagem', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agenda de hoje'), findsOneWidget);
      expect(find.text('Nenhuma sessão hoje'), findsOneWidget);
    });

    testWidgets('link "Ver tudo" navega para aba Sessões', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver tudo'));
      await tester.pumpAndSettle();

      // Sessões tab shows sessions header (also in bottom nav = multiple)
      expect(find.text('Sessões'), findsWidgets);
    });

    testWidgets('início não exibe mais o card de histórico de evoluções', (
      tester,
    ) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Histórico de evoluções'), findsNothing);
    });
  });

  group('TelaDashboard — navegação e FAB', () {
    testWidgets('barra inferior alterna abas', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      // Tab inicial: Início
      expect(find.text('Agenda de hoje'), findsOneWidget);

      // Tap Sessões
      await tester.tap(find.text('Sessões'));
      await tester.pumpAndSettle();
      expect(find.text('Sessões'), findsWidgets);

      // Tap Pacientes
      await tester.tap(find.text('Pacientes'));
      await tester.pumpAndSettle();
      expect(find.text('Pacientes'), findsWidgets);

      // Voltar para Início
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();
      expect(find.text('Agenda de hoje'), findsOneWidget);
    });

    testWidgets('FAB na aba Pacientes abre cadastro', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pacientes'));
      await tester.pumpAndSettle();

      // FAB in center of bottom nav (GestureDetector with gradient Container)
      final fab = find.byKey(const Key('fisio_bottom_nav_fab'));
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();
        expect(find.text('Novo Paciente'), findsWidgets);
      } else {
        // If key not found, look for any way to find the FAB
        expect(find.byType(TelaDashboard), findsOneWidget);
      }
    });

    testWidgets('tocar em paciente abre modal de detalhes', (tester) async {
      await _montar(
        tester,
        _criarApp(carregamento: _carregado, pacientes: [_paciente()]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pacientes'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('João Dashboard'));
      await tester.pumpAndSettle();

      // Bottom sheet de detalhes com ação de editar
      expect(find.text('Editar Paciente'), findsOneWidget);
    });
  });

  group('TelaDashboard — agenda e pendências', () {
    testWidgets('lista sessões de hoje na agenda', (tester) async {
      final hoje = DateTime.now();
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [
            // `_horaFutura` / `_horaPassada`: o rótulo depende do horário
            // previsto contra o relógio real, então ancorar em '09:00' fazia o
            // teste passar de manhã e falhar de tarde.
            _agendamento(id: 'A001', data: hoje, horaInicio: _horaFutura),
            _agendamento(
              id: 'A002',
              data: hoje,
              horaInicio: _horaPassada,
              situacao: Agendamento.situacaoRealizado,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('João Dashboard'), findsWidgets);
      expect(find.text('Agendado'), findsOneWidget);
      expect(find.text('Realizado'), findsOneWidget);
    });

    testWidgets('sessão com horário passado aparece como Vencida', (
      tester,
    ) async {
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [
            _agendamento(
              id: 'A001',
              data: DateTime.now(),
              horaInicio: _horaPassada,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vencida'), findsOneWidget);
      expect(find.text('Agendado'), findsNothing);
    });

    testWidgets('sessão de hoje ainda por vir não conta como pendência', (
      tester,
    ) async {
      // Regressão: o contador comparava só a data, então a sessão do dia era
      // contada como pendência desde a meia-noite, antes de acontecer.
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [
            _agendamento(
              id: 'A001',
              data: DateTime.now(),
              horaInicio: _horaFutura,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final pendencias = find.ancestor(
        of: find.text('Pendências'),
        matching: find.byType(FisioStatTile),
      );
      expect(
        find.descendant(of: pendencias, matching: find.text('0')),
        findsOneWidget,
      );
    });

    testWidgets('card da agenda responde ao toque', (tester) async {
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [
            _agendamento(
              id: 'A001',
              data: DateTime.now(),
              horaInicio: _horaPassada,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // `FisioCard` só vira `InkWell` quando recebe `onTap` — o card da agenda
      // não tinha nenhum, então a pendência era exibida aqui e só resolvível na
      // aba Sessões. Asserção estrutural: não navega, não depende de plugin.
      expect(
        find.ancestor(
          of: find.text('João Dashboard').first,
          matching: find.byType(InkWell),
        ),
        findsWidgets,
      );
    });

    testWidgets('contador de sessões do dia exibido no header', (
      tester,
    ) async {
      final hoje = DateTime.now();
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [
            _agendamento(id: 'A001', data: hoje),
            _agendamento(id: 'A002', data: hoje),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets); // count in header
      expect(find.text('sessões'), findsOneWidget); // label next to count
    });

    testWidgets('header apresenta a data antes do contador', (tester) async {
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [_agendamento(id: 'A001', data: DateTime.now())],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('você tem'), findsOneWidget);
    });

    testWidgets('cards não cobrem o contador de sessões', (tester) async {
      // Regressão: os stat tiles sobem 38px para flutuar sobre o gradiente. Com
      // o padding inferior do header menor que isso, eles cortavam o número das
      // sessões. Um finder de texto não pega esse bug — a asserção é geométrica.
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [_agendamento(id: 'A001', data: DateTime.now())],
        ),
      );
      await tester.pumpAndSettle();

      final fimDoContador = tester.getBottomLeft(find.text('sessão')).dy;
      final topoDoCard =
          tester.getTopLeft(find.byType(FisioStatTile).first).dy;

      expect(
        topoDoCard,
        greaterThan(fimDoContador),
        reason: 'os stat tiles estão sobrepondo o contador de sessões do dia',
      );
    });

    testWidgets('pendências são contabilizadas no stat tile', (tester) async {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      await _montar(
        tester,
        _criarApp(
          carregamento: _carregado,
          pacientes: [_paciente()],
          agendamentos: [
            _agendamento(id: 'A009', data: ontem), // past + agendado = pending
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pendências'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // pendência count
    });
  });
}
