# Changelog — Alta

## [Não lançado]

### Repositório e infraestrutura

- **O repositório passou a se chamar `alta`.** O produto foi renomeado para "Alta" em julho, mas a embalagem ficou para trás: o repo ainda era `app-fisio2`, um nome de rascunho que contradizia a marca em tudo que é público (URL, clone, badges, links compartilhados). `github.com/lacerdaRodrigo/app-fisio2` → `github.com/lacerdaRodrigo/alta`. O GitHub mantém redirect da URL antiga indefinidamente, então clones existentes não quebram; ainda assim o `origin` local foi reapontado. Também renomeada a pasta local para `~/Estudos/alta`.
- **`master` → `main`.** Além do padrão atual do GitHub, a troca precisou ser atômica: `deploy-prod.yml` dispara em `on: push` **e** faz `git pull --rebase origin <branch>` no passo de commit do bump de versão. Mudar só um dos dois quebraria a etapa final de todo deploy de produção. Atualizados juntos `deploy-prod.yml`, o target `release-prod` do `Makefile`, `documentacao/CI_CD.md` e `CLAUDE.md`. O `deploy-preview.yml` dispara em `develop` e não foi tocado.
- **Branches mortas removidas.** `ajuste-header-inicio`, `editar_sessao`, `identidade-visual` e `migracao-google-sign-in-7` já estavam mescladas; `correcao-bug` apontava para o mesmo commit de `develop` (o conteúdo entrou em produção por squash, então o `--merged` não a reconhecia). Restam `main` e `develop`, local e remoto.
- **`LICENSE` (novo) — proprietária.** O repositório é público como portfólio, mas o Alta é produto comercial; sem licença, o padrão legal é "todos os direitos reservados" de forma implícita e ambígua. A licença agora diz explicitamente o que é permitido (ler, estudar, avaliar, citar com atribuição) e o que não é (uso comercial, redistribuição, obra derivada, operar o serviço para terceiros, usar a marca), e registra que as dependências de `pubspec.yaml` mantêm suas próprias licenças.
- **`SECURITY.md` (novo).** Canal de reporte com prazos, escopo dentro/fora, e o ponto que muda a avaliação de risco deste projeto: sendo BYODB, um vazamento do repositório **não expõe dados de paciente** — o que importa são falhas de autenticação, de escopo OAuth, de manipulação de token ou de lógica que levem o app a gravar na planilha errada.
- **`README.md` reescrito como vitrine.** Era um índice de pastas. Agora abre pelo problema (a rotina real do fisioterapeuta domiciliar e a responsabilidade LGPD que um SaaS tradicional transfere ao profissional), explica o BYODB como resposta, e traz badges de CI/versão/testes/licença, diagrama Mermaid da arquitetura (o app fala direto com Drive e Sheets; o Firebase Hosting só serve estático), tabela de stack, instruções de execução, testes e CI/CD. A pendência do `google-services.json` do `com.rodrigo.alta` foi preservada. Seção de screenshots criada com os arquivos ainda pendentes.
- **Ruído removido:** `package-lock.json` (lockfile npm órfão, sem `package.json`, que ainda carregava `"name": "app-fisio2"`) apagado, e `.playwright-mcp/` removido do índice e adicionado ao `.gitignore` — artefato de sessão de ferramenta, não pertence ao repositório.

### Correções
- **Login no web não completava no iPhone, e no resto sempre pedia duas tentativas.** O fluxo antigo abria dois popups do Google: identidade pelo botão do GIS sobreposto ao desenho, e autorização dos escopos Drive/Sheets num segundo popup disparado automaticamente pelo stream `authenticationEvents` — sem clique nenhum nesta página, já que o clique original tinha sido consumido pela interação inteira com o primeiro popup. O Chrome tolerava isso na maioria das vezes (daí precisar tentar duas vezes); o WebKit do iOS — usado por todo navegador no iOS, Chrome incluso, por exigência da Apple — bloqueava sempre, impedindo o login por completo. Um cliente relatou não conseguir entrar de jeito nenhum pelo iPhone.
  - **Login interativo no web virou um popup só.** `AutorizadorGoogleWeb.entrarInterativo` (`lib/servicos/autorizador_google_web.dart`) pede conta e consentimento dos escopos juntos, chamado sem nenhum `await` real entre o toque do usuário e `requestAccessToken()` — preserva a ativação do usuário que o navegador exige para não bloquear o popup. Identidade (nome/e-mail) passa a vir do próprio access token via `userinfo` do Google.
  - **Removido o botão do GIS sobreposto ao desenho** (`componentes/botao_google_renderizado*.dart`, agora deletados): `_BotaoEntrarGoogle` virou um `GestureDetector` comum, sem platform view nem truques de `Opacity`.
  - `entrarComGoogle` (`provedor_autenticacao.dart`) passou a pular a restauração silenciosa de sessão no web (o cache do token é em memória e quase nunca ajuda ali) e a rodar a limpeza de `planilha_id` em paralelo com o login em vez de antes — cada operação assíncrona antes do popup era risco de o WebKit não reconhecê-lo mais como originado do clique.
  - Nova interface `AutorizadorGoogle.entrarInterativo`, implementada por plataforma; nativo (Android) mantém exatamente o comportamento anterior (`GoogleSignIn.authenticate()` + `authorizationClient`).
  - `mensagemErroLoginGoogle` ganhou uma mensagem específica para popup bloqueado pelo navegador.
  - Sem cobertura automatizada — o fluxo depende do SDK real do Google no navegador. Validar manualmente em Chrome desktop, Safari/iOS e Chrome/iOS: primeiro login, refresh de página, sessão acima de 1h.
- **Os links de Termos de Uso e Política de Privacidade na tela de login não abriam nada.** Os dois eram `TextSpan` apenas estilizados (cor da marca, negrito) dentro do `Text.rich` do consentimento — e `TextSpan` sem `recognizer` não recebe toque. Na prática o usuário tinha de aceitar os termos sem ter como lê-los, o oposto do que a tela promete e do que a LGPD exige. As páginas sempre existiram publicadas (`/termos.html` e `/privacidade.html`, com rewrites próprios no `firebase.json`); faltava o caminho até elas.
  - `TapGestureRecognizer` em cada span, criado no `initState` e liberado no `dispose` — criá-lo no `build` vazaria um por quadro. Os links ganharam sublinhado, porque cor sozinha não sinaliza que algo é clicável.
  - Abre com `LaunchMode.externalApplication`: nova aba no web, navegador do sistema no Android. Em nenhum dos dois o usuário perde a tela de login nem o estado do checkbox. Se o launcher falhar, um snackbar mostra a URL para acesso manual.
  - Novo `lib/utilitarios/links_legais.dart` como fonte única das URLs.
  - +4 testes em `tela_login_test.dart`, inclusive um que garante que **tocar no link não marca o checkbox** — o link fica na mesma linha dele, e aceitar os termos sem intenção seria pior do que não abrir a página.
