# 📚 Documentação de Testes

Guia completo dos 309 testes automatizados do Alta.

---

## 📖 Documentos

1. **[VISAO_GERAL.md](./VISAO_GERAL.md)** — Overview, estrutura, como rodar
2. **[UNITARIOS.md](./UNITARIOS.md)** — 128 testes unitários (validadores, modelos, serviços)
3. **[WIDGETS.md](./WIDGETS.md)** — 181 testes de widget (telas, componentes, utilitários)

---

## 🎯 Quick Start

```bash
# Rodar todos os testes
flutter test

# Apenas unitários
flutter test test/unitarios/

# Apenas widgets
flutter test test/widgets/

# Um arquivo específico
flutter test test/unitarios/utilitarios/validadores_test.dart
```

---

## 📊 Estatísticas

| Tipo | Quantidade | % |
|---|---|---|
| Unit — Utilitários | 93 | 30% |
| Unit — Modelos | 30 | 10% |
| Unit — Serviços | 5 | 2% |
| Widget — Telas | 154 | 50% |
| Widget — Componentes/Utilitários | 27 | 9% |
| **TOTAL** | **309** | **100%** |

---

## ✅ Cobertura

✅ **Validação de entrada** — CPF, telefone, nome, data, email  
✅ **Modelos de dados** — Serialização, transformação, cópia  
✅ **Utilitários** — Cálculo de idade, formatação de datas  
✅ **UI e interação** — 13 telas principais + modal de detalhes e ações de agendamento  

❌ **Não coberto:** Google Sheets API real, Google Sign-In real, E2E, performance

---

## 📂 Estrutura

```
test/
├── unitarios/
│   ├── auxiliares/
│   ├── modelos/
│   ├── servicos/
│   └── utilitarios/
└── widgets/
    ├── componentes/
    ├── utilitarios/
    └── telas/
```

---

## 🔗 Relacionado

- **[../../QA/qa.md](../../QA/qa.md)** — Script de QA manual
- **[../IMPLEMENTAR.md](../IMPLEMENTAR.md)** — Roadmap do projeto
