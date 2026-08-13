# Segurança, Privacidade e Conformidade LGPD

Este documento descreve a arquitetura de segurança, as políticas de privacidade e a conformidade com a Lei Geral de Proteção de Dados (LGPD — Lei nº 13.709/2018) do aplicativo Alta.

---

## 1. Arquitetura de Dados (Modelo BYODB — Soberano)

O App adota o modelo **Bring Your Own Database**: todos os dados são armazenados na conta Google do profissional.

| Aspecto | Implementação |
|---|---|
| **Servidor central** | Não existe. Dados nunca saem da conta Google do profissional. |
| **Banco de dados** | Planilha Google Sheets (`__saas_fisio_db__`) no Google Drive do profissional. |
| **Isolamento** | Cada profissional tem sua própria planilha. Impossível acessar dados de outro profissional. |
| **Hospedagem web** | Firebase Hosting serve apenas código estático (HTML/JS/CSS). Nenhum dado clínico passa pelo Firebase. |

```
┌──────────────────┐                    ┌──────────────────────────┐
│  Dispositivo do  │   OAuth 2.0 API    │   Google Cloud (Drive)   │
│  Fisioterapeuta  │ ═══════════════>   │  Planilha pessoal do     │
│  (App Flutter)   │   HTTPS / TLS      │  profissional            │
└──────────────────┘                    └──────────────────────────┘
```

---

## 2. Autenticação e Autorização

| Camada | Mecanismo |
|---|---|
| **Login** | Google Sign-In (OAuth 2.0), `google_sign_in` 7.x. O App nunca acessa a senha do usuário. No web, o toque no botão do App abre diretamente um popup do OAuth2 do Google (identidade + consentimento dos escopos num único passo); no Android, do fluxo nativo. |
| **Escopos** | `email`, `drive.file` e `spreadsheets`. `drive.file` restringe o acesso aos arquivos que o próprio App criou — não alcança outros arquivos, fotos ou pastas do Drive. `spreadsheets` é exigido pela Sheets API para ler e escrever na planilha do usuário. |
| **Token** | Access token temporário, resolvido a cada requisição pelo `AutorizadorGoogle` (`lib/servicos/autorizador_google.dart`). Não é armazenado de forma persistente pelo App: no Android vem de `conta.authorizationClient`; no web fica só em memória, indexado pelo e-mail da conta, e expira em 1h. |
| **Autenticação vs. autorização** | São etapas separadas: identificar o usuário não concede, por si só, acesso ao Drive/Sheets. O App só considera a sessão válida depois de confirmar a autorização dos escopos. |
| **Consentimento de termos** | Checkbox obrigatório na tela de login. Enquanto não for aceito, o botão de login do Google não é sequer construído — não basta desabilitá-lo visualmente, porque no web ele é um elemento DOM que receberia o clique por fora do controle do App. |

---

## 3. Dados Coletados

### 3.1. Dados do Profissional
- **Nome e e-mail:** do Google Sign-In, para identificação na interface.
- **Token OAuth:** temporário, usado para chamadas à API. Descartado ao sair.

### 3.2. Dados dos Pacientes (Titulares)

| Categoria | Dados | Base Legal (LGPD) |
|---|---|---|
| **Identificação** | Nome, CPF, telefone, data de nascimento, gênero, endereço | Art. 7º, V — execução de contrato |
| **Dados de saúde (sensíveis)** | Queixa, histórico clínico, comorbidades, medicamentos, alergias, cirurgias, escala de dor, evolução clínica, sinais vitais | Art. 11, II, "f" — tutela da saúde por profissional de saúde |
| **Operacionais** | Agendamentos, valores, status de presença, logs de auditoria | Art. 7º, V — execução de contrato |

### 3.3. Minimização de Dados
Apenas dados estritamente necessários para o acompanhamento clínico e faturamento são coletados. Campos de anamnese são opcionais.

---

## 4. Conformidade LGPD

### 4.1. Papéis

| Papel | Quem | Responsabilidade |
|---|---|---|
| **Controlador** | Fisioterapeuta (Usuário) | Decide quais dados coletar, por quanto tempo reter e como tratar. Responde ao paciente. |
| **Operador** | Google LLC + App | Processa dados conforme instruções do Controlador. |
| **Titular** | Paciente | Pessoa cujos dados são tratados. |