- **Cópia da planilha no Drive virava a base ativa em silêncio.** `ServicoGoogleDrive.buscarPlanilhaBanco()` consultava `name contains '__saas_fisio_db__'` ordenando por `modifiedTime desc` e pegava o primeiro resultado — então `__saas_fisio_db__ (1)` ou `Cópia de __saas_fisio_db__`, que o Drive cria sozinho ao duplicar ou restaurar, entrava no páreo e virava o destino das gravações assim que fosse a mais recente. A base antiga apenas "parava de receber sessões", sem erro nenhum.
  - A busca passou a usar **nome exato** (`name = '__saas_fisio_db__'`), o que elimina as cópias; e o novo `buscarPlanilhasBanco()` devolve a lista completa em vez de só o primeiro ID.
  - **Quando ainda assim houver mais de uma planilha com o nome exato**, o app segue usando a mais recente — mas agora avisa: `RepositorioDadosGoogle.planilhasDuplicadas` chega via `DadosCarregados` ao novo `provedorPlanilhasDuplicadas` e a tela de Configurações mostra um alerta no card "Planilha conectada" pedindo para apagar ou renomear as outras. Silêncio aqui é o que tornava o problema invisível.
- **Toda planilha era tratada como esquema versão 1.** `ServicoGoogleSheets.lerVersaoEsquema` fazia `valores[0].toString()` sobre a resposta da Sheets API, que vem como lista de linhas: o texto resultante era `"[2]"`, o `int.tryParse` falhava e o `catch` devolvia 1. Uma planilha de versão futura passava por `validarVersao` sem reclamar, justamente o cenário que essa validação existe para barrar. Passou a ler a primeira célula da primeira linha.
- **O login no web pedia para escolher a conta duas vezes.** No web o GIS separa identidade de autorização, então um login sempre passa por dois passos: o botão do Google (ID token) e o token client dos escopos Drive/Sheets. O segundo reabria o seletor de contas porque `google_sign_in_web` amarra hint e prompt num único ternário (`src/gis_client.dart:135`): `prompt: userHint == null ? '' : 'select_account'`. Os dois caminhos oferecidos pelo plugin falham quando o navegador tem mais de uma sessão Google — `conta.authorizationClient` manda o hint e por isso ganha `select_account`; `GoogleSignIn.instance.authorizationClient` (o que estava em uso) evita o `select_account` mas manda `login_hint: null`, e aí o Google pergunta qual conta usar. Não aparecia no Android, onde `conta.authorizationClient` autoriza sem UI nenhuma.
  - **Novo `lib/servicos/autorizador_google.dart`** (+ `_base`, `_stub`, `_web`), no mesmo padrão de import condicional do `botao_google_renderizado.dart`. No web a autorização passa a falar direto com o GIS via `google_identity_services_web` — que já era dependência transitiva e agora é direta — montando o token client com `login_hint: <e-mail da conta>` **e** `prompt: ''`: o par que o plugin não permite. O segundo passo vai direto para a conta escolhida no botão e não aparece quando o consentimento já existe. Fora do web nada muda: o stub mantém `conta.authorizationClient`.
  - **Token cacheado por e-mail, com margem de 1 min antes da expiração e requisição deduplicada.** No web o access token vale 1h e não se renova sozinho; cachear por conta impede que trocar de usuário reaproveite o token do anterior, e a deduplicação impede que duas chamadas simultâneas às APIs abram dois popups de autorização.
  - Sem cobertura automatizada — o fluxo depende do SDK real do Google no navegador. Validar manualmente: primeiro login com conta sem consentimento prévio, navegador com duas contas Google logadas, refresh de página e sessão acima de 1h.
- **Clicar numa evolução na tela "Evoluções" não abria nada.** O card da lista (`_CardEvolucaoGeral`, em `tela_historico_geral_evolucoes.dart`) era um `FisioCard` sem `onTap` — e `FisioCard` só vira `InkWell` quando recebe um. Não era um toque que falhava: não havia toque nenhum. Como o card corta o texto clínico em `maxLines: 3`, evolução mais longa que isso ficava **impossível de ler por completo** a partir dessa tela.
  - **Novo `lib/componentes/modal_detalhes_evolucao.dart`:** bottom sheet somente leitura, no padrão do `modal_detalhes_paciente.dart`. Mostra paciente, data, condição, status de presença, horário real, dor, local, PA/FC e o texto clínico **inteiro** — em `SelectableText` rolável, sem `maxLines`, para poder copiar. Ligado ao toque nas duas visualizações da tela ("Lista" e "Por paciente").
  - **A janela de 24h nunca escondeu conteúdo — mas o caminho até ele sumia.** A regra sempre bloqueou só a *edição*: `TelaRegistroEvolucao` renderiza o formulário completo preenchido mesmo passadas 24h, com banner e campos `readOnly`. O problema é que a única porta para ela, o botão "Editar" da timeline, **desaparecia** depois das 24h, deixando o registro antigo sem entrada nenhuma. O modal agora abre **sempre**; a janela decide apenas se aparece o botão "Editar" ou o rodapé `Registro fechado — mais de 24h`. Sem paciente na lista carregada a edição também não é oferecida — `TelaRegistroEvolucao` exige um `Paciente` não-nulo.
- **Evolução sem `Data_Registro` na planilha ficava editável para sempre.** `Evolucao.deLinhaPlanilha` caía em `DateTime.now()` quando a coluna estava vazia ou corrompida, então a linha renascia dentro da janela das 24h a cada carregamento do app. Passou a cair em `Data_Atendimento`, que é a estimativa conservadora correta.
- **Regra das 24h centralizada.** `DateTime.now().difference(...).inHours < 24` estava copiada em `tela_registro_evolucao.dart` e `tela_historico_evolucoes.dart`, e o modal novo seria a terceira cópia. Agora é `Evolucao.janelaEdicao` + `editavelEm(agora)` / `editavel` no modelo — a versão com parâmetro permite testar a borda das 24h sem depender do relógio do sistema.
- Total de testes: **295 → 309** (`evolucao_test.dart` 6 → 11, novo `modal_detalhes_evolucao_test.dart` com 6, `tela_historico_geral_evolucoes_test.dart` 7 → 10).
- **Os cards do topo cortavam o contador de sessões na tela Início.** Em `tela_dashboard.dart`, os stat tiles ("Pacientes ativos" / "Pendências") sobem 38px (`Transform.translate`) para flutuar sobre o gradiente, mas o `FisioGradientHeader` reservava só 30px de padding inferior. Como `30 - 38 = -8`, eles invadiam 8px do número do dia, que tem 44px de altura — o "1" aparecia cortado ao meio no aparelho. Padding inferior passou a **64** (38 do deslocamento + 26 de folga), o mesmo respiro que a `TelaFinanceiro` já usava com seu par 78/-52.
  - Novo teste de regressão **geométrico** em `tela_dashboard_test.dart`: compara `getTopLeft` do primeiro `FisioStatTile` com `getBottomLeft` do texto "sessão". Um finder de texto não detecta sobreposição — o teste antigo passava com o bug na tela. Verificado que ele falha com o padding antigo (topo do card em 170.0 contra fim do texto em 175.63).
