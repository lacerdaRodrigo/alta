import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alta/servicos/preferencias.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preferencias', () {
    test('lerPlanilhaId retorna null quando não há valor salvo', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await Preferencias.lerPlanilhaId(), isNull);
    });

    test('lerPlanilhaId retorna o valor previamente armazenado', () async {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ABC123'});
      expect(await Preferencias.lerPlanilhaId(), 'ABC123');
    });

    test('salvarPlanilhaId persiste o valor', () async {
      SharedPreferences.setMockInitialValues({});
      await Preferencias.salvarPlanilhaId('XYZ789');
      expect(await Preferencias.lerPlanilhaId(), 'XYZ789');
    });

    test('limparPlanilhaId remove o valor armazenado', () async {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ABC123'});
      await Preferencias.limparPlanilhaId();
      expect(await Preferencias.lerPlanilhaId(), isNull);
    });

    test('salvar sobrescreve um valor existente', () async {
      SharedPreferences.setMockInitialValues({'planilha_id': 'ANTIGO'});
      await Preferencias.salvarPlanilhaId('NOVO');
      expect(await Preferencias.lerPlanilhaId(), 'NOVO');
    });
  });
}
