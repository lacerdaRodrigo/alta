import 'package:alta/modelos/agendamento.dart';
import 'package:alta/modelos/evolucao.dart';
import 'package:alta/modelos/paciente.dart';
import 'package:alta/servicos/preferencias.dart';
import 'package:alta/servicos/servico_repositorio_dados.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auxiliares/servidor_google_fake.dart';

Paciente _paciente() => Paciente(
  idPaciente: 'P001',
  nome: 'Ana Souza',
  telefone: '11999999999',
  dataNascimento: DateTime(1990, 5, 20),
  cpf: '12345678901',
  endereco: 'Rua A, 10',
  situacao: 'Ativo',
);

Agendamento _agendamento() => Agendamento(
  idAgendamento: 'A001',
  idPaciente: 'P001',
  data: DateTime(2026, 7, 20),
  horaInicio: '08:00',
  horaFim: '09:00',
  valorSessao: 150,
  situacao: Agendamento.situacaoAgendado,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServidorGoogleFake servidor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    servidor = ServidorGoogleFake();
  });

  RepositorioDadosGoogle criarRepositorio() =>
      RepositorioDadosGoogle(servidor.cliente);

  group('RepositorioDadosGoogle — obterPlanilhaId', () {
    test('usa o ID salvo nas preferências sem consultar o Drive', () async {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ID_SALVO'});

      final id = await criarRepositorio().obterPlanilhaId();

      expect(id, 'ID_SALVO');
      expect(servidor.chamadasDrive, isEmpty);
    });

    test('descarta o ID salvo quando a planilha tem versão incompatível', () async {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ID_ANTIGO'});
      servidor.versaoEsquema = 2;
      servidor.arquivosDrive = [
        {'id': 'ID_DO_DRIVE', 'name': '__saas_fisio_db__'},
      ];

      // A busca no Drive acha outra planilha, mas ela também é versão 2 —
      // o importante é que o ID inválido saiu das preferências.
      await expectLater(
        criarRepositorio().obterPlanilhaId(),
        throwsA(isA<StateError>()),
      );
      expect(await Preferencias.lerPlanilhaId(), isNull);
      expect(servidor.chamadasDrive, isNotEmpty);
    });

    test('adota a planilha existente no Drive e a persiste', () async {
      servidor.arquivosDrive = [
        {'id': 'ID_EXISTENTE', 'name': '__saas_fisio_db__'},
      ];

      final id = await criarRepositorio().obterPlanilhaId();

      expect(id, 'ID_EXISTENTE');
      expect(await Preferencias.lerPlanilhaId(), 'ID_EXISTENTE');
    });

    test('cria uma planilha quando não existe nenhuma', () async {
      final id = await criarRepositorio().obterPlanilhaId();

      expect(id, 'PLANILHA_NOVA');
      expect(await Preferencias.lerPlanilhaId(), 'PLANILHA_NOVA');
      expect(servidor.chamadasPara('/values/Versao!A1:B1'), hasLength(1));
    });

    test('persiste o ID mesmo se gravar a versão falhar', () async {
      // Regressão: a falha ao escrever na aba Versao deixava o ID sem salvar,
      // e a tentativa seguinte criava **outra** planilha em vez de reaproveitar
      // a que acabou de nascer.
      servidor.rangesQueFalham = {'Versao!A1:B1'};

      await expectLater(
        criarRepositorio().obterPlanilhaId(),
        throwsA(anything),
      );
      expect(await Preferencias.lerPlanilhaId(), 'PLANILHA_NOVA');
    });

    test('reutiliza o ID em memória sem buscar de novo no Drive', () async {
      servidor.arquivosDrive = [
        {'id': 'ID_EXISTENTE', 'name': '__saas_fisio_db__'},
      ];
      final repositorio = criarRepositorio();

      await repositorio.obterPlanilhaId();
      final chamadasApos1a = servidor.chamadasDrive.length;
      await repositorio.obterPlanilhaId();

      expect(servidor.chamadasDrive.length, chamadasApos1a);
    });

    test('limparCache apaga o ID persistido', () async {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ID_SALVO'});
      final repositorio = criarRepositorio();
      await repositorio.obterPlanilhaId();

      repositorio.limparCache();
      await Future<void>.delayed(Duration.zero);

      expect(await Preferencias.lerPlanilhaId(), isNull);
    });
  });

  group('RepositorioDadosGoogle — planilhas duplicadas', () {
    test('usa a mais recente e reporta as demais', () async {
      servidor.arquivosDrive = [
        {'id': 'RECENTE', 'name': '__saas_fisio_db__'},
        {'id': 'ANTIGA', 'name': '__saas_fisio_db__'},
      ];
      final repositorio = criarRepositorio();

      final id = await repositorio.obterPlanilhaId();

      expect(id, 'RECENTE');
      expect(repositorio.planilhasDuplicadas.map((p) => p.id), ['ANTIGA']);
    });

    test('não reporta duplicata quando só existe uma planilha', () async {
      servidor.arquivosDrive = [
        {'id': 'UNICA', 'name': '__saas_fisio_db__'},
      ];
      final repositorio = criarRepositorio();

      await repositorio.obterPlanilhaId();

      expect(repositorio.planilhasDuplicadas, isEmpty);
    });

    test('carregarTudo propaga as duplicatas para a UI', () async {
      servidor.arquivosDrive = [
        {'id': 'RECENTE', 'name': '__saas_fisio_db__'},
        {'id': 'ANTIGA', 'name': '__saas_fisio_db__'},
      ];

      final dados = await criarRepositorio().carregarTudo();

      expect(dados.planilhaId, 'RECENTE');
      expect(dados.planilhasDuplicadas.map((p) => p.id), ['ANTIGA']);
    });
  });

  group('RepositorioDadosGoogle — carregarTudo', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ID'});
    });

    test('converte linhas curtas sem estourar índice', () async {
      // A planilha devolve só as colunas preenchidas: um paciente cadastrado
      // sem anamnese chega com 6 células, não com 19.
      servidor.abas = {
        'Pacientes': [
          ['P001', 'Ana Souza', '11999999999', '20/05/1990', '123', 'Rua A'],
        ],
      };

      final dados = await criarRepositorio().carregarTudo();

      final paciente = dados.pacientes.single;
      expect(paciente.nome, 'Ana Souza');
      expect(paciente.dataNascimento, DateTime(1990, 5, 20));
      expect(paciente.queixaPrincipal, isNull);
      // Coluna vazia não pode virar paciente arquivado.
      expect(paciente.situacao, 'Ativo');
    });

    test('lê o valor da sessão com vírgula decimal', () async {
      servidor.abas = {
        'Agenda': [
          ['A001', 'P001', '20/07/2026', '08:00', '09:00', '150,50'],
        ],
      };

      final dados = await criarRepositorio().carregarTudo();

      expect(dados.agendamentos.single.valorSessao, 150.5);
      expect(dados.agendamentos.single.situacao, 'Agendado');
    });

    test('carrega evoluções pela mesma regra do modelo', () async {
      servidor.abas = {
        'Evolucoes': [
          ['E001', 'P001', 'A001', '20/07/2026', 'Texto clínico'],
        ],
      };

      final dados = await criarRepositorio().carregarTudo();

      expect(dados.evolucoes.single.idEvolucao, 'E001');
      expect(dados.evolucoes.single.evolucaoTexto, 'Texto clínico');
    });

    test('usa o valor padrão da sessão vindo de Configuracoes', () async {
      servidor.abas = {
        'Configuracoes': [
          ['valor_sessao_padrao', '220,00'],
        ],
      };

      final dados = await criarRepositorio().carregarTudo();

      expect(dados.valorSessaoPadrao, '220,00');
    });

    test('cai em 150,00 quando a configuração não existe', () async {
      final dados = await criarRepositorio().carregarTudo();

      expect(dados.valorSessaoPadrao, '150,00');
    });

    test('mostra os logs de auditoria do mais recente para o mais antigo', () async {
      servidor.abas = {
        'Auditoria': [
          ['L1', '01/07/2026 10:00', 'CADASTRO_PACIENTE', 'Primeiro'],
          ['L2', '02/07/2026 10:00', 'EDITAR_PACIENTE', 'Segundo'],
        ],
      };

      final dados = await criarRepositorio().carregarTudo();

      expect(dados.logsAuditoria.first, contains('Segundo'));
      expect(dados.logsAuditoria.last, contains('Primeiro'));
    });
  });

  group('RepositorioDadosGoogle — escrita', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ID'});
    });

    test('salvarPaciente grava as 19 colunas na ordem do cabeçalho', () async {
      await criarRepositorio().salvarPaciente(_paciente());

      final append = servidor.chamadasPara('/values/Pacientes!A:Z').single;
      expect(append.valoresEnviados, hasLength(19));
      expect(append.valoresEnviados[0], 'P001');
      expect(append.valoresEnviados[1], 'Ana Souza');
      expect(append.valoresEnviados[4], '12345678901');
    });

    test('salvarPaciente registra auditoria da operação', () async {
      await criarRepositorio().salvarPaciente(_paciente());

      final auditoria = servidor.chamadasPara('/values/Auditoria!A:Z').single;
      expect(auditoria.valoresEnviados[2], 'CADASTRO_PACIENTE');
      expect(auditoria.valoresEnviados[3], contains('P001'));
    });

    test('registrarAuditoria gera o próximo ID a partir do maior existente', () async {
      // `length + 1` daria L3 e sobrescreveria a linha existente.
      servidor.abas = {
        'Auditoria': [
          ['L7', '01/07/2026 10:00', 'X', 'y'],
          ['L2', '01/07/2026 11:00', 'X', 'y'],
        ],
      };

      await criarRepositorio().registrarAuditoria('TESTE', 'detalhe');

      final auditoria = servidor.chamadasPara('/values/Auditoria!A:Z').single;
      expect(auditoria.valoresEnviados.first, 'L008');
    });

    test('atualizarSituacaoAgendamento troca só a coluna Situacao', () async {
      servidor.abas = {
        'Agenda': [
          ['A001', 'P001', '20/07/2026', '08:00', '09:00', '150,00', 'obs',
            'Agendado', '2026-07-01T10:00:00.000'],
          ['A002', 'P002', '21/07/2026', '10:00', '11:00', '150,00', '',
            'Agendado', '2026-07-01T10:00:00.000'],
        ],
      };

      await criarRepositorio().atualizarSituacaoAgendamento(
        'A002',
        Agendamento.situacaoRealizado,
      );

      // Segunda linha de dados = linha 3 da planilha (cabeçalho ocupa a 1).
      final update = servidor.chamadasPara('/values/Agenda!A3:I3').single;
      expect(update.metodo, 'PUT');
      expect(update.valoresEnviados[7], 'Realizado');
      expect(update.valoresEnviados[0], 'A002');
      expect(update.valoresEnviados[2], '21/07/2026');
    });

    test('atualizarSituacaoAgendamento ignora ID inexistente', () async {
      servidor.abas = {'Agenda': []};

      await criarRepositorio().atualizarSituacaoAgendamento(
        'INEXISTENTE',
        Agendamento.situacaoRealizado,
      );

      expect(servidor.escritas, isEmpty);
    });

    test('arquivarPaciente marca a situação preservando o resto da linha', () async {
      servidor.abas = {
        'Pacientes': [
          ['P001', 'Ana Souza', '11999999999', '20/05/1990', '123', 'Rua A'],
        ],
      };

      await criarRepositorio().arquivarPaciente('P001');

      final update = servidor.chamadasPara('/values/Pacientes!A2:S2').single;
      expect(update.valoresEnviados[10], 'Arquivado');
      expect(update.valoresEnviados[1], 'Ana Souza');
      expect(update.valoresEnviados, hasLength(19));
    });

    test('restaurarPaciente devolve a situação para Ativo', () async {
      servidor.abas = {
        'Pacientes': [
          ['P001', 'Ana Souza', '11999999999', '20/05/1990', '123', 'Rua A',
            '', '', '', '', 'Arquivado'],
        ],
      };

      await criarRepositorio().restaurarPaciente('P001');

      final update = servidor.chamadasPara('/values/Pacientes!A2:S2').single;
      expect(update.valoresEnviados[10], 'Ativo');
    });

    test('atualizarPaciente falha alto quando o paciente sumiu da planilha', () async {
      servidor.abas = {'Pacientes': []};

      expect(
        () => criarRepositorio().atualizarPaciente(_paciente()),
        throwsA(isA<StateError>()),
      );
    });

    test('atualizarEvolucao não escreve nada se o ID não existe', () async {
      servidor.abas = {'Evolucoes': []};

      await criarRepositorio().atualizarEvolucao(
        Evolucao(
          idEvolucao: 'E999',
          idPaciente: 'P001',
          idAgendamento: 'A001',
          dataAtendimento: DateTime(2026, 7, 20),
          evolucaoTexto: 'x',
          dataRegistro: DateTime(2026, 7, 20),
          horarioInicioReal: DateTime(2026, 7, 20, 8),
          horarioFimReal: DateTime(2026, 7, 20, 9),
        ),
      );

      expect(servidor.escritas, isEmpty);
    });

    test('salvarValorSessaoPadrao insere a chave quando ela não existe', () async {
      servidor.abas = {'Configuracoes': []};

      await criarRepositorio().salvarValorSessaoPadrao('200,00');

      final append = servidor.chamadasPara('/values/Configuracoes!A:Z').single;
      expect(append.valoresEnviados, ['valor_sessao_padrao', '200,00']);
    });

    test('salvarValorSessaoPadrao atualiza a linha existente', () async {
      servidor.abas = {
        'Configuracoes': [
          ['valor_sessao_padrao', '150,00'],
        ],
      };

      await criarRepositorio().salvarValorSessaoPadrao('200,00');

      final update = servidor.chamadasPara('/values/Configuracoes!A2:B2').single;
      expect(update.valoresEnviados, ['valor_sessao_padrao', '200,00']);
    });

    test('salvarAgendamento grava as 9 colunas da Agenda', () async {
      await criarRepositorio().salvarAgendamento(_agendamento());

      final append = servidor.chamadasPara('/values/Agenda!A:Z').single;
      expect(append.valoresEnviados, hasLength(9));
      expect(append.valoresEnviados[0], 'A001');
      expect(append.valoresEnviados[2], '20/07/2026');
    });
  });

  group('RepositorioDadosGoogle — utilidades', () {
    test('urlPlanilha aponta para o documento no Drive', () {
      expect(
        criarRepositorio().urlPlanilha('ABC'),
        'https://docs.google.com/spreadsheets/d/ABC/edit',
      );
    });
  });
}