- **Teste `filtro Vencidas` quebrava no CI de madrugada.** Em `tela_sessoes_test.dart`, o teste "deve listar sessões vencidas" montava a sessão com a data de hoje e a hora fixa `08:00` do helper. Como `Agendamento.estaAtrasado` compara `inicioPrevisto` (data **e** hora) com o relógio, a sessão só ficava vencida depois das 08:00 — o runner do GitHub em UTC via `Found 0 widgets with text "Vencida"`. O horário passou a ser derivado de `DateTime.now()` (um minuto atrás, com clamp na meia-noite) por meio dos novos helpers `_instanteJaVencido`/`_hhmm`, que também substituem o cálculo já duplicado no grupo "filtros por período e status".
- **Frase do header reescrita:** `Você tem hoje, 26 de julho` deixava a vírgula pendurada, porque o complemento ("1 sessão") vem numa linha separada e em corpo muito maior. Agora lê `Hoje, 26 de julho, você tem` seguido do número — a frase fecha em si. Total **295 testes**.

### Testes
- **Camada de serviço deixou de ser um ponto cego** — eram 5 testes (só `preferencias_test.dart`) para os serviços que falam com a rede. Novo `test/unitarios/auxiliares/servidor_google_fake.dart`: um Drive/Sheets falso no nível do HTTP (`MockClient` do `package:http`), já que `DriveApi`/`SheetsApi` são construídos a partir de um `http.Client` e esse é o único ponto de injeção existente. A vantagem sobre um fake de classe é exercitar o que de fato quebrou nesta camada: a query do Drive, o range de cada aba e a ordem dos valores gravados.
- **+48 testes (312 → 360):** `servico_google_drive_test.dart` (6 — nome exato, ordenação, arquivos sem id), `servico_google_sheets_test.dart` (10 — versão do esquema, criação de abas, cabeçalhos, `USER_ENTERED`), `servico_repositorio_dados_test.dart` (29 — cache/preferências/criação de planilha, duplicatas, parsing de linha curta, valor com vírgula, auditoria com `GeradorId`, ranges de atualização) e 3 na `tela_configuracoes_test.dart` para o aviso de duplicata.
- Dois testes fixam regressões que já custaram caro: o ID da planilha continua persistido mesmo se gravar a aba `Versao` falhar (senão a tentativa seguinte cria **outra** planilha), e `registrarAuditoria` gera `L008` a partir do maior ID existente, não de `length + 1`.
- **Links legais na tela de login (4):** cada link abre sua página, o toque não marca o checkbox, e falha do launcher mostra a URL no snackbar. O toque é dado por coordenada sobre o span (`getOffsetForCaret`) — `tester.tap(find.text(...))` acertaria o `RichText` inteiro e passaria mesmo sem `recognizer` nenhum.

## [1.1.1] — 2026-07-26

> Versão *minor* planejada como 1.1.0, publicada como **1.1.1**: `pubspec.yaml` e
> `web/version.json` foram para produção com o mesmo valor, e o workflow trata
> igualdade entre os dois como "essa versão já saiu" e incrementa o patch. Para
> um bump manual valer, o `web/version.json` precisa ficar na versão anterior e
> deixar o deploy escrevê-lo.


### Marca
- **O produto passou a se chamar `Alta`.** Antes convivia com três nomes — `Fisio Home Care` (título e telas), `FisioCare` (label do launcher) e `fisio_home_care` (pacote Dart, iOS, macOS) — e nenhum era defensável: `fisiocare.com.br` já pertence a terceiro e a categoria está saturada de "Fisio+X" (ZenFisio, FisioGestor, FISIO.APP, FisIA), o que enfraquece marca, ASO e SEO. "Alta" é o desfecho de todo tratamento fisioterapêutico: nomeia o resultado entregue, não a ferramenta; 4 letras, sem acento (não divide a grafia entre marca e domínio).
  - **A palavra-chave migrou para a listagem:** marca e launcher exibem `Alta`; `<title>`, `manifest.name` e o nome nas lojas usam `Alta — Fisioterapia Domiciliar`. Resolve o único ponto fraco do nome (palavra comum) sem sujar a marca.
  - **Tipografia do wordmark:** de 15 letras para 4, o título precisou crescer — `fontSize` 28 → 44 e `letterSpacing` -0.6 → -1.5, replicado em `TelaSplash`, `TelaLogin` e na splash HTML. Os três **têm** de bater: o cross-fade da abertura só é invisível com o logotipo na mesma métrica.
  - **Identificadores:** `applicationId`/`namespace` `com.rodrigo.fisio_care` → `com.rodrigo.alta` (com `MainActivity.kt` movido de diretório), pacote Dart `fisio_home_care` → `alta` (≈30 arquivos de import) e bundle do macOS. Trocado agora porque o app **ainda não foi publicado na Play Store** — depois da primeira publicação o `applicationId` é permanente para sempre.
  - **`__saas_fisio_db__` foi mantido de propósito:** é o nome pelo qual o app localiza a planilha no Drive do usuário; renomear faria quem já está em testes perder a base. O projeto Firebase (`app-fisio-care-2`) também ficou como está — trocá-lo obrigaria a refazer o secret de deploy, as origens OAuth e o redirect URI, com ganho zero.
  - **Pendência externa obrigatória:** o build Android quebra com `No matching client found for package name 'com.rodrigo.alta'` até o `google-services.json` ser regerado e um cliente OAuth Android ser criado para o novo pacote. Ver README.
  - Termos de uso, política de privacidade e páginas institucionais (`web/`, `branding/`) atualizados; testes de `TelaSplash`/`TelaLogin` passaram a afirmar o nome novo.

