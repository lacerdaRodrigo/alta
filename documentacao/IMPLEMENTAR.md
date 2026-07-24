# Plano de Implementação — Fisio Home Care

> Este arquivo lista **apenas o que falta fazer**. O que já foi entregue está
> registrado no [`CHANGELOG.md`](../CHANGELOG.md); o estado atual da arquitetura
> está no [`CLAUDE.md`](../CLAUDE.md).

**Status:** MVP funcional completo em produção (web) · 276 testes automatizados
**Atualizado em:** 2026-07-23

---

## 🔴 Alta prioridade

### 1. Segurança — rotacionar credenciais expostas no histórico do git

`android/app/google-services.json` foi removido do working tree e adicionado ao
`.gitignore`, mas **continua acessível nos commits antigos**. Remover o arquivo
não invalida a credencial.

- [ ] Rotacionar as chaves no Google Cloud / Firebase Console
- [ ] Decidir se vale reescrever o histórico (`git filter-repo`) ou apenas
      rotacionar e seguir

### 2. Migrar `google_sign_in` 6.2.1 → 7.x

É a causa raiz estrutural dos bugs de login no web, hoje resolvidos apenas por
mitigação. Na 6.x, `signInSilently()` devolve identidade sem access token dos
escopos de Drive/Sheets, e `signIn()` está depreciado no web (avisos de FedCM e
COOP no console). A 7.x separa identidade de autorização via
`authorizationClient` (`authorizationForScopes()` / `authorizeScopes()` /
`authorizationHeaders()`).

- [ ] Restaurar a lógica do commit `dc7b46b` sobre a API 7.x
- [ ] **Retestar o login no Android também** — não só no web

> Adiado conscientemente em 2026-07-01 para evitar reteste do fluxo Android
> numa mudança maior de versão de pacote.

### 3. Validar o fluxo de login com uma conta Google nova

`escoposGoogleFisio` (`lib/servicos/servico_autenticacao_google.dart`) pede
apenas `email` e `drive.file`. Contas que já usaram o app carregam
`spreadsheets` de consentimentos anteriores e mascaram o problema — uma conta
limpa pode não ter.

- [ ] Testar o primeiro login (criação da planilha) com conta sem consentimento prévio
- [ ] Adicionar `https://www.googleapis.com/auth/spreadsheets` aos escopos se necessário

### 4. Publicação nas lojas

**Android**
- [ ] Registrar SHA-1 debug no Firebase e baixar `google-services.json` atualizado
- [ ] Configurar release signing para a Play Store

**iOS** (nada configurado ainda)
- [ ] `GoogleService-Info.plist`
- [ ] `CFBundleURLTypes` (callback OAuth)
- [ ] Permissão de microfone (ditado por voz na evolução)

---

## 🟡 Média prioridade

### 5. Tratamento de erro e retry

- [ ] Retry automático em falhas da API Google
- [ ] Timeout handling
- [ ] Feedback visual consistente em todas as telas

### 6. WhatsApp para confirmação e contato rápido

- **Onde:** modal de detalhes do paciente e cards de sessão
- **O que:** abrir conversa com mensagem pronta de confirmação, remarcação ou lembrete
- **Exemplo:** `Olá, confirmando sua sessão de fisioterapia no dia X às Y.`
- **Valor:** reduz faltas, agiliza confirmação e combina bem com atendimento domiciliar

### 7. Testes de serviço

`test/unitarios/servicos/` cobre apenas `preferencias_test.dart`. Os serviços que
falam com a rede só aparecem nos testes via fakes — nenhum tem teste próprio.

- [ ] `servico_repositorio_dados.dart` (parsing de linhas, `obterPlanilhaId`, retry de 404)
- [ ] `servico_autenticacao_google.dart`
- [ ] Fluxo de integração com a Sheets API

### 8. Duplicata de planilha

`ServicoGoogleDrive.buscarPlanilhaBanco()` consulta `name contains
'__saas_fisio_db__'` ordenando por `modifiedTime desc` e usa a primeira. Havendo
mais de uma planilha, escolhe silenciosamente a mais recente.

- [ ] Usar correspondência exata de nome, ou avisar o usuário quando houver duplicatas

### 9. Cache local offline

- [ ] Escolher e adicionar dependências de armazenamento local (só quando for implementar)
- [ ] Salvar `SessaoGoogle` (tokens) localmente para login offline
- [ ] Cache dos dados da planilha para leitura sem internet
- [ ] Indicador visual de conectividade

### 10. Relatório do paciente (PDF)

Perfil, dados clínicos principais, histórico de evoluções, dor, condição clínica
e sessões realizadas. Útil para encaminhamentos, prestação de contas e auditoria.

### 11. Exportar dados

- [ ] Agenda em CSV
- [ ] Financeiro em CSV

### 12. Backup automático para Google Drive

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
- **Autenticação:** `google_sign_in` 6.2.1, escopos OAuth `email` + `drive.file`
- **Testes sensíveis a relógio:** fixtures que representam "sessão de hoje já
  vencida" devem derivar o horário de `DateTime.now()`, nunca fixá-lo. O CI roda
  em UTC e uma hora fixa faz o teste passar só em parte do dia
  (ver `tela_sessoes_test.dart`).
- **Manutenção periódica:** remover dependências não usadas
