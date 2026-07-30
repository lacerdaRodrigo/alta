import 'package:alta/servicos/servico_google_sheets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auxiliares/servidor_google_fake.dart';

void main() {
  late ServidorGoogleFake servidor;

  setUp(() => servidor = ServidorGoogleFake());

  ServicoGoogleSheets criarServico() => ServicoGoogleSheets(servidor.cliente);

  group('ServicoGoogleSheets — leitura', () {
    test('lerAba descarta linhas totalmente vazias da planilha', () async {
      servidor.abas = {
        'Pacientes': [
          ['P001', 'Ana'],
          ['', '  '],
          ['P002', 'Bruno'],
        ],
      };

      final linhas = await criarServico().lerAba('ID', 'Pacientes');

      expect(linhas, [
        ['P001', 'Ana'],
        ['P002', 'Bruno'],
      ]);
    });

    test('lerAba pede o intervalo a partir da segunda linha (pula cabeçalho)', () async {
      await criarServico().lerAba('ID', 'Agenda');

      expect(
        Uri.decodeFull(servidor.chamadas.single.url.path),
        endsWith('/values/Agenda!A2:Z'),
      );
    });
  });

  group('ServicoGoogleSheets — versão do esquema', () {
    test('lê o número dentro da linha, não a linha inteira', () async {
      // Regressão: `valores[0].toString()` dava "[2]", o parse falhava e o
      // serviço respondia 1 — uma planilha de versão futura passava batido.
      servidor.versaoEsquema = 2;

      expect(await criarServico().lerVersaoEsquema('ID'), 2);
    });

    test('assume versão 1 quando a aba Versao está vazia', () async {
      servidor.versaoEsquema = null;

      expect(await criarServico().lerVersaoEsquema('ID'), 1);
    });

    test('validarVersao aceita a versão suportada', () async {
      servidor.versaoEsquema = 1;

      await expectLater(criarServico().validarVersao('ID'), completes);
    });

    test('validarVersao recusa planilha de versão futura', () async {
      servidor.versaoEsquema = 2;

      expect(
        () => criarServico().validarVersao('ID'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ServicoGoogleSheets — escrita', () {
    test('criarPlanilhaBanco cria todas as abas, inclusive Versao', () async {
      final id = await criarServico().criarPlanilhaBanco();

      expect(id, 'PLANILHA_NOVA');
      final criacao = servidor.chamadas.first;
      final titulos = [
        for (final aba in criacao.corpo['sheets'] as List)
          (aba as Map)['properties']['title'] as String,
      ];
      // A aba Versao precisa nascer junto: `salvarVersaoEsquema` escreve nela
      // logo em seguida e a Sheets API devolve 400 se ela não existir.
      expect(titulos, contains('Versao'));
      expect(titulos, containsAll(ServicoGoogleSheets.cabecalhos.keys));
    });

    test('criarPlanilhaBanco grava os cabeçalhos de cada aba', () async {
      await criarServico().criarPlanilhaBanco();

      final cabecalhoPacientes = servidor
          .chamadasPara('/values/Pacientes!A1:S1')
          .single;
      expect(
        cabecalhoPacientes.valoresEnviados,
        ServicoGoogleSheets.cabecalhos['Pacientes'],
      );
      expect(servidor.chamadasPara('/values/Agenda!A1:I1'), hasLength(1));
    });

    test('garantirEstrutura cria só as abas que faltam', () async {
      servidor.abasExistentes = ['Pacientes', 'Agenda'];

      await criarServico().garantirEstrutura('ID');

      final batch = servidor.chamadasPara(':batchUpdate').single;
      final titulos = [
        for (final req in batch.corpo['requests'] as List)
          (req as Map)['addSheet']['properties']['title'] as String,
      ];
      expect(titulos, ['Evolucoes', 'Configuracoes', 'Auditoria']);
    });

    test('inserirLinha manda append com USER_ENTERED', () async {
      await criarServico().inserirLinha('ID', 'Auditoria', ['L1', 'hoje']);

      final chamada = servidor.chamadasPara('/values/Auditoria!A:Z').single;
      expect(chamada.metodo, 'POST');
      expect(chamada.valoresEnviados, ['L1', 'hoje']);
      expect(chamada.url.queryParameters['valueInputOption'], 'USER_ENTERED');
    });
  });
}