### Correções
- **Erro de configuração do login aparecia como cancelamento silencioso.** Na migração para `com.rodrigo.alta` o login falhava e a tela voltava sem mensagem nenhuma. Duas causas somadas:
  - `contasConectadas.listen(...)` em `provedor_autenticacao.dart` não tinha `onError`, e é justamente para esse stream que `ServicoAutenticacaoGoogleReal` encaminha os erros de `authenticationEvents` (`onError: _contasController.addError`). O erro virava `Unhandled Exception` no log em vez de estado na UI. Adicionado `onError` nos dois listeners, ambos passando por `mensagemErroLoginGoogle`.
  - O plugin classifica como `GoogleSignInExceptionCode.canceled` **tanto** a desistência do usuário quanto `[16] Account reauth failed`, que na verdade é o Google recusando o app (`This android application is not registered to use OAuth2.0`). `mensagemErroLoginGoogle` passou a separar os dois casos e, no segundo, dizer o que resolve: criar um cliente OAuth do tipo **Android** no Google Cloud Console — cadastrar a impressão digital só no Firebase não basta (foi exatamente o que travou o login por ~40min).
  - Novo `test/unitarios/utilitarios/mensagens_erro_google_test.dart` (7 testes) — total **293 testes**.
- **`make check-android-oauth` dava falso positivo.** Ele fazia `grep '"client_type": 1'` no `google-services.json` inteiro, então encontrava o cliente Android de *qualquer* pacote — continuou passando depois da renomeação, enquanto o arquivo só tinha o cliente do pacote antigo. Substituído por `tool/verificar_oauth_android.py`, que lê o `applicationId` do `build.gradle.kts` e exige que **aquele** pacote tenha `client_type: 1`, com mensagem apontando a correção.

### Design
- **Ícone do aplicativo próprio (adeus logo padrão do Flutter):** marca nova — coração (mesmo símbolo da `TelaLogin`/`TelaSplash`) atravessado por um pulso de eletrocardiograma **em espaço negativo**, sobre o gradiente violeta. A linha do pulso fica abaixo do meio do coração e o spike costura as duas metades, então a silhueta continua lendo como coração mesmo a 20px.
  - **Gerado por código, não por editor:** `tool/gerar_icones.dart` desenha o ícone vetorialmente e o renderiza com o próprio engine do Flutter **em cada tamanho final** — nada sai de redimensionamento, então o traço fica limpo nos ícones pequenos. Fica fora de `test/`, então `flutter test` não o executa. `tool/finalizar_icones.py` (Pillow) faz o que o engine não entrega: remove o canal alfa dos ícones iOS (a App Store rejeita ícone com transparência) e empacota o `.ico` do Windows. Regerar tudo: `make icones`.
  - **Android:** ícone legado (48→192px), `roundIcon` circular para launchers pré-Android 8, **ícone adaptativo** (`mipmap-anydpi-v26/ic_launcher.xml`) com fundo em gradiente (`drawable/ic_launcher_background.xml`) e frente respeitando a zona segura de 66dp, mais a camada **monochrome** para os ícones temáticos do Android 13+. `AndroidManifest.xml` passou a declarar `android:roundIcon`.
  - **Web:** `favicon.png` (16→32px), `Icon-192/512` e as variantes `maskable` (sangrando até a borda, marca dentro da zona segura). `manifest.json` deixou de ser o padrão do Flutter — nome "Fisio Home Care", short name "FisioCare", descrição real e cores da marca (`theme_color` `#6C4CE0`, `background_color` `#4A2FB2`, casando com a splash); `index.html` ganhou `<meta name="theme-color">`.
  - **iOS/macOS/Windows:** as 15 imagens do `AppIcon.appiconset` do iOS, os 7 tamanhos do macOS (estilo squircle com margem) e o `app_icon.ico` do Windows com 7 tamanhos.
  - Validado com `flutter build apk --debug` (recursos do ícone adaptativo compilam) e por inspeção visual dos PNGs de 16px a 1024px.
- **Splash de abertura própria (`lib/telas/tela_splash.dart`):** a abertura padrão do Flutter (tela branca até o primeiro frame) foi substituída por uma animação de marca com tema de sinal vital, coerente com a `TelaLogin`. São três camadas:
  - **Nativa (antes do engine subir):** `android/app/src/main/res/drawable*/launch_background.xml` passou de branco para o gradiente violeta da marca (cores em `values/colors.xml`, espelhando `FisioCores`), e `NormalTheme` usa `fisio_primary_dark` — sem piscar branco entre o launch screen do sistema e o Flutter. No web, `web/index.html` ganhou uma splash em HTML/CSS com o mesmo gradiente, logotipo e ECG, removida no evento `flutter-first-frame` (com timeout de segurança de 12s).
  - **Animada (Flutter):** 2,4s de coreografia sobre `FisioGradients.header` — brilho radial abrindo atrás do logotipo, tile de vidro entrando com escala + rotação, traçado de **eletrocardiograma com morfologia PQRST real** desenhado da esquerda para a direita (`PathMetric.extractPath`) com ponto luminoso na ponta, anéis de pulso propagando a cada pico R e título revelado por *wipe*. O batimento do logotipo usa curva de sístole real ("lub-dub": pico forte + eco de 45%), não um seno.
  - **Handoff sem emenda:** a splash termina com o logotipo exatamente na métrica da `TelaLogin` (74px, raio 24, `Alignment(0, -0.45)`, mesmos título e subtítulo), então o `pushReplacement` com cross-fade de 420ms parece continuidade, não troca de tela.
  - **Acessibilidade:** com `MediaQuery.disableAnimations` (reduzir movimento) a animação é pulada e o app vai direto ao login; o CSS da splash web respeita `prefers-reduced-motion`.
  - `main.dart` passa a abrir em `TelaSplash`. Novo `test/widgets/telas/tela_splash_test.dart` (7 testes: conteúdo da marca, ECG, não navegar antes do fim, navegar ao fim, rota substituída, movimento reduzido, descarte no meio da animação) — total **286 testes**.
- **Redesign visual completo:** nova paleta violeta `#6C4CE0` (primary) + verde-sálvia `#7CB9A8` (secondary), fonte `PlusJakartaSans`. Aplicado a todas as telas principais (`lib/telas/*.dart`) e ao design system compartilhado (`lib/componentes/design_system.dart`). Telas passam a ser componentes "somente corpo" (sem `Scaffold`/bottom-nav próprios, exceto Login), hospedadas por um shell de navegação com `FisioBottomNav`.
  - `TelaPacientes` deixou de receber `filtroInicial`; o filtro (`Ativos`/`Todos`/`Arquivados`) agora é estado interno trocado via chips, e a abertura de um paciente passa a ser feita por callback (`onAbrir`) em vez de abrir um modal diretamente.

