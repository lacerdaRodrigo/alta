# Fisio Home Care — Contexto Completo para Claude

> ⚠️ **IMPORTANTE:** Este arquivo deve ser **SEMPRE ATUALIZADO** quando o projeto muda. Além disso, **testes e documentação DEVEM ser mantidos atualizados** em paralelo com o código.

---

## O que é este projeto

**Fisio Home Care** é um aplicativo mobile + web de Fisioterapia Domiciliar desenvolvido em Flutter.

### Características principais
- **Backend:** Serverless via Google Sheets API (modelo BYODB — o fisioterapeuta conecta sua própria conta Google)
- **Autenticação:** OAuth 2.0 (Google Sign-In)
- **Hospedagem web:** Firebase Hosting
- **Conformidade:** LGPD (dados nunca saem da conta Google do profissional)
- **Sem servidor central:** Não há prontuário centralizado de terceiros

---

## Stack Técnico

| Tecnologia | Versão | Propósito |
|---|---|---|
| **Flutter + Dart** | 3.12.0+ | Framework principal (Material 3, null-safety) |
| **Riverpod** | 3.x | Estado e injeção de dependência |
| **Google Sheets API** | v4 | Banco de dados BYODB |
| **Google Drive API** | v3 | Localizar planilha do usuário |
| **Google Sign-In** | 7.2.0 | Autenticação OAuth (web: `google_sign_in_web` 1.1.3) |
| **Table Calendar** | 3.1.3 | Visão calendário na agenda |
| **Firebase Hosting** | — | Deploy web |

---

## Estrutura de Pastas

