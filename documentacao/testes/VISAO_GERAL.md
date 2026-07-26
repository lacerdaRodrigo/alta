# 📋 Testes Automatizados — Visão Geral

**Status:** ✅ 286 testes passando

---

## Resumo Executivo

O projeto utiliza **apenas testes unitários e de widget** (sem E2E automatizados). A estrutura é simples, clara e sem redundâncias:

| Categoria | Quantidade | % | Focos |
|---|---|---|---|
| **Unit — Utilitários** | 86 | 30% | Validadores, formatadores, gerador de IDs |
| **Unit — Modelos** | 25 | 9% | Serialização, transformação, cópia |
| **Unit — Serviços** | 5 | 2% | Preferências (SharedPreferences) |
| **Widget — Telas** | 149 | 52% | UI, interação, estados visuais |
| **Widget — Componentes/Utilitários** | 21 | 7% | Modal de detalhes, rodapé versão, ações de agendamento |
| **TOTAL** | **286** | **100%** | — |

---

## Estrutura de Diretórios

```
test/
├── unitarios/              (116 testes — lógica pura)
│   ├── auxiliares/         
│   │   └── fakes.dart                    — Mocks reutilizados
│   ├── modelos/
│   │   ├── agendamento_test.dart        (10 testes)
│   │   ├── evolucao_test.dart           (6 testes)
│   │   └── paciente_test.dart           (9 testes)
│   ├── servicos/
│   │   └── preferencias_test.dart       (5 testes)
│   └── utilitarios/
│       ├── utilitarios_data_test.dart   (23 testes)
│       ├── validador_cpf_test.dart      (9 testes)
│       ├── validadores_test.dart        (46 testes)
│       └── gerador_id_test.dart         (8 testes)
└── widgets/                (170 testes — UI + componentes)
    ├── componentes/
    │   ├── modal_detalhes_paciente_test.dart   (12 testes)
    │   └── rodape_versao_test.dart             (3 testes)
    ├── utilitarios/
    │   └── acoes_agendamento_test.dart         (6 testes)
    └── telas/
        ├── tela_splash_test.dart              (7 testes — abertura animada)
        ├── tela_login_test.dart               (9 testes)
        ├── tela_dashboard_test.dart           (14 testes)
        ├── tela_cadastro_paciente_test.dart  (23 testes)
        ├── tela_editar_paciente_test.dart    (6 testes — campos travados + atualização)
        ├── tela_editar_sessao_test.dart      (7 testes — editar/reagendar sessão)
        ├── tela_financeiro_test.dart          (8 testes — resumo financeiro mensal)
        ├── tela_configuracoes_test.dart       (14 testes)
        ├── tela_historico_geral_evolucoes_test.dart (7 testes)
        ├── tela_pacientes_test.dart          (12 testes)
        ├── tela_registro_evolucao_test.dart  (23 testes — inclui timeline e ditado por voz)
        ├── tela_sessoes_test.dart           (10 testes)
        └── tela_nova_sessao_test.dart       (9 testes)
```

---

## Como Rodar

```bash
# Todos os 286 testes
flutter test

# Apenas unitários
flutter test test/unitarios/

# Apenas widgets
flutter test test/widgets/

# Um arquivo específico
flutter test test/unitarios/utilitarios/validadores_test.dart

# Modo watch (rerun ao salvar)
flutter test --watch

# Com relatório de coverage
flutter test --coverage
```

---

## Padrão de Teste: AAA

Todos os testes seguem **Arrange → Act → Assert**:

```dart
test('descrição do comportamento', () {
  // Arrange: preparar dados
  final entrada = Paciente(...);
  
  // Act: executar função
  final resultado = entrada.calcularIdade();
  
  // Assert: validar resultado
  expect(resultado, equals(40));
});
```

---

## O que NÃO é Testado

❌ Google Sheets API real (seria lento, usaria quota)  
❌ Google Sign-In real (exigiria navegador/device)  
❌ Testes E2E (removidos — era redundante)  
❌ Performance/carga  

---

## Ver Também

- [`UNITARIOS.md`](./UNITARIOS.md) — Detalhes de cada teste unitário
- [`WIDGETS.md`](./WIDGETS.md) — Detalhes de cada teste de widget
- [`../../QA/qa.md`](../../QA/qa.md) — Script de QA manual