### Alterado
- **"Histórico de evoluções" movido da tela Início para a tela Pacientes:** o card no rodapé da Home foi removido; o acesso agora é um botão compacto "Evoluções" (ícone `history_edu`) ao lado dos filtros `Ativos/Todos/Arquivados`. Abre `TelaHistoricoGeralEvolucoes`, que lista todas as evoluções de todos os pacientes (com alternância Lista / Por paciente). Testes atualizados: Home não exibe mais o card; novo teste em `tela_pacientes_test.dart` cobre o botão abrindo o histórico — total **279 testes**.
- **Migração do `google_sign_in` 6.2.1 → 7.2.0 (+ `google_sign_in_web` 1.1.3):** a 7.x separa autenticação (quem é o usuário) de autorização (acesso a Drive/Sheets), que era exatamente a distinção ausente na 6.x e origem dos bugs de login no web. `signIn()`/`signInSilently()` dão lugar a `authenticate()`/`attemptLightweightAuthentication()`, e os tokens passam a vir de `conta.authorizationClient` (`authorizationForScopes()` → `authorizeScopes()` se necessário, e `authorizationHeaders()` por requisição). O escopo `https://www.googleapis.com/auth/spreadsheets` — removido no downgrade — foi restaurado; sem ele, uma conta Google sem consentimento prévio não conseguiria usar a Sheets API.
  - **Login no web agora parte do botão do Google.** No web `GoogleSignIn.authenticate()` lança `UnsupportedError` e `supportsAuthenticate()` devolve `false`: o Google Identity Services só aceita login iniciado pelo widget que ele mesmo renderiza. Para preservar o visual do redesign, `TelaLogin` sobrepõe o botão do GIS (praticamente invisível) ao botão desenhado do app. O widget vem de `lib/componentes/botao_google_renderizado.dart`, com import condicional (`dart.library.js_interop`) para manter `package:google_sign_in_web` fora do build Android/iOS e dos testes, que rodam na VM do Dart.
  - **Três armadilhas da sobreposição, encontradas inspecionando o DOM no navegador** (nenhuma é observável nos testes de widget, porque fora do web o componente vira um `SizedBox.shrink()`):
    - `Opacity(opacity: 0)` **não renderiza o botão**: `RenderOpacity.paint` retorna sem pintar o filho quando o alpha é zero (`proxy_box.dart`), e uma platform view só é anexada ao DOM quando pintada — o botão do Google não existia na página e o clique caía no vazio (era a causa de "o botão não clica, está estático"). Usado `0.01`, que vira alpha 3/255.
    - `IgnorePointer` **não protege uma platform view**: ele só afeta o hit-test do Flutter, e o botão do GIS é um elemento DOM que recebe o clique direto — dava para entrar **sem aceitar os termos de uso**. O botão passou a só ser construído quando o login está liberado.
    - O GIS renderiza o botão com **no máximo 400px**, centralizado no espaço disponível. Como o botão desenhado ocupava a largura toda, numa janela larga as extremidades ficavam sobre o container vazio do GIS e não respondiam ao clique. O desenho passou a ser limitado aos mesmos 400px.
  - `ServicoAutenticacaoGoogle` ganhou `suportaLoginProgramatico`; `entrarComGoogle()` encerra o carregamento sem chamar `entrar()` quando ele é `false`, senão o botão do Google ficaria coberto por um `IgnorePointer` permanente.
  - `inicializar()` passou a memorizar o `Future` — `GoogleSignIn.instance.initialize()` só pode rodar uma vez, e chamadas concorrentes apareciam no console como `google.accounts.id.initialize() is called multiple times`.
  - **Evita a segunda escolha de conta no web.** Autenticação e autorização são etapas separadas na 7.x, então um login abria dois popups: o botão do GIS (identidade) e, logo depois, o consentimento de escopos. O segundo ainda exigia escolher a conta de novo porque `google_sign_in_web` monta o token client com `prompt: 'select_account'` sempre que recebe um hint de usuário (`src/gis_client.dart`), e `conta.authorizationClient` envia a conta como hint. No web o app passou a usar `GoogleSignIn.instance.authorizationClient`, que não manda hint (`prompt: ''`): o Google reaproveita a sessão ativa e só mostra o seletor quando há ambiguidade real entre contas. Fora do web nada muda — `conta.authorizationClient` continua sendo usado no fluxo nativo, já validado no Android.
  - **Validado manualmente em 2026-07-23:** login funcionando no web e no Android, com uma única escolha de conta em ambos. Seguem sem verificação (nenhum teste automatizado cobre o SDK real do Google): sessão com mais de 1h — no web o access token expira em 3600s e não é renovado pelo plugin, e `obterHeaders()` resolve os headers a cada requisição justamente por isso — e o primeiro login com conta Google sem consentimento prévio, que é o único cenário capaz de exercitar o escopo `spreadsheets` restaurado. Total **277 testes**.