```
fisio-home-care/
├── lib/
│   ├── main.dart                    # Ponto de entrada
│   ├── telas/                       # Screens UI
│   │   ├── tela_splash.dart         # Abertura animada (ECG + batimento)
│   │   ├── tela_login.dart
│   │   ├── tela_dashboard.dart
│   │   ├── tela_pacientes.dart
│   │   ├── tela_cadastro_paciente.dart
│   │   ├── tela_editar_paciente.dart
│   │   ├── tela_nova_sessao.dart
│   │   ├── tela_sessoes.dart
│   │   ├── tela_registro_evolucao.dart
│   │   ├── tela_historico_evolucoes.dart
│   │   ├── tela_editar_sessao.dart
│   │   ├── tela_financeiro.dart
│   │   ├── tela_historico_geral_evolucoes.dart
│   │   └── tela_configuracoes.dart
│   │
│   ├── componentes/
│   │   ├── design_system.dart       # 🔑 Design tokens, cores, tipografia
│   │   ├── modal_detalhes_paciente.dart  # Bottom sheet detalhes paciente
│   │   └── rodape_versao.dart       # Overlay de versão do app
│   │
│   ├── provedores/                  # Riverpod state management
│   │   ├── provedor_autenticacao.dart    # Login Google
│   │   ├── provedores_dados.dart         # CRUD de pacientes, agendamentos, evoluções
│   │   └── (seletores, callbacks)
│   │
│   ├── modelos/
│   │   ├── paciente.dart            # 19 colunas na planilha
│   │   ├── agendamento.dart         # 9 colunas
│   │   ├── evolucao.dart            # 14 colunas
│   │   └── (value objects, copyWith, serialização)
│   │
│   ├── servicos/
│   │   ├── servico_autenticacao_google.dart    # Google Sign-In wrapper
│   │   ├── servico_repositorio_dados.dart      # Google Sheets CRUD
│   │   ├── servico_google_drive.dart           # Localizar planilha
│   │   ├── servico_google_sheets.dart          # Wrapper Google Sheets API
│   │   ├── cliente_google_autenticado.dart     # HTTP client autenticado
│   │   ├── preferencias.dart                   # SharedPreferences
│   │   └── versao_esquema.dart                 # Versionamento de schema
│   │
│   └── utilitarios/
│       ├── validadores.dart         # CPF, telefone, nome, data, email
│       ├── validador_cpf.dart       # Validação de CPF isolada
│       ├── utilitarios_data.dart    # Cálculo de idade, formatação
│       ├── acoes_agendamento.dart   # Lógica de desfechos
│       ├── gerador_id.dart          # Geração de IDs sequenciais (max+1)
│       ├── formatters.dart          # Formatadores de entrada (máscaras)
│       └── mensagens_erro_google.dart    # Mapear erros Google
│
├── test/
│   ├── unitarios/                   # 116 testes — lógica pura
│   │   ├── auxiliares/
│   │   │   └── fakes.dart           # Mocks reutilizados
│   │   ├── modelos/
│   │   │   ├── paciente_test.dart           (9 testes)
│   │   │   ├── agendamento_test.dart        (10 testes)
│   │   │   └── evolucao_test.dart           (6 testes)
│   │   ├── servicos/
│   │   │   └── preferencias_test.dart       (5 testes)
│   │   └── utilitarios/
│   │       ├── validadores_test.dart        (46 testes)
│   │       ├── validador_cpf_test.dart      (9 testes)
│   │       ├── utilitarios_data_test.dart   (23 testes)
│   │       └── gerador_id_test.dart         (8 testes — 100% cobertura)
│   │
│   └── widgets/                     # 170 testes — UI + componentes
│       ├── componentes/
│       │   ├── modal_detalhes_paciente_test.dart   (12 testes)
│       │   └── rodape_versao_test.dart             (3 testes)
│       ├── utilitarios/
│       │   └── acoes_agendamento_test.dart         (6 testes)
│       └── telas/
│           ├── tela_splash_test.dart                 (7 testes — abertura animada + handoff para o login)
│           ├── tela_login_test.dart                  (9 testes — navegação única + login não-programático)
│           ├── tela_dashboard_test.dart              (14 testes)
│           ├── tela_cadastro_paciente_test.dart      (23 testes)
│           ├── tela_editar_paciente_test.dart        (6 testes — campos travados + atualização)
│           ├── tela_editar_sessao_test.dart          (7 testes — editar/reagendar sessão)
│           ├── tela_financeiro_test.dart             (8 testes — resumo financeiro mensal)
│           ├── tela_pacientes_test.dart              (12 testes)
│           ├── tela_registro_evolucao_test.dart      (23 testes — inclui timeline e ditado por voz)
│           ├── tela_sessoes_test.dart                (10 testes)
│           ├── tela_nova_sessao_test.dart             (9 testes)
│           ├── tela_configuracoes_test.dart          (14 testes)
│           └── tela_historico_geral_evolucoes_test.dart (7 testes)
│
├── documentacao/
│   ├── MODELO_DADOS.md              # Estrutura das 5 abas da planilha
│   ├── DIAGRAMA_FLUXOS.md           # Navegação e fluxos
│   ├── ESPECIFICACOES_TELAS.md      # Requisitos funcionais
│   ├── SEGURANCA_E_DADOS.md         # LGPD, OAuth, modelo BYODB
│   ├── IMPLEMENTAR.md               # Roadmap priorizado
│   ├── LOGIN_SCREEN_SPEC.md         # Specs tela login
│   ├── PACIENTES_SPEC.md            # Specs tela pacientes
│   ├── SUGESTOES_CADASTRO_PACIENTE.md
│   ├── chaves.md                    # (no .gitignore) — credenciais
│   └── testes/
│       ├── README.md                # Índice de testes
│       ├── VISAO_GERAL.md           # Overview 286 testes
│       ├── UNITARIOS.md             # Detalhe dos 116 unitários
│       └── WIDGETS.md               # Detalhe dos 170 widgets
│
├── QA/
│   └── qa.md                        # Script QA manual (NOT E2E automatizado)
│
├── tool/                            # Scripts de build (fora de test/)
│   ├── gerar_icones.dart            # 🔑 Ícone do app, desenhado em código
│   └── finalizar_icones.py          # Alfa do iOS + .ico do Windows (Pillow)
│
├── android/                         # Config Firebase, signing
├── ios/                             # Config iOS (futuro)
├── web/                             # Config web
├── pubspec.yaml                     # Dependências (patrol removido)
├── analysis_options.yaml            # Lints rigorosos
├── Makefile                         # Targets: dev, test, lint, icones, prod
├── CLAUDE.md                        # Este arquivo
├── README.md                        # Getting started
├── CHANGELOG.md                     # Histórico versões
└── .gitignore                       # (inclui .env, chaves.md, google-services.json)
```

