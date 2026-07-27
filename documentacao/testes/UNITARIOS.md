# 📁 Testes Unitários (123 testes)

Lógica pura: validação de entrada, transformação de dados, cálculos.

---

## test/unitarios/utilitarios/ (93 testes)

### mensagens_erro_google_test.dart (7 testes)

Tradução de erros do Google Sign-In para mensagens acionáveis na UI.

```dart
✓ cancelamento explícito do serviço vira mensagem curta
✓ cancelamento do plugin vira mensagem curta
✓ app não registrado no OAuth não é tratado como cancelamento
✓ erro 10 aponta para o cliente OAuth, não para o Firebase
✓ erro 12500 orienta configurar o provedor Google
✓ permissão negada orienta a lista de usuários de teste
✓ erro desconhecido cai na mensagem genérica
```

**Por que existe:** o plugin classifica como `canceled` tanto a desistência do
usuário quanto o erro `[16] Account reauth failed`, que na verdade é o par
pacote + SHA-1 não registrado como cliente OAuth Android. Sem separar os dois, um
erro de configuração aparece como se o usuário tivesse fechado o login.

---

### validadores_test.dart (46 testes)

Valida entrada de usuário em toda a aplicação.

#### CPF (15 testes)
```dart
✓ Aceita CPF válido com formatação (111.444.777-35)
✓ Aceita CPF válido sem formatação (11144477735)
✓ Rejeita CPF com dígitos repetidos (111.111.111-11)
✓ Rejeita CPF com comprimento errado
✓ Rejeita CPF com dígito verificador inválido
✓ Rejeita CPF vazio
✓ Rejeita CPF com apenas pontos e hífens
✓ Retorna mensagem de erro para CPF inválido
✓ Retorna null para CPF válido
✓ Retorna mensagem específica para CPF vazio
```

#### Telefone (8 testes)
```dart
✓ Aceita telefone com 10 dígitos (11) 3333-4444
✓ Aceita telefone com 11 dígitos (11) 99999-9999
✓ Aceita telefone sem formatação com 10 dígitos
✓ Aceita telefone sem formatação com 11 dígitos
✓ Rejeita telefone com menos de 10 dígitos
✓ Rejeita telefone com mais de 11 dígitos
✓ Rejeita telefone começando com 0
✓ Rejeita DDD inválido (menor que 11)
```

#### Nome (6 testes)
```dart
✓ Aceita nome válido
✓ Rejeita nome vazio
✓ Rejeita nome com números
✓ Rejeita nome com caracteres especiais inválidos
✓ Valida comprimento mínimo
✓ Valida comprimento máximo
```

#### Data (8 testes)
```dart
✓ Rejeita data retroativa
✓ Aceita data futura
✓ Rejeita data vazia
✓ Valida data em formato correto
✓ Calcula dias até agendamento
✓ Evita agendamento no fim de semana (se aplicável)
```

#### Email (3 testes)
```dart
✓ Aceita email válido
✓ Rejeita email sem @
✓ Rejeita email incompleto
```

### validador_cpf_test.dart (9 testes)

Testes isolados da classe ValidadorCpf com casos extremos.

```dart
✓ Calcula dígito verificador correto
✓ Rejeita CPF com caracteres não-numéricos
✓ Trata underflow (strings muito curtas)
✓ Trata overflow (strings muito longas)
✓ Valida sequências de repetição
✓ Dígitos verificadores aplicados corretamente
```

### utilitarios_data_test.dart (23 testes)

Manipulação de datas e horários: idade, saudação, formatação, e os
comparadores usados pelos filtros de Sessões/Financeiro
(`mesmoDia`, `mesmoMesAno`, retroatividade).

```dart
// Idade
✓ Idade correta quando o aniversário já passou no ano
✓ Idade reduzida se o aniversário ainda não chegou no ano
✓ Idade correta no dia do aniversário
✓ Idade 0 para um bebê nascido no mesmo ano

// Data/hora retroativa
✓ Verdadeiro para data no passado
✓ Falso para data no futuro
✓ Mesmo dia mas 30 min no passado
✓ Mesmo dia, 1 minuto no passado é retroativo
✓ Mesmo dia, 1 minuto no futuro NÃO é retroativo
✓ Mesmo exato instante NÃO é retroativo
✓ Ontem qualquer hora é retroativo
✓ Amanhã 00:00 NÃO é retroativo

// Saudação por horário
✓ "Bom dia" entre 05h e 11h59
✓ "Boa tarde" entre 12h e 17h59
✓ "Boa noite" entre 18h e 04h59

// Formatação
✓ Formata data no padrão DD/MM/AAAA
✓ Preenche com zeros à esquerda (dia/mês de um dígito)
✓ Retorna mês abreviado e ano

// mesmoMesAno / mesmoDia
✓ Mesmo mês e ano retorna true
✓ Meses ou anos diferentes retorna false
✓ Mesmo dia meia-noite é retroativo se hora atual é posterior
✓ Mesmo dia com horários diferentes retorna true
✓ Dias diferentes retorna false
```