### Correções
- **Tocar em um paciente na lista não abria nada (regressão do redesign):** a abertura de um paciente passou a depender do callback `onAbrir` de `TelaPacientes`, mas o shell de navegação (`TelaDashboard`) montava a aba com `const TelaPacientes()` **sem** passar o callback, então o `onTap` do card caía num `onAbrir?.call(p)` nulo. Ligado `onAbrir` a `mostrarModalDetalhesPaciente`, o bottom sheet de detalhes com as ações Editar/Nova Evolução/Histórico/Arquivar. Novo teste de regressão em `tela_dashboard_test.dart` (tocar no card abre o modal). — total **278 testes**.
- **Campo de busca ilegível e grande sobre o gradiente (Pacientes e Sessões):** `FisioSearchField` usava fill translúcido com texto/placeholder brancos sobre o gradiente — sobre as regiões claras lia como "branco no branco". Redesenhado como pill branco flutuante, compacto, sem borda cinza — sombra violeta suave para profundidade, ícone e placeholder em violeta suave (`primary` alpha 0.55). Legível em qualquer região do gradiente e on-brand.
- **Campo de busca duplicava o input no web:** a busca faz `setState` a cada tecla e `FisioSearchField` era `StatelessWidget` com `TextField` sem controller/foco próprios; no Flutter web cada rebuild podia desincronizar o `<input>` nativo do DOM, aparecendo um segundo campo fantasma ao clicar. Convertido para `StatefulWidget` com `TextEditingController` + `FocusNode` persistentes (descartados no `dispose`), e removido o `isCollapsed`/altura fixa (usa `contentPadding`) — layout web estável, um único campo. Diagnóstico feito renderizando o componente isolado em Chrome headless.
- **Login continuava navegando para o Dashboard duas vezes (causa remanescente):** a correção anterior removeu o `state = ...` redundante em `entrarComGoogle()`, mas a segunda notificação vinha de outro lugar — `ServicoAutenticacaoGoogleReal.entrar()` publica em **dois** streams para um único login (`_sessoesController` e `_contasController`), e cada listener em `AutenticacaoNotificador.build()` faz seu próprio `state = state.copiarCom(...)`. Como `EstadoAutenticacao` não sobrescreve `==`, as duas emissões notificam; a segunda ainda carrega `estaAutenticado: true` (preservado pelo `copiarCom`). O listener de `TelaLogin` testava só `proximo.estaAutenticado`, sem checar a transição, e `TelaLogin` permanece montada durante a animação do `pushReplacement` — logo, dois `pushReplacement(TelaDashboard)`. O primeiro Dashboard era desmontado com `carregarDadosReais()` em voo, e o `ref.read()` depois do `await` lançava `Bad state: Using 'ref' ... unmounted`, que virava a tela "Não foi possível carregar os dados da planilha". Corrigido em três frentes: (1) `TelaLogin` ganhou o flag `_navegou`, tornando a navegação idempotente; (2) `entrar()` passou a publicar a conta **antes** da sessão, para que a virada de `estaAutenticado` seja a última notificação do login; (3) `carregarDadosReais`/`_executarCarregamento` resolvem todos os notifiers e o repositório numa struct (`_DependenciasCarregamento`) **antes** de qualquer `await`, para o carregamento sobreviver à desmontagem do widget que o disparou. Novo teste com `NavigatorObserver` garante uma única substituição de rota mesmo com duas emissões autenticadas — total **276 testes**.
- **`planilha_id` podia ser apagado logo após ser salvo:** `_autenticarComSessao` disparava `Preferencias.limparPlanilhaId()` sem `await`, enquanto `entrarComGoogle()` já fazia a mesma limpeza (aguardada) antes do login. A chamada solta podia completar **depois** de `obterPlanilhaId()` ter gravado o ID da planilha recém-criada, apagando a referência e forçando uma busca no Drive no login seguinte. Removida a chamada duplicada.
- **Botão "Continuar com Google" não travava durante o login (regressão do redesign):** o `ElevatedButton` original tinha `onPressed: (estaCarregando || !termosAceitos) ? null : ...`, desabilitando de verdade o clique. O redesign trocou por um `GestureDetector` com `onTap: _entrar` incondicional — só a opacidade mudava visualmente, o toque nunca era bloqueado. Tocar de novo enquanto o primeiro login ainda estava em andamento disparava uma segunda chamada concorrente a `entrarComGoogle()` (visível no console como `google.accounts.id.initialize() is called multiple times`), o que podia gerar notificações de estado duplicadas e reproduzir os bugs de navegação dupla mesmo depois de corrigidos. Corrigido restaurando o guard de `_carregando`/`termosAceitos` no `onTap`. Também corrigido: `TelaLogin` (agora `ConsumerStatefulWidget`) registrava um `ref.listenManual` em `initState` sem nunca cancelar a assinatura em `dispose()` — outra regressão da conversão de `ConsumerWidget` (que usava `ref.listen` em `build()`, limpo automaticamente) para `ConsumerStatefulWidget`. Novo teste (`tela_login_test.dart`) cobre o double-tap — total **275 testes**.
- **Login web "autenticava" sem autorização real ("Bad state: Não foi possível obter autorização do Google"):** no Flutter web (Google Identity Services), o login silencioso (`signInSilently`, usado para restaurar sessão) só devolve identidade (ID token) — não um access token com os escopos do Drive/Sheets, que só vêm do fluxo interativo (popup). `entrarComGoogle()` tratava qualquer restauração silenciosa bem-sucedida como totalmente autenticada e pulava o fluxo interativo, deixando a sessão sem token de acesso — a primeira chamada à API (carregar/criar planilha) falhava. Corrigido validando `sessaoAnterior.obterHeaders()` antes de aceitar a sessão restaurada; se falhar, cai para o login interativo normalmente.
- **Login navegava para o Dashboard duas vezes, quebrando o carregamento ("Bad state: Using 'ref' ... unmounted"):** `entrarComGoogle()` atualizava `state` manualmente depois de `await servico.entrar()`, mas `servico.entrar()` já publica a sessão em `sessoesConectadas`, que o listener do notifier consome e atualiza `state` sozinho — resultando em duas notificações para um único login. `TelaLogin` reage a cada notificação com `Navigator.pushReplacement`, então empurrava uma segunda `TelaDashboard` por cima da primeira enquanto o carregamento de dados da primeira ainda estava em andamento, desmontando-a no meio do `await` e derrubando o `ref` usado depois. Corrigido removendo a atualização de estado redundante.
- **Criação de planilha nova sempre falhava (login):** `criarPlanilhaBanco()` criava a planilha só com as abas Pacientes/Agenda/Evolucoes/Configuracoes/Auditoria, sem a aba `Versao`. Logo em seguida, `salvarVersaoEsquema()` tentava escrever em `Versao!A1:B1` — um intervalo numa aba inexistente —, o Google Sheets API rejeitava a chamada e a exceção subia sem tratamento, abortando o login **antes** do ID da planilha ser salvo em `Preferencias`. Resultado: todo primeiro login (sem planilha prévia) falhava silenciosamente, sem criar nem persistir nada. Corrigido criando a aba `Versao` já na criação da planilha, e reordenado para persistir o ID antes de gravar a versão (uma eventual falha nesse passo não perde mais a referência à planilha já criada).
- **Busca de pacientes ignorava o termo:** em `TelaPacientes`, buscar por nome (sem dígitos) retornava a lista inteira, porque a branch de comparação por CPF comparava com uma string vazia (`cpf.contains('')`), que é sempre verdadeira. Corrigido para só aplicar o filtro de CPF quando a busca contém dígitos.
- **Filtro "Hoje" de Sessões sobrepunha "Pendentes":** o filtro comparava apenas a data (sem hora) de `Agendamento.data`, então uma sessão atrasada do próprio dia aparecia tanto em "Hoje" quanto em "Pendentes". Corrigido para usar `inicioPrevisto` (data + hora real) e excluir de "Hoje" as sessões já vencidas.
- **`tela_registro_evolucao.dart`:** botão de voltar sem `Key('btn_fechar')`, inconsistente com as demais telas redesenhadas — adicionada.
- **CI quebrando por lint:** `flutter analyze` retorna código de saída ≠ 0 mesmo para issues em nível `info`, e o workflow de deploy tratava isso como falha. Corrigidos os 10 lints restantes (const constructors, `BuildContext` após gap assíncrono).
- Novos/atualizados testes de widget para acompanhar a nova API de `TelaPacientes` e o comportamento do filtro "Hoje" — total **274 testes**.