---

## Banco de Dados: Google Sheets

Planilha: `__saas_fisio_db__` (na conta Google do fisioterapeuta)

| Aba | Colunas | Descrição |
|---|---|---|
| **Pacientes** | 19 | ID, Nome, CPF, Telefone, Data Nascimento, Endereço, Situação, Anamnese clínica (queixa, histórico, comorbidades, medicamentos, alergias, cirurgias, hábitos) |
| **Agenda** | 9 | ID, ID_Paciente, Data, Hora início/fim, Valor, Situação (Agendado/Realizado/Cancelado/Faltou), Observações |
| **Evoluções** | 14 | ID, ID_Paciente, ID_Agendamento, Data, Protocolo, Texto clínico, Horário real, Desfecho, etc. |
| **Configurações** | K/V | Valor padrão sessão, links, etc. |
| **Auditoria** | Log | Operações (quem, quando, o quê) |

### ⚠️ Regra crítica
**NUNCA** use índice numérico literal como `linha[10]`. Use mapa de índices:
- `Paciente.indicesColunas` (lib/modelos/paciente.dart:L30)
- `Agendamento.indicesColunas` (lib/modelos/agendamento.dart:L20)
- `VersaoEsquema.obterIndicesColunas(versao)` (lib/servicos/versao_esquema.dart:L45)

---

## Padrões de Código

### Estado (Riverpod)

**Localização:** `lib/provedores/`

```dart
// Autenticação
provedorAutenticacao → AutenticacaoNotificador
  .login()
  .logout()

// Dados
provedorRepositorioDados → RepositorioDadosGoogle (null se não autenticado)
  .carregarPacientes()
  .salvarPaciente(paciente)

// Listas em estado
provedorListaPacientes → StateNotifier<List<Paciente>>
provedorListaAgendamentos → StateNotifier<List<Agendamento>>
provedorListaEvolucoes → StateNotifier<List<Evolucao>>
```

**Padrão de carregamento:**
```dart
Future<void> carregarDadosReais(WidgetRef ref) async {
  final repo = ref.read(provedorRepositorioDados);
  if (repo == null) return; // não autenticado
  
  final pacientes = await repo.carregarPacientes();
  ref.read(provedorListaPacientes.notifier).definir(pacientes);
}
```

### Logging

**Regra:** `print()` é proibido (lint ativo).

Use sempre:
```dart
import 'dart:developer' as developer;

developer.log(
  'Mensagem aqui',
  error: exception,
  stackTrace: st,
  name: 'NomeClasse'
);
```

### Erros na UI

**Na tela:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Erro ao salvar. Tente novamente.'))
);
```

**No console/logs:**
```dart
developer.log(
  'Erro salvar paciente: ${e.message}',
  error: e,
  stackTrace: st,
  name: 'TelaCadastroPaciente'
);
```

### Validação

Usar classe `Validadores` (`lib/utilitarios/validadores.dart`):
```dart
if (!Validadores.validarCPF(cpf)) {
  // erro
}

// Delega para implementação isolada
ValidadorCpf.validar(cpf)  // ✓ fonte única de verdade
Paciente.calcularIdade()   // ✓ delega para UtilitariosData
```

---

## Testes (286 testes automatizados)

### Estrutura

```
test/
├── unitarios/  (116 testes)
│   ├── auxiliares/     — fakes.dart (mocks reutilizados)
│   ├── modelos/        — 25 testes (serialização, transformação)
│   ├── servicos/       — 5 testes (preferencias)
│   └── utilitarios/    — 86 testes (validadores, data, CPF, gerador_id)
│
└── widgets/    (170 testes)
    ├── telas/        — 13 telas principais (UI, interação)
    ├── componentes/  — modal de detalhes do paciente + rodapé versão
    └── utilitarios/  — ações de agendamento
