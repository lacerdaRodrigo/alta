# 📊 Análise de Cobertura de Testes

> ⚠️ **ARQUIVADO — snapshot histórico de 2026-06-16.** Todas as 12 telas
> principais já têm testes de widget hoje (368 testes no total). Para os
> números atuais, veja [`VISAO_GERAL.md`](./VISAO_GERAL.md). Este documento
> fica só como registro de como a cobertura evoluiu (era 60% de telas
> testadas nessa data) — não reflete o estado atual do projeto.

**Data:** 2026-06-16  
**Status:** 62% de cobertura total | 60% de telas com testes

---

## Resumo Executivo

```
Teles do APP:          10
✅ Com testes:          6 (60%)
❌ Sem testes:          4 (40%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Testes unitários:      89 ✅ 100% cobertura
Testes de widget:      40 ✅ Parcial (6/10 telas)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL:                129 testes passando
```

---

## ✅ Telas Testadas (40 testes | 6 telas)

| Tela | Testes | Status |
|---|---|---|
| tela_cadastro_paciente | 15 | ✅ Completa |
| tela_registro_evolucao | 10 | ✅ Completa |
| tela_pacientes | 5 | ✅ Boa |
| tela_sessoes | 4 | ✅ Básica |
| tela_configuracoes | 4 | ✅ Básica |
| tela_historico_geral_evolucoes | 2 | ⚠️ Mínima |

---

## ❌ Telas Sem Testes (0 testes | 4 telas)

### 🔴 Críticas (precisa testar urgentemente)

1. **tela_login** — 445 linhas
   - Fluxo de autenticação (pré-requisito do app)
   - Complexidade: Depende de Google Sign-In
   - Testes necessários: ~10-12
   - **Blockers:** Requer mock complexo de AutenticacaoNotificador + Google Sign-In

2. **tela_dashboard** — 380+ linhas
   - Tela principal, navegação central
   - Complexidade: Múltiplos cards, estado compartilhado
   - Testes necessários: ~8-10
   - **Blockers:** Requer mock de Riverpod state, pacientes e agendamentos

### 🟡 Médias (testar em futuro próximo)

3. **tela_nova_sessao** — 360+ linhas
   - Testes necessários: ~5-6

4. **tela_historico_evolucoes** — 240+ linhas
   - Testes necessários: ~3-4

---

## 📈 Cobertura de Lógica Pura (89 testes | 100%)

✅ **Validadores:** 46 testes
- CPF, Telefone, Nome, Data, Email

✅ **Modelos:** 22 testes
- Paciente, Agendamento, Evolução
- Serialização, transformação, status

✅ **Utilitários:** 21 testes
- Cálculo de idade
- Formatação de datas
- Validação de CPF

---

## 🛠️ Próximos Passos

### Curto prazo (essencial)
- [ ] Criar testes para tela_login (requer mock de AuthN)
- [ ] Criar testes para tela_dashboard (requer mock de Riverpod)

### Médio prazo
- [ ] Criar testes para tela_nova_sessao
- [ ] Criar testes para tela_historico_evolucoes

### Meta final
- [ ] Atingir 100% de cobertura de telas (~75+ testes totais)

---

## Tecnicamente

Os testes falharam ao tentar mockear:
- `AutenticacaoNotificador` (extends Notifier) — requer `ref`
- `Riverpod StateNotifier` — dependência circular

**Solução possível:** Usar `ProviderContainer` para teste isolado ou refatorar UI para separar lógica de apresentação.

---

## Conclusão

- ✅ **Cobertura de lógica:** Excelente (100%)
- ⚠️ **Cobertura de UI:** Boa (60%)
- 🔴 **Críticas:** Login e Dashboard (40% de telas)

**Recomendação:** Focar em login e dashboard quando tiver estrutura de mock adequada. Atual suite de 129 testes é estável e confiável.
