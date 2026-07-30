import 'package:alta/servicos/servico_google_drive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auxiliares/servidor_google_fake.dart';

void main() {
  late ServidorGoogleFake servidor;

  setUp(() => servidor = ServidorGoogleFake());

  ServicoGoogleDrive criarServico() => ServicoGoogleDrive(servidor.cliente);

  group('ServicoGoogleDrive', () {
    test('busca pelo nome exato da base, não por "contains"', () async {
      await criarServico().buscarPlanilhasBanco();

      final q = servidor.chamadas.single.url.queryParameters['q']!;
      expect(q, contains("name = '__saas_fisio_db__'"));
      expect(q, isNot(contains('contains')));
      expect(q, contains('trashed=false'));
      expect(
        q,
        contains("mimeType='application/vnd.google-apps.spreadsheet'"),
      );
    });

    test('pede a lista ordenada da mais recente para a mais antiga', () async {
      await criarServico().buscarPlanilhasBanco();

      final parametros = servidor.chamadas.single.url.queryParameters;
      expect(parametros['orderBy'], 'modifiedTime desc');
    });

    test('converte os arquivos preservando id, nome e data', () async {
      servidor.arquivosDrive = [
        {
          'id': 'ID_RECENTE',
          'name': '__saas_fisio_db__',
          'modifiedTime': '2026-07-20T10:00:00.000Z',
        },
      ];

      final planilhas = await criarServico().buscarPlanilhasBanco();

      expect(planilhas, hasLength(1));
      expect(planilhas.first.id, 'ID_RECENTE');
      expect(planilhas.first.nome, '__saas_fisio_db__');
      expect(planilhas.first.modificadaEm, DateTime.utc(2026, 7, 20, 10));
    });

    test('descarta arquivos sem id — não dá para abrir uma planilha assim', () async {
      servidor.arquivosDrive = [
        {'name': '__saas_fisio_db__'},
        {'id': 'ID_VALIDO', 'name': '__saas_fisio_db__'},
      ];

      final planilhas = await criarServico().buscarPlanilhasBanco();

      expect(planilhas.map((p) => p.id), ['ID_VALIDO']);
    });

    test('buscarPlanilhaBanco devolve null quando não há nenhuma', () async {
      expect(await criarServico().buscarPlanilhaBanco(), isNull);
    });

    test('buscarPlanilhaBanco devolve a primeira (mais recente)', () async {
      servidor.arquivosDrive = [
        {'id': 'RECENTE', 'name': '__saas_fisio_db__'},
        {'id': 'ANTIGA', 'name': '__saas_fisio_db__'},
      ];

      expect(await criarServico().buscarPlanilhaBanco(), 'RECENTE');
    });
  });
}
