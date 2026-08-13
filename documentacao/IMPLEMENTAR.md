# Plano de Implementação — Alta

> Este arquivo lista **apenas o que falta fazer**. O que já foi entregue está
> registrado no [`CHANGELOG.md`](../CHANGELOG.md); o estado atual da arquitetura
> está no [`CLAUDE.md`](../CLAUDE.md).

**Status:** MVP funcional completo em produção (web) · 365 testes automatizados
**Atualizado em:** 2026-07-29

---

## 🔴 Alta prioridade

### 1. Segurança — rotacionar credenciais expostas no histórico do git

`android/app/google-services.json` foi removido do working tree e adicionado ao
`.gitignore`, mas **continua acessível nos commits antigos**. Remover o arquivo
não invalida a credencial.

- [ ] Rotacionar as chaves no Google Cloud / Firebase Console
- [ ] Decidir se vale reescrever o histórico (`git filter-repo`) ou apenas
      rotacionar e seguir

### 2. Publicação nas lojas

**Android**
- [ ] Registrar SHA-1 debug no Firebase e baixar `google-services.json` atualizado
- [ ] Configurar release signing para a Play Store

**iOS** (nada configurado ainda)
- [ ] `GoogleService-Info.plist`
- [ ] `CFBundleURLTypes` (callback OAuth)
- [ ] Permissão de microfone (ditado por voz na evolução)

---

## 🟡 Média prioridade

### 3. Tratamento de erro e retry

- [ ] Retry automático em falhas da API Google
- [ ] Timeout handling
- [ ] Feedback visual consistente em todas as telas

### 4. WhatsApp para confirmação e contato rápido

- **Onde:** modal de detalhes do paciente e cards de sessão
- **O que:** abrir conversa com mensagem pronta de confirmação, remarcação ou lembrete
- **Exemplo:** `Olá, confirmando sua sessão de fisioterapia no dia X às Y.`
- **Valor:** reduz faltas, agiliza confirmação e combina bem com atendimento domiciliar

### 5. Cache local offline

- [ ] Escolher e adicionar dependências de armazenamento local (só quando for implementar)
- [ ] Salvar `SessaoGoogle` (tokens) localmente para login offline
- [ ] Cache dos dados da planilha para leitura sem internet
- [ ] Indicador visual de conectividade

### 6. Relatório do paciente (PDF)

Perfil, dados clínicos principais, histórico de evoluções, dor, condição clínica
e sessões realizadas. Útil para encaminhamentos, prestação de contas e auditoria.

### 7. Exportar dados

- [ ] Agenda em CSV
- [ ] Financeiro em CSV

### 8. Backup automático para Google Drive

---

## 🟢 Baixa prioridade

| Feature | Descrição |
|---|---|
| **Pacotes de sessão** | Pacotes pré-pagos (ex: 10 sessões) com controle de saldo |
| **Escalas de avaliação** | EVA dor, SF-36, Roland-Morris, etc. |
| **Prescrição de exercícios** | Biblioteca de exercícios com imagens/descrição |
| **Lembretes WhatsApp** | Enviar link de rota ou lembrete via WhatsApp |
| **Modo escuro** | Tema dark nas configurações |
| **Perfil do profissional** | CREFITO, telefone, endereço da clínica |
| **Backup manual** | Botão para exportar/importar backup completo |
| **Notificações push** | Lembretes de consulta via Firebase Cloud Messaging |
| **Multi-clínica** | Suporte a múltiplos profissionais/empresas |
| **Gráficos** | Visualização de tendências por período |
| **Deep links** | Compartilhar link direto para paciente/agenda |

---

## Observações técnicas

- **Banco:** Google Sheets (5 abas: Pacientes, Agenda, Evolucoes, Configuracoes, Auditoria) + aba `Versao`
- **Autenticação:** `google_sign_in` 7.2.0 + `google_sign_in_web` 1.1.3, escopos OAuth
  `email` + `drive.file` + `spreadsheets`. No web o login parte do botão renderizado
  pelo GIS; fora do web, de `GoogleSignIn.instance.authenticate()`
- **Testes sensíveis a relógio:** fixtures que representam "sessão de hoje já
  vencida" devem derivar o horário de `DateTime.now()`, nunca fixá-lo. O CI roda
  em UTC e uma hora fixa faz o teste passar só em parte do dia
  (ver `tela_sessoes_test.dart`).
- **Manutenção periódica:** remover dependências não usadas
