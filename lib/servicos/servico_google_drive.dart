import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Planilha candidata a ser a base do app, encontrada no Drive do usuário.
class PlanilhaBanco {
  final String id;
  final String nome;
  final DateTime? modificadaEm;

  const PlanilhaBanco({
    required this.id,
    required this.nome,
    this.modificadaEm,
  });
}

class ServicoGoogleDrive {
  static const nomeBanco = '__saas_fisio_db__';

  final drive.DriveApi _api;

  ServicoGoogleDrive(http.Client cliente) : _api = drive.DriveApi(cliente);

  /// Lista as planilhas do usuário cujo nome é **exatamente** [nomeBanco],
  /// da mais recente para a mais antiga.
  ///
  /// A busca era por `name contains`, o que trazia junto as cópias criadas pelo
  /// próprio Drive (`__saas_fisio_db__ (1)`, `Cópia de __saas_fisio_db__`).
  /// Como o resultado vinha ordenado por `modifiedTime` e o app pegava o
  /// primeiro, bastava abrir uma cópia para que os dados novos passassem a ser
  /// gravados nela — em silêncio. Nome exato elimina esse caso; quando ainda
  /// assim houver mais de uma, quem chama decide o que fazer (ver
  /// `RepositorioDadosGoogle.planilhasDuplicadas`).
  Future<List<PlanilhaBanco>> buscarPlanilhasBanco() async {
    final resultado = await _api.files.list(
      q:
          "name = '$nomeBanco' and "
          "mimeType='application/vnd.google-apps.spreadsheet' and "
          'trashed=false',
      spaces: 'drive',
      pageSize: 10,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );

    return [
      for (final arquivo in resultado.files ?? const <drive.File>[])
        if (arquivo.id != null)
          PlanilhaBanco(
            id: arquivo.id!,
            nome: arquivo.name ?? nomeBanco,
            modificadaEm: arquivo.modifiedTime,
          ),
    ];
  }

  /// A planilha mais recente com o nome da base, ou `null` se não houver
  /// nenhuma.
  Future<String?> buscarPlanilhaBanco() async {
    final planilhas = await buscarPlanilhasBanco();
    return planilhas.isEmpty ? null : planilhas.first.id;
  }
}
