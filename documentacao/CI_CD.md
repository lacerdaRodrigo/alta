# CI/CD — Integração e Entrega Contínua

> Guia da pipeline automatizada do Alta no **GitHub Actions**.
> Escrito para ser seguido mesmo sem experiência prévia com DevOps.

---

## O que é e por que existe

Antes, publicar o app era manual (`make prod-web` no PC do desenvolvedor).
Agora o **GitHub** faz isso sozinho: a cada alteração enviada, ele roda os testes
e publica o site automaticamente. Isso evita erro humano, garante que nada quebrado
vá ao ar e mantém a versão sempre organizada.

---

## O fluxo de branches (duas branches)

```
        develop ───────────►  Ambiente de TESTES (URL temporária de preview)
            │  (merge quando aprovado nos testes)
            ▼
         master ───────────►  PRODUÇÃO (site oficial app-fisio-care-2.web.app)
```

- **`develop`**: ambiente de testes. Todo push aqui roda lint + testes e publica
  num **preview channel** do Firebase (endereço temporário, isolado da produção).
- **`master`**: produção. Todo push aqui roda lint + testes, **incrementa a versão**,
  publica o site oficial e registra o número da nova versão automaticamente.

> Em ambos os casos, se o lint ou os testes falharem, **a publicação é cancelada** —
> nada quebrado vai ao ar. Não há um workflow de CI separado: a verificação está
> embutida dentro dos dois deploys.

---

## Os 2 workflows (`.github/workflows/`)

| Arquivo | Dispara quando | O que faz |
|---|---|---|
| `deploy-preview.yml` | push em `develop` | `flutter analyze` + `flutter test`, builda e publica no **preview channel** (ambiente de testes). |
| `deploy-prod.yml` | push em `master` | `flutter analyze` + `flutter test`, **incrementa a versão**, builda, publica em **produção** e commita o bump (`[skip ci]`). |

> Para rodar a mesma verificação localmente antes de subir, use `make ci-local`.

Detalhes técnicos:
- **Flutter** fixado em `3.44.1` (`subosito/flutter-action@v2`).
- **Deploy** via `FirebaseExtended/action-hosting-deploy@v0`.
- Cópia das páginas públicas (`branding/*.html`) e bump de versão replicam o
  antigo `make prod-web`.

### Como o número da versão é decidido

`pubspec.yaml` guarda a versão **do código**; `web/version.json` guarda a
**última versão publicada**. No deploy de produção:

- Se as duas são iguais → patch +1 (comportamento padrão, automático).
- Se o `pubspec.yaml` está **à frente** (bump manual de *minor*/*major*, ex.:
  `1.0.18` → `1.1.0`) → o deploy publica exatamente essa versão, sem incrementar.

Ou seja, para lançar uma *minor*, edite só o `pubspec.yaml` e **não mexa** em
`web/version.json` — quem o atualiza é o deploy. A mesma regra vale em
`make prod-web`, para o deploy local não divergir do CI.

---

## Segredos (Secrets) necessários no GitHub

Em **Settings → Secrets and variables → Actions** (aba **Secrets**, não "Variables"):

| Secret | Conteúdo |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | **JSON da conta de serviço** do Firebase (começa com `"type": "service_account"` e tem `"private_key"`). Gerado em: Firebase Console → ⚙️ Configurações do projeto → **Contas de serviço** → **Gerar nova chave privada**. |
| `GOOGLE_OAUTH_CLIENT_ID_WEB` | Client ID OAuth web (`...apps.googleusercontent.com`). |
| `GOOGLE_OAUTH_CLIENT_ID_ANDROID` | Client ID OAuth Android (pode ser `none` enquanto for só web). |

> ⚠️ **Não confundir** o JSON de conta de serviço com o arquivo de "OAuth Client"
> (esse tem `installed`/`web`, `client_secret`, `auth_uri`...). Só o de **conta de
> serviço** funciona para deploy. Usar o arquivo errado dá o erro
> *"Failed to authenticate, have you run firebase login?"*.

---

## Como usar no dia a dia

### Atalhos no Makefile

```bash
make ci-local      # roda lint + testes + build web ANTES de subir (igual à CI)
make release-dev   # mescla a branch atual na develop e publica o ambiente de testes
make release-prod  # mescla develop -> master e PUBLICA EM PRODUÇÃO (pede confirmação)
```

### Passo a passo típico

1. **Desenvolver** na `develop`:
   ```bash
   git checkout develop
   # ...código...
   make ci-local            # confere que está tudo verde localmente (opcional)
   git add . && git commit -m "feat: minha mudança"
   git push origin develop
   ```
   → dispara o **Deploy de Testes**; a URL de preview aparece em **Actions**, na etapa
   *"🚀 Publicar no ambiente de testes"* (formato `https://app-fisio-care-2--develop-XXXX.web.app`).
   Para pegar a URL pelo terminal: `firebase hosting:channel:list --project app-fisio-care-2`.

2. **Publicar em produção** (quando aprovado nos testes):
   ```bash
   make release-prod        # mescla develop -> master e pede confirmação (s/N)
   ```
   → publica em `https://app-fisio-care-2.web.app`, sobe a versão (ex.: 1.0.7 → 1.0.8)
   e registra o commit do bump.

### Acompanhar as execuções

👉 `https://github.com/lacerdaRodrigo/app-fisio2/actions`
- ✓ verde = sucesso · ✗ vermelho = falha (clique na execução → no job → na etapa
  vermelha para ver o erro).

---

## Solução de problemas (troubleshooting)

| Sintoma | Causa provável | Como resolver |
|---|---|---|
| `Failed to authenticate, have you run firebase login?` | `FIREBASE_SERVICE_ACCOUNT` vazio ou com arquivo errado (OAuth em vez de conta de serviço) | Gerar a chave correta (conta de serviço) e recolar no secret. |
| Etapa **🔐 Conferir credencial** falha | Secret vazio ou salvo na aba "Variables" | Recriar na aba **Secrets** com o nome exato. |
| `403 ... does not have permission` | Conta de serviço sem permissão de Hosting | Conceder o papel **Administrador do Firebase Hosting** à conta em GCP → IAM. |
| Testes falham na CI mas passam local | Versão de Flutter diferente | A CI usa `3.44.1`; alinhe localmente (`flutter --version`). |

---

## Relação com o `make prod-web` antigo

O target `make prod-web` (deploy local direto pelo PC) **continua existindo** como
alternativa de emergência, mas o **caminho recomendado agora é via Git/CI**
(`make release-prod`). Evite usar os dois para a mesma versão, pois ambos
incrementam o número de versão e podem se desencontrar.

---

**Última atualização:** 2026-06-17