### 4.2. Direitos do Titular (Art. 18)

| Direito | Como é atendido |
|---|---|
| **Acesso** | Exportar dados da planilha ou mostrar pelo App |
| **Correção** | Tela "Editar Paciente" (telefone, endereço, anamnese). Campos de identidade travados por segurança. |
| **Eliminação** | Arquivar no App ou excluir linha diretamente na planilha |
| **Portabilidade** | Planilha exportável em CSV, XLSX ou PDF pelo Google Drive |
| **Revogação** | Paciente solicita ao profissional, que deve eliminar os registros |

### 4.3. Consentimento
- Aceite de Termos de Uso e Política de Privacidade é pré-condição para login (checkbox obrigatório, Art. 8º §3 LGPD).
- O aceite é gravado na aba **Auditoria** da planilha com tipo `ACEITE_TERMOS`, versão do documento e e-mail do profissional (rastreabilidade conforme Art. 8º §2).
- A versão vigente dos documentos é controlada pela constante `_versaoTermosAceitos` em `lib/provedores/provedores_dados.dart`. Deve ser atualizada em toda alteração material dos documentos legais.
- Documentos legais disponíveis em:
  - Termos de Uso: `https://app-fisio-care-2.web.app/termos.html`
  - Política de Privacidade: `https://app-fisio-care-2.web.app/privacidade.html`

### 4.4. Retenção e Exclusão
- **Retenção:** dados permanecem enquanto o profissional julgar necessário (prontuário: mínimo 20 anos conforme Resolução COFFITO).
- **Exclusão:** ao desinstalar o App, dados permanecem na planilha. O profissional pode excluir a planilha a qualquer momento.

### 4.5. Incidentes de Segurança
Em caso de incidente, o desenvolvedor se compromete a comunicar a ANPD e os Titulares afetados em prazo razoável, descrevendo natureza dos dados, riscos e medidas adotadas.

---

## 5. Segurança Técnica

| Medida | Implementação |
|---|---|
| **Criptografia em trânsito** | HTTPS/TLS em todas as chamadas à API Google |
| **Criptografia em repouso** | Nativa do Google Cloud (AES-256) |
| **Validação de entrada** | CPF, telefone, datas, escala de dor — validados antes da gravação |
| **Logging estruturado** | `developer.log()` com nome da classe. `print()` proibido por lint. |
| **Auditoria** | Toda operação crítica (cadastro, edição, arquivamento, agendamento) registrada na aba "Auditoria" com timestamp. |
| **Sem dados persistentes no dispositivo** | Dados clínicos ficam em memória durante a sessão. Ao sair, estado descartado. |
| **Credenciais fora do git** | `.env`, `google-services.json`, `chaves.md` no `.gitignore`. |
| **Lint rigoroso** | `analysis_options.yaml` com regras de segurança (`cancel_subscriptions`, `close_sinks`, `unawaited_futures`). |

---

## 6. O que NÃO é feito

- **Não** há cookies de rastreamento, pixels ou analytics que processem dados de pacientes.
- **Não** há compartilhamento de dados com terceiros.
- **Não** há venda, aluguel ou comercialização de dados.
- **Não** há cache offline persistente de dados clínicos (planejado para versão futura).
- **Não** há backup automático (o profissional pode copiar a planilha pelo Google Drive).

---

## 7. Documentos Legais

| Documento | URL | Descrição |
|---|---|---|
| Termos de Uso | [termos.html](https://app-fisio-care-2.web.app/termos.html) | Condições de uso do App |
| Política de Privacidade | [privacidade.html](https://app-fisio-care-2.web.app/privacidade.html) | Tratamento de dados pessoais e de saúde conforme LGPD |

---

## 8. Contato (DPO / Encarregado)

**Rodrigo Lacerda**
E-mail: lacerdaa.rodrigo@gmail.com

O Titular pode apresentar reclamação à Autoridade Nacional de Proteção de Dados (ANPD) pelo site **www.gov.br/anpd**.
