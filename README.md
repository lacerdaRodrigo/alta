# Fisio Home Care

Aplicativo de Fisioterapia Domiciliar desenvolvido em Flutter, com arquitetura Serverless baseada no Google Sheets API (BYODB - Bring Your Own Database) e 100% aderente à LGPD.

## Estrutura do Projeto

Toda a lógica e documentação foram estruturadas seguindo nomenclaturas em Português (PT-BR) para facilitar a manutenção futura.

### Documentação (`/documentacao`)
Toda a documentação técnica, de segurança e de arquitetura do sistema foi movida para a pasta `/documentacao`.
* **Especificações Técnicas:** `ESPECIFICACOES_TELAS.md`, `LOGIN_SCREEN_SPEC.md`, `PACIENTES_SPEC.md`
* **Modelo de Dados & Segurança:** `MODELO_DADOS.md`, `SEGURANCA_E_DADOS.md`, `chaves.md`
* **Arquitetura Visual:** `DIAGRAMA_FLUXOS.md`
* **Testes & QA:** `testes/` (VISAO_GERAL, UNITARIOS, WIDGETS) + `../../QA/qa.md`

### Estrutura do Aplicativo (`/lib`)
* `/telas`: Telas principais do aplicativo (Login, Dashboard, Pacientes, etc.)
* `/componentes`: Widgets reutilizáveis da interface de usuário
* `/provedores`: Gerenciamento de estado utilizando Riverpod
* `/modelos`: Classes de abstração de dados (Pacientes, Agendamentos, Evoluções)
* `/servicos`: Integrações externas (Google Sheets API, OAuth, Speech-to-Text)
* `/utilitarios`: Funções auxiliares (máscaras de CPF, cálculos de idade, validação de datas)

## Tecnologias e Dependências Principais
* **Flutter & Dart:** Framework principal.
* **Riverpod:** Injeção de dependência e controle de estado.
* **Google Sign-In & Google APIs:** Autenticação e integração backend via Sheets.
* **Firebase Hosting:** landing pública em `https://app-fisio-care-2.web.app` e aplicativo em `https://app-fisio-care-2.web.app/app/`.
* **Google Fonts:** Tipografia premium (ex: Inter).
* **Speech to Text:** Para registros clínicos.
* **Url Launcher:** Rotas (Google Maps / Waze).

## Como Executar

### Android (dispositivo físico — recomendado)
1. Ative **Depuração USB** no celular e conecte via cabo.
2. Verifique se o device aparece: `flutter devices`
3. Rode no celular: `make dev-android`

O login Google no Android exige o SHA-1 do keystore debug registrado no Firebase (projeto `app-fisio-care-2`). Após adicionar a impressão digital, baixe o novo `google-services.json` e substitua em `android/app/google-services.json`.

Para obter o SHA-1 debug local:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Web (navegador)
```bash
make dev-web
```

## Como Publicar

### Web
```bash
make prod-web
```

### Android (APK release)
```bash
make prod-android
```

## Ícone do aplicativo
O ícone é desenhado em código (`tool/gerar_icones.dart`) e renderizado pelo engine do Flutter em cada tamanho final — Android (legado, redondo, adaptativo e monocromático), web, iOS, macOS e Windows. Não edite os PNGs à mão; ajuste o desenho e regere:

```bash
make icones
```

## Segurança e LGPD
O aplicativo opera num modelo soberano: o fisioterapeuta conecta a própria conta do Google e atua como Controlador dos dados. Não há servidores centrais de terceiros processando os prontuários.