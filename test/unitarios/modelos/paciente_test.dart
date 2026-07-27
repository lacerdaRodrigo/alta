import 'package:flutter_test/flutter_test.dart';
import 'package:alta/modelos/paciente.dart';

void main() {
  group('Paciente', () {
    late Paciente paciente;

    setUp(() {
      paciente = Paciente(
        idPaciente: 'P001',
        nome: 'Carlos Eduardo',
        telefone: '(11) 99999-9999',
        dataNascimento: DateTime(1986, 6, 4),
        cpf: '529.982.247-25',
        endereco: 'Rua das Flores, 123, São Paulo - SP',
        queixaPrincipal: 'Dor lombar crônica',
        histDoencaAtual: 'Dor há 6 meses, piora ao levantar',
        comorbidades: 'Hipertensão, diabetes tipo 2',
        medicamentos: 'Losartana, Metformina',
        alergias: 'Dipirona',
        cirurgias: 'Apendicectomia 2010',
        habitosVida: 'Sedentário, caminhada 1x/semana',
        situacao: 'Ativo',
      );
    });

test(
 'calcularIdade deve retornar 40 anos para nascido em 04/06/1986 na data 04/06/2026',
 () {
 expect(
 paciente.calcularIdade(dataReferencia: DateTime(2026, 6, 4)),
 equals(40),
 );
 },
);

test(
 'calcularIdade deve retornar 39 se o aniversário ainda não chegou',
 () {
 expect(
 paciente.calcularIdade(dataReferencia: DateTime(2026, 5, 1)),
 equals(39),
 );
 },
);

test('estaAtivo deve retornar verdadeiro quando situacao é Ativo', () {
 expect(paciente.estaAtivo, isTrue);
});

test('estaAtivo deve retornar falso quando situacao é Arquivado', () {
 final arquivado = paciente.copiarCom(situacao: 'Arquivado');
 expect(arquivado.estaAtivo, isFalse);
});

test(
 'copiarCom deve criar novo paciente com situacao alterada sem modificar o original',
 () {
 final arquivado = paciente.copiarCom(situacao: 'Arquivado');
 expect(arquivado.situacao, equals('Arquivado'));
 expect(paciente.situacao, equals('Ativo')); // Original inalterado
 expect(arquivado.nome, equals('Carlos Eduardo')); // Dados mantidos
 expect(arquivado.queixaPrincipal, equals('Dor lombar crônica')); // Anamnese mantida
 },
);

test('paraMapaPlanilha deve conter todas as chaves esperadas', () {
  final mapa = paciente.paraMapaPlanilha();
  expect(mapa.containsKey('ID_Paciente'), isTrue);
  expect(mapa.containsKey('Nome'), isTrue);
  expect(mapa.containsKey('CPF'), isTrue);
  expect(mapa.containsKey('Situacao'), isTrue);
  expect(mapa.containsKey('Queixa_Principal'), isTrue);
  expect(mapa.containsKey('Hist_Doenca_Atual'), isTrue);
  expect(mapa.containsKey('Comorbidades'), isTrue);
  expect(mapa.containsKey('Medicamentos'), isTrue);
  expect(mapa.containsKey('Alergias'), isTrue);
  expect(mapa.containsKey('Cirurgias'), isTrue);
  expect(mapa.containsKey('Habitos_Vida'), isTrue);
  expect(mapa['Nome'], equals('Carlos Eduardo'));
  expect(mapa['Data_Nascimento'], equals('04/06/1986'));
  expect(mapa['Queixa_Principal'], equals('Dor lombar crônica'));
  expect(mapa['Hist_Doenca_Atual'], equals('Dor há 6 meses, piora ao levantar'));
  expect(mapa['Comorbidades'], equals('Hipertensão, diabetes tipo 2'));
  expect(mapa['Medicamentos'], equals('Losartana, Metformina'));
  expect(mapa['Alergias'], equals('Dipirona'));
  expect(mapa['Cirurgias'], equals('Apendicectomia 2010'));
  expect(mapa['Habitos_Vida'], equals('Sedentário, caminhada 1x/semana'));
});

test(
  'deLinhaPlanilha deve criar Paciente corretamente a partir de uma linha com anamnese completa',
  () {
  final linha = [
    'P002',
    'Ana Paula',
    '(21) 98888-8888',
    '15/03/1996',
    '529.982.247-25',
    'Rua B, 456',
    'Dor no ombro direito', // Queixa Principal
    'Dor há 1 mês, piora com movimento', // HDA
    'Cirurgia no ombro em 2020', // Hist_Pregresso (legacy)
    'Fisioterapeuta', // Ocupação (legacy)
    'Ativo',
    '2026-06-04T10:00:00.000',
    'Feminino', // Genero
    '7', // Dor
    'Hipertensão', // Comorbidades
    'Losartana', // Medicamentos
    'Dipirona', // Alergias
    'Artroscopia 2020', // Cirurgias
    'Ativo, academia 3x/semana', // Habitos_Vida
  ];
  final novoPaciente = Paciente.deLinhaPlanilha(linha);
  expect(novoPaciente.nome, equals('Ana Paula'));
  expect(novoPaciente.dataNascimento, equals(DateTime(1996, 3, 15)));
  expect(novoPaciente.situacao, equals('Ativo'));
  expect(novoPaciente.queixaPrincipal, equals('Dor no ombro direito'));
  expect(novoPaciente.histDoencaAtual, equals('Dor há 1 mês, piora com movimento'));
  expect(novoPaciente.genero, equals('Feminino'));
  expect(novoPaciente.dor, equals('7'));
  expect(novoPaciente.comorbidades, equals('Hipertensão'));
  expect(novoPaciente.medicamentos, equals('Losartana'));
  expect(novoPaciente.alergias, equals('Dipirona'));
  expect(novoPaciente.cirurgias, equals('Artroscopia 2020'));
  expect(novoPaciente.habitosVida, equals('Ativo, academia 3x/semana'));
  });

test('Paciente criado sem campos de anamnese deve ter valores nulos no mapa', () {
  final pacienteSemAnamnese = Paciente(
    idPaciente: 'P003',
    nome: 'João Silva',
    telefone: '(31) 98765-4321',
    dataNascimento: DateTime(1990, 1, 1),
    cpf: '529.982.247-25',
    endereco: 'Rua C, 789',
    situacao: 'Ativo',
  );

  final mapa = pacienteSemAnamnese.paraMapaPlanilha();
  expect(mapa['Queixa_Principal'], isEmpty);
  expect(mapa['Hist_Doenca_Atual'], isEmpty);
  expect(mapa['Comorbidades'], isEmpty);
  expect(mapa['Medicamentos'], isEmpty);
  expect(mapa['Alergias'], isEmpty);
  expect(mapa['Cirurgias'], isEmpty);
  expect(mapa['Habitos_Vida'], isEmpty);
});

test('copiarCom deve preservar campos de anamnese quando não fornecidos', () {
  final copia = paciente.copiarCom(situacao: 'Arquivado');
  expect(copia.comorbidades, equals('Hipertensão, diabetes tipo 2')); // Preservado
  expect(copia.medicamentos, equals('Losartana, Metformina')); // Preservado
  expect(copia.alergias, equals('Dipirona')); // Preservado
  expect(copia.cirurgias, equals('Apendicectomia 2010')); // Preservado
  expect(copia.habitosVida, equals('Sedentário, caminhada 1x/semana')); // Preservado
  expect(copia.queixaPrincipal, equals('Dor lombar crônica')); // Preservado
  expect(copia.histDoencaAtual, equals('Dor há 6 meses, piora ao levantar')); // Preservado
  });
 });
}
