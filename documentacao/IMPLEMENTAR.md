# Plano de Implementação — Fisio Home Care

> Este arquivo lista **apenas o que falta fazer**. O que já foi entregue está
> registrado no [`CHANGELOG.md`](../CHANGELOG.md); o estado atual da arquitetura
> está no [`CLAUDE.md`](../CLAUDE.md).

**Status:** MVP funcional completo em produção (web) · 277 testes automatizados
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

### 2. Validar a migração do `google_sign_in` 7.2.0 (código pronto, falta testar)

Migração implementada na branch `migracao-google-sign-in-7`. Falta **validação
manual** — nenhum teste automatizado cobre o SDK real do Google.

- [ ] Login no web (preview channel): entrar, criar/abrir planilha, carregar dados
- [ ] Login no Android em device físico — a 7.x usa Credential Manager no nativo
- [ ] Sessão com mais de 1h: no web o access token expira em 3600s e **não é
      renovado** pelo plugin. `obterHeaders()` chama `authorizationHeaders()` a
      cada requisição justamente para renovar; confirmar que funciona na prática
- [ ] Primeiro login com **conta Google sem consentimento prévio** (o escopo
      `spreadsheets` foi restaurado nesta migração, mas contas antigas mascaram
      o problema por já terem o consentimento)

> ⚠️ A `TelaLogin` sobrepõe o botão do GIS (quase invisível) ao botão desenhado
> do app, porque no web `authenticate()` lança `UnsupportedError`. A sobreposição
> foi validada no navegador (botão presente no DOM, largura alinhada, área
> clicável cobrindo todo o desenho, e ausente enquanto os termos não são aceitos),
> mas **nenhum teste automatizado cobre isso** — fora do web o componente vira um
> `SizedBox.shrink()`. Três detalhes a preservar em qualquer mexida:
> `Opacity` precisa ser > 0 (com alpha 0 o Flutter não pinta e a platform view não
> entra no DOM); `IgnorePointer` não segura o clique de uma platform view; e o
> GIS limita o botão a 400px, então o desenho tem que respeitar a mesma largura.
> Se uma atualização do SDK mudar o tamanho ou o DOM do botão, a saída suportada
> é exibir o botão do Google diretamente, sem o desenho por baixo.

### 3. Publicação nas lojas

**Android**
- [ ] Registrar SHA-1 debug no Firebase e baixar `google-services.json` atualizado
- [ ] Configurar release signing para a Play Store

**iOS** (nada configurado ainda)
- [ ] `GoogleService-Info.plist`
- [ ] `CFBundleURLTypes` (callback OAuth)
- [ ] Permissão de microfone (ditado por voz na evolução)

---

## 🟡 Média prioridade

### 4. Tratamento de erro e retry

- [ ] Retry automático em falhas da API Google
- [ ] Timeout handling
- [ ] Feedback visual consistente em todas as telas

### 5. WhatsApp para confirmação e contato rápido

- **Onde:** modal de detalhes do paciente e cards de sessão
- **O que:** abrir conversa com mensagem pronta de confirmação, remarcação ou lembrete
- **Exemplo:** `Olá, confirmando sua sessão de fisioterapia no dia X às Y.`
- **Valor:** reduz faltas, agiliza confirmação e combina bem com atendimento domiciliar

### 6. Testes de serviço

`test/unitarios/servicos/` cobre apenas `preferencias_test.dart`. Os serviços que
falam com a rede só aparecem nos testes via fakes — nenhum tem teste próprio.

- [ ] `servico_repositorio_dados.dart` (parsing de linhas, `obterPlanilhaId`, retry de 404)
- [ ] `servico_autenticacao_google.dart`
- [ ] Fluxo de integração com a Sheets API

### 7. Duplicata de planilha

`ServicoGoogleDrive.buscarPlanilhaBanco()` consulta `name contains
'__saas_fisio_db__'` ordenando por `modifiedTime desc` e usa a primeira. Havendo
mais de uma planilha, escolhe silenciosamente a mais recente.

- [ ] Usar correspondência exata de nome, ou avisar o usuário quando houver duplicatas

### 8. Cache local offline

- [ ] Escolher e adicionar dependências de armazenamento local (só quando for implementar)
- [ ] Salvar `SessaoGoogle` (tokens) localmente para login offline
- [ ] Cache dos dados da planilha para leitura sem internet
- [ ] Indicador visual de conectividade

### 9. Relatório do paciente (PDF)

Perfil, dados clínicos principais, histórico de evoluções, dor, condição clínica
e sessões realizadas. Útil para encaminhamentos, prestação de contas e auditoria.

### 10. Exportar dados

- [ ] Agenda em CSV
- [ ] Financeiro em CSV

### 11. Backup automático para Google Drive

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