```

### Rodar testes

```bash
# Todos
flutter test

# Apenas unitários
flutter test test/unitarios/

# Apenas widgets
flutter test test/widgets/

# Um arquivo
flutter test test/unitarios/utilitarios/validadores_test.dart

# Modo watch
flutter test --watch

# Coverage
flutter test --coverage
```

### Cobertura

✅ **Validação de entrada** — 55 testes (CPF, telefone, nome, data)  
✅ **Modelos** — 25 testes (serialização, cópia, status)  
✅ **Utilitários** — 31 testes (idade, formatação, geração de ID)  
✅ **UI + Interação** — 170 testes (13 telas principais + componentes/utilitários)  

❌ **Não coberto:**
- Google Sheets API real (usaria quota, seria lento)
- Google Sign-In real (exigiria device/navegador)
- Testes E2E (removidos em 2026-06-16 — redundante)
- Performance/carga

### Documentação de testes

📚 Ver `documentacao/testes/`:
- `README.md` — índice
- `VISAO_GERAL.md` — overview
- `UNITARIOS.md` — cada teste unitário
- `WIDGETS.md` — cada teste de widget

---

## Credenciais e Segurança

### Variáveis de ambiente

```bash
# .env (NUNCA commitar)
GOOGLE_OAUTH_CLIENT_ID_WEB=1034972209864-22ivlkbu9eu206fv6tvot90mup62stic.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_ID_ANDROID=...
GOOGLE_CLOUD_PROJECT_NUMBER=...
GOOGLE_AUTHORIZED_JAVASCRIPT_ORIGIN=https://app-fisio-care-2.web.app
GOOGLE_AUTHORIZED_REDIRECT_URI=https://app-fisio-care-2.web.app/__/auth/handler
```

### Arquivos no .gitignore

```
.env
.env.local
documentacao/chaves.md
documentacao/chaves.local.md
android/app/google-services.json
ios/GoogleService-Info.plist
```

### Rodando localmente

```bash
# Carregar .env e rodar
./run-dev.sh

# Ou manual
export GOOGLE_OAUTH_CLIENT_ID_WEB=...
flutter run
```

---

## Bugs conhecidos / Trade-offs

| Descrição | Status | Prioridade |
|---|---|---|
| Parsers `_pacienteDeLinha`/`_agendamentoDeLinha` usavam índices literais | Resolvido (usam `indicesColunas`) | ✅ |
| IDs agendamento/evolução/auditoria por `length + 1` (race condition) | Resolvido (`GeradorId.proximo` usa max+1) | ✅ |
| `BackdropFilter` reimplementado inline em telas | Resolvido (o redesign removeu todos os usos) | ✅ |
| Lógica de popup duplicada em dashboard/sessoes | Resolvido (centralizado em `acoes_agendamento.dart`) | ✅ |
| Todas as telas principais possuem testes de widget | — | ✅ |
| Botão de login do web é o do Google (platform view) sobreposto ao desenho | Trade-off aceito para preservar o visual — ver regras abaixo | 🟡 |

### ⚠️ Login no web — regras que não podem ser quebradas

No web o Google Identity Services **não permite login iniciado pela aplicação**
(`GoogleSignIn.authenticate()` lança `UnsupportedError`). A `TelaLogin` sobrepõe
o botão do SDK, quase transparente, ao botão desenhado. Nada disso aparece nos
testes: fora do web `construirBotaoGoogleRenderizado` vira `SizedBox.shrink()`.

- **`Opacity` tem que ser > 0.** Com alpha 0 o Flutter não pinta o filho
  (`RenderOpacity.paint`), e uma platform view só entra no DOM quando pintada —
  o botão deixa de existir e o clique cai no vazio.
- **`IgnorePointer` não segura clique de platform view.** Ele só afeta o
  hit-test do Flutter; o elemento DOM recebe o evento direto. Para bloquear de
  verdade (ex.: enquanto os termos não são aceitos), **não construir o widget**.
- **O GIS limita o botão a 400px** e centraliza. O desenho por baixo tem que
  respeitar a mesma largura, senão as extremidades não respondem ao clique.
- **Não passar hint de usuário na autorização no web.** `conta.authorizationClient`
  envia a conta como hint, e o plugin traduz isso em `prompt: 'select_account'`,
  reabrindo o seletor de contas. Usar `GoogleSignIn.instance.authorizationClient`.

Como diagnosticar: rodar o app e inspecionar o DOM — `flt-platform-view` para
saber se o botão existe, e `elementFromPoint(...).closest('[role="button"]')` nas
bordas e no centro para saber se ele recebe o clique. Screenshot não revela nada
disso.

---

## Identidade visual — abertura e ícone

Três peças usam **o mesmo gradiente** (`FisioGradients.header`: `#8A6FF0` →
`#6C4CE0` → `#4A2FB2`) e **o mesmo símbolo** (coração). Mudou uma, confira as outras.