### gerador_id_test.dart (8 testes — 100% de cobertura)

Geração de IDs sequenciais (`A007`, `E012`, `L003`) a partir do maior número
existente — evita a race condition do antigo `length + 1`.

```dart
✓ Lista vazia gera o primeiro ID (A001)
✓ Incrementa a partir do maior número existente
✓ Usa o maior número mesmo com buracos na numeração (evita colisão)
✓ Ignora IDs com prefixo diferente
✓ Ignora sufixos não numéricos
✓ Ignora entradas vazias ou só com o prefixo
✓ Respeita a largura customizada de padding
✓ Não trunca números maiores que a largura
```

---

## test/unitarios/servicos/ (5 testes)

### preferencias_test.dart (5 testes)

Persistência local via SharedPreferences (ID da planilha).

```dart
✓ lerPlanilhaId retorna null quando não há valor salvo
✓ lerPlanilhaId retorna o valor previamente armazenado
✓ salvarPlanilhaId persiste o valor
✓ limparPlanilhaId remove o valor armazenado
✓ salvar sobrescreve um valor existente
```

---

## test/unitarios/modelos/ (25 testes)

Serialização, transformação e comportamento dos modelos de dados.

### paciente_test.dart (9 testes)

Modelo Paciente: dados cadastrais, anamnese, status.

```dart
✓ calcularIdade() retorna idade correta
✓ estaAtivo é true quando situacao = 'Ativo'
✓ estaAtivo é false quando situacao = 'Arquivado'
✓ copiarCom() mantém imutabilidade
✓ copiarCom() altera campos especificados
✓ paraMapaPlanilha() serializa corretamente
✓ Mapa contém todas as 19 colunas esperadas
✓ deLinhaPlanilha() desserializa linha corretamente
✓ Preserva anamnese na cópia
```

### agendamento_test.dart (10 testes)

Modelo Agendamento: sessões, desfechos, horários.

```dart
✓ estaAgendado retorna verdadeiro para situação Agendado
✓ copiarCom para Realizado atualiza a situação mantendo dados
✓ paraMapaPlanilha() contém todas as chaves da aba Agenda
✓ ehDeHoje considera apenas dia, mês e ano
✓ estaAtrasado considera horário previsto sem desfecho
✓ pendenteDeDiaAnterior ativa quando vira o dia
✓ copiarCom altera campos editáveis e preserva identidade
✓ copiarCom sem parâmetros mantém todos os campos iguais
✓ pendenteDeDiaAnterior não ativa no mesmo dia
✓ cancelamentos e faltas devem ser desfechos
```

### evolucao_test.dart (6 testes)

Modelo Evolução: registros clínicos, protocolos.

```dart
✓ Gera timestamp automático
✓ Protocolo: avaliação vs reavaliação
✓ Campos obrigatórios validados
✓ paraMapaPlanilha() com 14 colunas
✓ deLinhaPlanilha() desserializa corretamente
✓ Preserva texto clínico após cópia
```

---

## Cobertura de Lógica

| Componente | Cobertura | Detalhes |
|---|---|---|
| Validadores | ✅ 100% | CPF, telefone, nome, data, email |
| Cálculos | ✅ 100% | Idade, duração, datas |
| Serialização | ✅ 100% | paraMapaPlanilha, deLinhaPlanilha |
| Transformação | ✅ 100% | copiarCom, status changes |

---

## Como Rodar Apenas Unitários

```bash
flutter test test/unitarios/
```

---

## Padrão: Arrange → Act → Assert

```dart
test('Paciente.calcularIdade deve retornar 40 para nascido 04/06/1986', () {
  // Arrange
  final paciente = Paciente(
    dataNascimento: DateTime(1986, 6, 4),
    ...
  );
  
  // Act
  final idade = paciente.calcularIdade(
    dataReferencia: DateTime(2026, 6, 4)
  );
  
  // Assert
  expect(idade, equals(40));
});
```