## [Não lançado] — 2026-06-20

### Funcionalidades
- **Agenda completa (visão calendário):** nova 3ª visualização "Calendário" na tela de Sessões, usando `table_calendar`. Calendário mensal com marcadores coloridos por status (verde=realizado, azul=agendado, laranja=pendente, vermelho=cancelado/falta). Tocar num dia mostra as sessões daquele dia abaixo do calendário. Filtros e busca continuam funcionando na visão calendário.
  - Nova dependência: `table_calendar: ^3.1.3`
  - Novos utilitários: `UtilitariosData.mesmoDia()`
  - Novos testes: validação de data/hora retroativa (6 edge cases), `mesmoDia` (2), `pendenteDeDiaAnterior` (1), calendário widget (3) — total **279 testes**.

### Segurança e LGPD
- **Registro de aceite dos termos na auditoria:** ao fazer login, o aceite dos Termos de Uso e da Política de Privacidade é gravado na aba **Auditoria** da planilha com tipo `ACEITE_TERMOS`, versão dos documentos e e-mail do profissional (rastreabilidade conforme Art. 8º §2 da LGPD). A versão é controlada pela constante `_versaoTermosAceitos` em `lib/provedores/provedores_dados.dart`.
- **Documentação formal LGPD/Privacidade:** páginas legais `web/termos.html` e `web/privacidade.html` reescritas com Termos de Uso v1.1 e Política de Privacidade v1.1 em conformidade com a Lei 13.709/2018.
  - Termos: aceite, modelo BYODB, responsabilidades, limitações, propriedade intelectual, lei aplicável e foro (incluída cláusula de novo aceite para mudanças materiais — Art. 8º LGPD).
  - Privacidade: papéis LGPD (Controlador/Operador/Titular), dados coletados com base legal em tabela (Art. 7º / Art. 11), direitos do titular (Art. 18), retenção (mínimo 20 anos COFFITO), segurança, incidentes/Art. 48, DPO, ANPD.
- **`firebase.json`:** adicionadas regras explícitas de rewrite para `termos.html` e `privacidade.html` antes do catch-all SPA, garantindo que as páginas estáticas sejam servidas corretamente.
- **SEGURANCA_E_DADOS.md** reescrito com tabelas detalhadas de conformidade (papéis, base legal por tipo de dado, Art. 18, incidentes, DPO, ANPD) e atualizado para refletir o novo registro de aceite.
- **Fix login Android:** botão "Entrar com Google" agora desabilitado sem aceitar termos LGPD; restauração silenciosa de sessão só ocorre dentro do fluxo de login (não mais automática ao abrir o app).
- **Financeiro simples:** nova tela `tela_financeiro.dart` acessível pela 4ª aba no bottom nav. Mostra resumo mensal com cards de **Faturado** (sessões realizadas), **Previsto** (sessões agendadas) e **Sessões realizadas** (contagem). Filtro por mês via chips horizontais. Lista de sessões do mês com nome do paciente, data, valor e badge de status. Cancelamentos e faltas são ignorados nos totais.
  - Nova aba "Financeiro" no bottom nav (ícone carteira), FAB oculto nesta aba.
  - Novos utilitários: `UtilitariosData.formatarMesAno()` e `mesmoMesAno()`.
  - Novos testes: `tela_financeiro_test.dart` (6) + `utilitarios_data_test.dart` (3 novos) — total **268 testes**.
- **Editar / reagendar sessão:** nova tela `tela_editar_sessao.dart` acessível pelo menu de ações da sessão (Dashboard e Sessões). Permite alterar data, horário de início/fim, valor e observações. **Paciente e ID ficam travados** (somente leitura). Disponível apenas para sessões com situação "Agendado".
  - Novo `RepositorioDadosGoogle.atualizarAgendamento()` (reescreve a linha existente na aba `Agenda`, range `A:I`) e `atualizarAgendamentoReal()` no provedor; auditoria `EDITAR_AGENDAMENTO`.
  - `Agendamento.copiarCom()` expandido para aceitar todos os campos editáveis (data, horaInicio, horaFim, valorSessao, observacoes).
  - Novo enum `AcaoAgendamento.editarSessao` com handler que navega para a tela de edição.
  - Menus de ações no Dashboard e Sessões exibem "Editar sessão" apenas quando `situacao == "Agendado"`.
- Novos testes: `tela_editar_sessao_test.dart` (7) + `agendamento_test.dart` (2 novos) — total **257 testes**.

### Documentação
- `IMPLEMENTAR.md`: "Editar / reagendar agendamento" marcado como ✅ implementado.
- Limpeza de branches: removidas `divisao`, `editar_paciente`, `test-mobile` (local + remoto).
- Correções em CLAUDE.md, WIDGETS.md, VISAO_GERAL.md, README.md: contagens de testes, estrutura de pastas, versão e branch atualizados.

## [Não lançado] — 2026-06-18

### Funcionalidades
- **Editar paciente:** nova tela `tela_editar_paciente.dart` acessível pelo botão "Editar Paciente" no modal de detalhes. Permite atualizar telefone, endereço e toda a anamnese clínica. **Nome, CPF, Data de Nascimento e Gênero ficam travados** (somente leitura) por serem dados de identidade.
  - Novo `RepositorioDadosGoogle.atualizarPaciente()` (reescreve a linha existente na aba `Pacientes`, range `A:S`) e wrapper `atualizarPacienteReal()` no provedor; auditoria/log `EDITAR_PACIENTE`.
- **Aviso de campos definitivos no cadastro:** ao salvar um novo paciente, popup de confirmação avisa que Nome, CPF, Data de Nascimento e Gênero não poderão ser editados depois (opções "Revisar" / "Confirmar e salvar").
- Modal de detalhes: altura máxima ajustada (0.6 → 0.72) para acomodar a nova ação.
- Novos testes: `tela_editar_paciente_test.dart` (6) + 1 no cadastro (popup) + 1 no modal (botão Editar) — total **248 testes**.

## [Não lançado] — 2026-06-17

### CI/CD
- Adicionada pipeline GitHub Actions (`.github/workflows/`):
  - `ci.yml`: lint + testes (`--coverage`) + build web em toda PR para `develop`/`master` e pushes de branches auxiliares
  - `deploy-preview.yml`: deploy em preview channel do Firebase a cada push em `develop` (ambiente de testes)
  - `deploy-prod.yml`: push em `master` incrementa versão (patch), build, deploy live no Firebase e commita o bump (`[skip ci]`)