| Peça | Onde | Observação |
|---|---|---|
| Splash animada | `lib/telas/tela_splash.dart` | ECG PQRST + batimento; termina na métrica exata da `TelaLogin` |
| Splash nativa Android | `android/.../drawable*/launch_background.xml` + `values/colors.xml` | Gradiente, para não piscar branco antes do engine |
| Splash nativa web | `web/index.html` (`#splash-fisio`) | Removida no evento `flutter-first-frame` |
| Ícone do app | `tool/gerar_icones.dart` | Regerar com `make icones` |

### Ícone: regras que não podem ser quebradas

- **Não edite os PNGs à mão.** Eles são saída de `tool/gerar_icones.dart`; a
  próxima execução de `make icones` sobrescreve tudo. Mude o desenho no Dart.
- **O gerador fica em `tool/`, nunca em `test/`** — senão `flutter test` (e a CI)
  reescreveria os ícones a cada execução.
- **Cada tamanho é renderizado direto**, não redimensionado a partir do 1024 —
  é o que mantém o traço limpo a 20px.
- **Zona segura do ícone adaptativo:** a camada de frente tem 108dp de quadro mas
  só 66dp visíveis garantidos. A marca ocupa 50% da largura para caber em
  qualquer máscara de launcher.
- **iOS não aceita canal alfa** no ícone (a App Store rejeita); quem remove é
  `tool/finalizar_icones.py`. Rodar só o gerador Dart deixa os PNGs do iOS
  inválidos para publicação.
- `AndroidManifest.xml` declara `android:icon` **e** `android:roundIcon`; o
  segundo precisa existir como PNG em todas as densidades (launchers pré-API 26),
  não só no `mipmap-anydpi-v26`.

---

## Publicar

```bash
# Web → Firebase Hosting (incrementa versão automaticamente)
make prod-web

# Android → APK release
make prod-android
```

## CI/CD (GitHub Actions)

Pipeline em `.github/workflows/` com fluxo de duas branches (`develop` → `master`):

| Workflow | Dispara em | O que faz |
|---|---|---|
| `deploy-preview.yml` | push em `develop` | Lint + testes + build web → deploy em **preview channel** do Firebase (URL temporária, ambiente de testes). |
| `deploy-prod.yml` | push em `master` | Lint + testes → define a versão (patch +1, ou respeita bump manual do `pubspec.yaml`) → build → deploy **live** no Firebase → commita o bump com `[skip ci]`. |

> Não há workflow de CI separado: a verificação (lint + testes) está embutida nos dois deploys, então código quebrado nunca é publicado. Rode `make ci-local` para verificar localmente antes de subir.

