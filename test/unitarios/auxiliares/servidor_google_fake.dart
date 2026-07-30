import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Uma chamada HTTP que o app fez ao Google, já com o corpo decodificado.
class ChamadaGoogle {
  final String metodo;
  final Uri url;
  final Map<String, dynamic> corpo;

  const ChamadaGoogle({
    required this.metodo,
    required this.url,
    required this.corpo,
  });

  /// Valores da primeira linha enviada em `values.append` / `values.update`.
  List<String> get valoresEnviados {
    final values = (corpo['values'] as List?) ?? const [];
    if (values.isEmpty) return const [];
    return [for (final valor in values.first as List) valor.toString()];
  }

  @override
  String toString() => '$metodo ${url.path}';
}

/// Google Sheets e Drive de mentira, no nível do HTTP.
///
/// Os serviços do app instanciam `DriveApi`/`SheetsApi` diretamente a partir de
/// um `http.Client`, então trocar o cliente é o único ponto de injeção que
/// existe — e tem a vantagem de exercitar a montagem real das requisições
/// (query do Drive, range das abas, ordem dos valores), que é justamente onde
/// os bugs desta camada apareceram.
class ServidorGoogleFake {
  /// Arquivos devolvidos por `files.list`, na ordem.
  List<Map<String, String>> arquivosDrive;

  /// Conteúdo de cada aba (sem cabeçalho), como vem de `values.get`.
  Map<String, List<List<String>>> abas;

  /// Versão de esquema gravada na aba `Versao`. `null` simula a aba ausente.
  int? versaoEsquema;

  /// Abas presentes na planilha, para `spreadsheets.get`.
  List<String> abasExistentes;

  /// ID devolvido por `spreadsheets.create`.
  String idPlanilhaCriada;

  /// Ranges de `values.update` que devem falhar (ex.: `Versao!A1:B1`).
  Set<String> rangesQueFalham;

  final List<ChamadaGoogle> chamadas = [];

  ServidorGoogleFake({
    this.arquivosDrive = const [],
    Map<String, List<List<String>>>? abas,
    this.versaoEsquema = 1,
    this.abasExistentes = const [
      'Pacientes',
      'Agenda',
      'Evolucoes',
      'Configuracoes',
      'Auditoria',
      'Versao',
    ],
    this.idPlanilhaCriada = 'PLANILHA_NOVA',
    Set<String>? rangesQueFalham,
  }) : abas = abas ?? {},
       rangesQueFalham = rangesQueFalham ?? {};

  http.Client get cliente => MockClient(_tratar);

  /// Chamadas feitas ao Drive (útil para afirmar que o app **não** buscou).
  Iterable<ChamadaGoogle> get chamadasDrive =>
      chamadas.where((c) => c.url.path.startsWith('/drive/'));

  /// Tudo que não é leitura — para afirmar que nada foi gravado.
  Iterable<ChamadaGoogle> get escritas =>
      chamadas.where((c) => c.metodo != 'GET');

  Iterable<ChamadaGoogle> chamadasPara(String trechoDaUrl) =>
      chamadas.where((c) => Uri.decodeFull(c.url.path).contains(trechoDaUrl));

  Future<http.Response> _tratar(http.Request requisicao) async {
    final url = requisicao.url;
    final corpo = requisicao.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(requisicao.body) as Map<String, dynamic>;
    chamadas.add(
      ChamadaGoogle(metodo: requisicao.method, url: url, corpo: corpo),
    );

    final caminho = Uri.decodeFull(url.path);

    if (caminho.startsWith('/drive/v3/files')) {
      return _json({'files': arquivosDrive});
    }

    if (caminho.contains('/values/')) {
      final range = caminho.split('/values/').last.split(':append').first;
      if (requisicao.method == 'GET') {
        return _json({'values': _valoresDoRange(range)});
      }
      if (rangesQueFalham.contains(range)) {
        return http.Response('{"error":{"code":400}}', 400);
      }
      return _json({});
    }

    if (caminho.endsWith(':batchUpdate')) {
      return _json({});
    }

    if (requisicao.method == 'POST' && caminho.endsWith('/v4/spreadsheets')) {
      return _json({'spreadsheetId': idPlanilhaCriada});
    }

    // spreadsheets.get
    return _json({
      'sheets': [
        for (final aba in abasExistentes)
          {
            'properties': {'title': aba},
          },
      ],
    });
  }

  List<List<String>>? _valoresDoRange(String range) {
    if (range.startsWith('Versao!')) {
      return versaoEsquema == null
          ? null
          : [
              ['$versaoEsquema'],
            ];
    }
    return abas[range.split('!').first] ?? const [];
  }

  http.Response _json(Object corpo) => http.Response(
    jsonEncode(corpo),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