- Auth do Firebase via Service Account (secret `FIREBASE_SERVICE_ACCOUNT`); Flutter pinado em 3.44.1
- Logs dos workflows em PT-BR com checagem de credencial; ambiente de testes (`develop`) validado e publicando
- Novos atalhos no `Makefile`: `ci-local`, `release-dev`, `release-prod`
- Novo guia `documentacao/CI_CD.md` (fluxo, secrets, uso e troubleshooting)
- Simplificado para fluxo de duas branches: removido `ci.yml` (rodava em toda branch e duplicava execuções); verificação de qualidade agora embutida nos deploys de `develop` e `master`

### UI
- Versão do app agora aparece **fixa em todas as telas** (canto inferior direito), via `VersaoOverlay` no `builder` do `MaterialApp` — antes `appVersao` existia mas não era exibido em lugar nenhum
- Novos testes: `rodape_versao_test.dart` (3) — total 240 testes

### Qualidade
- `flutter analyze` 100% limpo (eram 42 issues): aplicado `dart fix`, removido campo morto `_contaAtual` e constantes renomeadas para `lowerCamelCase` (`versaoAtual`, `historico`, `versaoEsquema`)
- Cobertura global de testes subiu de ~80% para ~85% (237 testes, eram 207)

### Correções de Bugs
- **Índices literais:** `_pacienteDeLinha` e `_agendamentoDeLinha` em `servico_repositorio_dados.dart` agora usam `Paciente.indicesColunas` / `Agendamento.indicesColunas` em vez de `linha[0..18]` — cumpre a regra crítica do projeto
- **Race condition de IDs:** geração de IDs por `length + 1` substituída por `GeradorId.proximo` (baseado no maior número existente) em nova sessão, registro de evolução e auditoria — evita IDs duplicados

### Código
- Novo utilitário `lib/utilitarios/gerador_id.dart` (geração de IDs sequenciais, 100% coberto)

### Testes
- Novos: `gerador_id_test.dart` (8), `preferencias_test.dart` (5), `modal_detalhes_paciente_test.dart` (11), `acoes_agendamento_test.dart` (6)
- Teste da tela de configurações documentado (11 testes, 100% de cobertura)

## [Não lançado] — 2026-06-14

### Segurança
- Removidos `documentacao/chaves.md` e `android/app/google-services.json` do rastreamento do git
- Adicionados ao `.gitignore`: credenciais Firebase, arquivos de debug do Mobilewright
- Removido Client ID hardcoded do `Makefile`

### Correções de Bugs
- **CRÍTICO:** Corrigido null dereference em `obterPlanilhaId` após `limparCache()` — app não crasha mais com planilha incompatível
- **CRÍTICO:** Corrigido `Paciente.copiarCom` que não preservava `dataCadastro` — arquivar/restaurar não corrompe mais a data de cadastro original
- Adicionado `try/catch` em `salvarAgendamento` e `salvarEvolucao` com logging estruturado
- Adicionado `.catchError` em `tentarRestaurarSessao` — falhas de rede não ficam silenciosas
- Índices hardcoded (`linha[10]`, `linha[7]`) em arquivar/restaurar substituídos por referência ao mapa `indicesColunas`

### Código
- Removido código morto (`is int` nunca verdadeiro) em `Paciente.deLinhaPlanilha`
- `Validadores.validarCPF` agora delega para `ValidadorCpf.validar` — algoritmo em um único lugar
- `Paciente.calcularIdade` agora delega para `UtilitariosData.calcularIdade` — lógica em um único lugar
- `Agendamento` agora expõe `indicesColunas` público (mesmo padrão de `Paciente`)
- Mensagem de erro do código 12500 não expõe mais o nome interno do projeto Firebase
- URL `fisio-home-care.local` substituída por mensagem genérica em `VersaoEsquema`

### Testes
- Removido `MockListaPacientesNotifier` que sobrescrevia métodos inexistentes
- Criado `test/helpers/fakes.dart` com `ServicoAutenticacaoGoogleFake` compartilhado
- Corrigidos CPFs inválidos nos testes de modelo (`222.222.222-22` → `529.982.247-25`)
- Corrigido ID duplicado `CT11` no E2E (renomeado segundo para `CT12`)

### Documentação
- Removidos 7 arquivos `.md` redundantes da raiz (ANALISE_MELHORIAS, ROTEIRO_IMPLEMENTACAO, RESUMO_EXECUTIVO, PROXIMOS_PASSOS, FASE1/2/3_IMPLEMENTADO)
- Movido `test/e2e/paciente/sugestoes_cadastro_paciente.md` para `documentacao/`
- Removido `documentacao/REATIVAR_TELAS.md` (nota temporária)
- Removido `test/e2e/login/tela_login_test.md` (duplicado)
- Criado `CHANGELOG.md` unificado (este arquivo)
- Criado `CLAUDE.md` com contexto do projeto para sessões futuras

### Qualidade
- `analysis_options.yaml`: adicionadas regras `cancel_subscriptions`, `close_sinks`, `prefer_const_constructors`, `prefer_final_fields`, `unawaited_futures`; adicionado bloco `analyzer` com erros obrigatórios e excludes para arquivos gerados
- `pubspec.yaml`: atualizada `description`; `google_sign_in` agora usa `^6.2.1`
- `Makefile`: adicionados targets `make test` e `make lint`
- Removidos arquivos de debug desnecessários: `example.test.ts`, `screenshot.png`, `window_dump.xml`, `1.html`, `fisio-web.html`

---

## [1.0.5] — 2026-06-14 (Fases 1–3)

### Fase 3: Testes e Documentação
- 46 testes unitários para `Validadores`
- 23 testes unitários para `VersaoEsquema`
- Dartdoc completo (100%) em `validadores.dart` e `versao_esquema.dart`

### Fase 2: Arquitetura
- Criado `VersaoEsquema` para gerenciar versões do esquema das planilhas
- `Paciente.deLinhaPlanilha` desacoplado de índices hardcoded via `indicesColunas`
- Validação automática de versão em `obterPlanilhaId`
- Logging estruturado com `developer.log` em operações críticas

### Fase 1: Segurança
- Client ID OAuth movido para variável de ambiente `GOOGLE_OAUTH_CLIENT_ID_WEB`
- Criados validadores: CPF, telefone, data de nascimento, endereço, nome
- Validação integrada em `Paciente.deLinhaPlanilha`
- Substituído `print()` por `developer.log()` em todo o projeto
- Habilitado lint `avoid_print`