- **Flutter pinado** em `3.44.1` (via `subosito/flutter-action@v2`).
- **Auth Firebase:** Service Account JSON em `FirebaseExtended/action-hosting-deploy@v0`.
- A lógica de bump de versão e cópia de branding replica o target `prod-web` do `Makefile`.
- **Versão:** `pubspec.yaml` = versão do código, `web/version.json` = última
  publicada. Iguais → patch +1 automático; `pubspec.yaml` à frente (bump manual
  de minor/major) → publica exatamente esse número. Ao subir uma minor, edite só
  o `pubspec.yaml`; `web/version.json` é escrito pelo deploy.

### Secrets necessários (GitHub → Settings → Secrets and variables → Actions)

| Secret | Conteúdo |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | **JSON da conta de serviço** (`"type": "service_account"` + `"private_key"`), gerado no Firebase Console → Contas de serviço. **Não** confundir com o arquivo OAuth Client. |
| `GOOGLE_OAUTH_CLIENT_ID_WEB` | Client ID OAuth web. |
| `GOOGLE_OAUTH_CLIENT_ID_ANDROID` | Client ID OAuth Android (pode ser `none` — web-only por enquanto). |

> Android está fora de escopo do CI atual (somente web). `google-services.json` não é necessário no CI.

### Atalhos no Makefile

```bash
make ci-local      # roda localmente o mesmo que a CI (lint + testes + build web)
make release-dev   # mescla a branch atual na develop → dispara deploy de testes (preview)
make release-prod  # mescla develop → master → dispara deploy de produção (pede confirmação)
```

📚 Guia completo (uso, secrets, troubleshooting): `documentacao/CI_CD.md`.

---

## Documentação do Projeto

| Arquivo | Conteúdo | Atualizado? |
|---|---|---|
| `README.md` | Getting started, como rodar, publicar | ✅ |
| `CHANGELOG.md` | Histórico de versões | ✅ |
| `CLAUDE.md` | Este arquivo (contexto para Claude) | ✅ |
| `documentacao/MODELO_DADOS.md` | Estrutura das 5 abas da planilha | ✅ |
| `documentacao/DIAGRAMA_FLUXOS.md` | Navegação e fluxos do app | ✅ |
| `documentacao/ESPECIFICACOES_TELAS.md` | Requisitos funcionais das telas | ✅ |
| `documentacao/SEGURANCA_E_DADOS.md` | LGPD, OAuth, modelo BYODB | ✅ |
| `documentacao/IMPLEMENTAR.md` | Roadmap priorizado | ✅ |
| `documentacao/testes/` | 286 testes automatizados | ✅ |
| `documentacao/CI_CD.md` | Pipeline GitHub Actions: fluxo, secrets, uso e troubleshooting | ✅ |
| `QA/qa.md` | Script QA manual (não é E2E) | ✅ |

---

## ⚠️ REGRAS IMPORTANTES

### 1. Manter Documentação Sincronizada

**TODA vez que você muda o código, VOCÊ DEVE:**

- ✅ Atualizar testes (ou criar novos)
- ✅ Atualizar documentação relevante
- ✅ Atualizar este arquivo (CLAUDE.md) se mudar estrutura, stack ou padrões
- ✅ Atualizar `CHANGELOG.md` com resumo da mudança
- ❌ **NUNCA** commitar sem testes + docs atualizados

### 2. Testes Sempre Atualizados

```bash
# Antes de fazer commit, SEMPRE:
flutter test   # Deve passar 100%
make lint      # Sem warnings
```

### 3. Quando Adicionar Feature

1. **Criar testes primeiro** (TDD)
2. **Implementar código**
3. **Rodar testes** — devem passar
4. **Atualizar documentação**
5. **Atualizar CLAUDE.md** se necessário
6. **Commit** com mensagem clara

---

## Contato e Contexto

Este projeto é desenvolvido por **Rodrigo Lacerda** (lacerdaa.rodrigo@gmail.com).

Para questões sobre estrutura, padrões ou decisões técnicas, **SEMPRE consulte este arquivo primeiro**.

---

**Última atualização:** 2026-07-26  
**Versão:** 1.0.18 (produção) — 1.1.0 pendente de deploy  
**Branches:** master, develop, identidade-visual
