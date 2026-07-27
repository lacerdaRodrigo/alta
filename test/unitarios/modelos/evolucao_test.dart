import 'package:flutter_test/flutter_test.dart';
import 'package:alta/modelos/evolucao.dart';

void main() {
  group('Evolucao', () {
    late DateTime dataBase;
    late DateTime horarioInicio;
    late DateTime horarioFim;
    late Evolucao evolucao;

    setUp(() {
      dataBase = DateTime(2026, 6, 9);
      horarioInicio = DateTime(2026, 6, 9, 14, 5);
      horarioFim = DateTime(2026, 6, 9, 15, 0);

      evolucao = Evolucao(
        idEvolucao: 'E001',
        idPaciente: 'P001',
        idAgendamento: 'A001',
        dataAtendimento: dataBase,
        evolucaoTexto: 'Realizado alongamento de cadeia posterior e fortalecimento de core.',
        localAtendimento: 'Domicílio',
        statusPresenca: 'Presente',
        dorSessao: 5,
        horarioInicioReal: horarioInicio,
        horarioFimReal: horarioFim,
        condicaoPaciente: 'Melhora',
        pressaoArterial: '120/80',
        frequenciaCardiaca: 72,
      );
    });

    test('deve criar com valores padrão quando não especificados', () {
      final padrao = Evolucao(
        idEvolucao: 'E002',
        idPaciente: 'P001',
        idAgendamento: 'A002',
        dataAtendimento: dataBase,
        evolucaoTexto: 'Teste',
        horarioInicioReal: horarioInicio,
        horarioFimReal: horarioFim,
      );

      expect(padrao.localAtendimento, equals('Domicílio'));
      expect(padrao.statusPresenca, equals('Presente'));
      expect(padrao.dorSessao, equals(0));
      expect(padrao.condicaoPaciente, equals('Melhora'));
      expect(padrao.pressaoArterial, isNull);
      expect(padrao.frequenciaCardiaca, isNull);
    });

    test('paraMapaPlanilha deve conter todas as chaves esperadas', () {
      final mapa = evolucao.paraMapaPlanilha();

      expect(mapa['ID_Evolucao'], equals('E001'));
      expect(mapa['ID_Paciente'], equals('P001'));
      expect(mapa['ID_Agendamento'], equals('A001'));
      expect(mapa['Data_Atendimento'], equals('09/06/2026'));
      expect(mapa['Evolucao_Texto'], contains('alongamento'));
      expect(mapa['Local_Atendimento'], equals('Domicílio'));
      expect(mapa['Status_Presenca'], equals('Presente'));
      expect(mapa['Dor_Sessao'], equals('5'));
      expect(mapa['Horario_Inicio_Real'], equals('14:05'));
      expect(mapa['Horario_Fim_Real'], equals('15:00'));
      expect(mapa['Condicao_Paciente'], equals('Melhora'));
      expect(mapa['Pressao_Arterial'], equals('120/80'));
      expect(mapa['Frequencia_Cardiaca'], equals('72'));
    });

    test('deLinhaPlanilha deve criar Evolucao a partir de linha completa', () {
      final linha = [
        'E003',
        'P002',
        'A003',
        '10/06/2026',
        'Paciente apresentou melhora significativa.',
        '2026-06-10T15:30:00.000',
        'Clínica',
        'Presente',
        '7',
        '14:10',
        '15:05',
        'Melhora',
        '130/85',
        '78',
      ];

      final result = Evolucao.deLinhaPlanilha(linha);

      expect(result.idEvolucao, equals('E003'));
      expect(result.idPaciente, equals('P002'));
      expect(result.idAgendamento, equals('A003'));
      expect(result.evolucaoTexto, contains('melhora'));
      expect(result.localAtendimento, equals('Clínica'));
      expect(result.statusPresenca, equals('Presente'));
      expect(result.dorSessao, equals(7));
      expect(result.horarioInicioReal.hour, equals(14));
      expect(result.horarioInicioReal.minute, equals(10));
      expect(result.horarioFimReal.hour, equals(15));
      expect(result.horarioFimReal.minute, equals(5));
      expect(result.condicaoPaciente, equals('Melhora'));
      expect(result.pressaoArterial, equals('130/85'));
      expect(result.frequenciaCardiaca, equals(78));
    });

    test('deLinhaPlanilha deve preservar retrocompatibilidade com linhas antigas (6 colunas)', () {
      final linha = [
        'E004',
        'P003',
        'A004',
        '15/03/2024',
        'Evolução antiga sem dados extras.',
        '2024-03-15T10:00:00.000',
      ];

      final result = Evolucao.deLinhaPlanilha(linha);

      expect(result.idEvolucao, equals('E004'));
      expect(result.evolucaoTexto, equals('Evolução antiga sem dados extras.'));
      expect(result.localAtendimento, equals('Domicílio')); // Padrão
      expect(result.statusPresenca, equals('Presente')); // Padrão
      expect(result.dorSessao, equals(0)); // Padrão
      expect(result.condicaoPaciente, equals('Melhora')); // Padrão
      expect(result.pressaoArterial, isNull);
      expect(result.frequenciaCardiaca, isNull);
    });

    test('deLinhaPlanilha deve lidar com linhas de tamanho intermediário (12 colunas)', () {
      final linha = [
        'E005',
        'P004',
        'A005',
        '20/06/2026',
        'Paciente faltou.',
        '2026-06-20T09:00:00.000',
        'Domicílio',
        'Ausente sem aviso',
        '',
        '',
        '',
        'Faltou',
      ];

      final result = Evolucao.deLinhaPlanilha(linha);

      expect(result.localAtendimento, equals('Domicílio'));
      expect(result.statusPresenca, equals('Ausente sem aviso'));
      expect(result.dorSessao, equals(0));
      expect(result.condicaoPaciente, equals('Faltou'));
      expect(result.pressaoArterial, isNull);
      expect(result.frequenciaCardiaca, isNull);
    });

    test('paraMapaPlanilha deve retornar campos opcionais vazios quando nulos', () {
      final semOpcionais = Evolucao(
        idEvolucao: 'E006',
        idPaciente: 'P001',
        idAgendamento: 'A006',
        dataAtendimento: dataBase,
        evolucaoTexto: 'Teste',
        horarioInicioReal: horarioInicio,
        horarioFimReal: horarioFim,
      );

      final mapa = semOpcionais.paraMapaPlanilha();
      expect(mapa['Pressao_Arterial'], equals(''));
      expect(mapa['Frequencia_Cardiaca'], equals(''));
    });
  });
}
