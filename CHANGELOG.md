# Changelog — Fisio Home Care

## [Não lançado] — 2026-07-01

### Design
- **Redesign visual completo:** nova paleta violeta `#6C4CE0` (primary) + verde-sálvia `#7CB9A8` (secondary), fonte `PlusJakartaSans`. Aplicado a todas as telas principais (`lib/telas/*.dart`) e ao design system compartilhado (`lib/componentes/design_system.dart`). Telas passam a ser componentes "somente corpo" (sem `Scaffold`/bottom-nav próprios, exceto Login), hospedadas por um shell de navegação com `FisioBottomNav`.
  - `TelaPacientes` deixou de receber `filtroInicial`; o filtro (`Ativos`/`Todos`/`Arquivados`) agora é estado interno trocado via chips, e a abertura de um paciente passa a ser feita por callback (`onAbrir`) em vez de abrir um modal diretamente.

### Alterado
- **Migração do `google_sign_in` 6.2.1 → 7.2.0 (+ `google_sign_in_web` 1.1.3):** a 7.x separa autenticação (quem é o usuário) de autorização (acesso a Drive/Sheets), que era exatamente a distinção ausente na 6.x e origem dos bugs de login no web. `signIn()`/`signInSilently()` dão lugar a `authenticate()`/`attemptLightweightAuthentication()`, e os tokens passam a vir de `conta.authorizationClient` (`authorizationForScopes()` → `authorizeScopes()` se necessário, e `authorizationHeaders()` por requisição). O escopo `https://www.googleapis.com/auth/spreadsheets` — removido no downgrade — foi restaurado; sem ele, uma conta Google sem consentimento prévio não conseguiria usar a Sheets API.
  - **Login no web agora parte do botão do Google.** No web `GoogleSignIn.authenticate()` lança `UnsupportedError` e `supportsAuthenticate()` devolve `false`: o Google Identity Services só aceita login iniciado pelo widget que ele mesmo renderiza. Para preservar o visual do redesign, `TelaLogin` sobrepõe o botão do GIS (praticamente invisível) ao botão desenhado do app. O widget vem de `lib/componentes/botao_google_renderizado.dart`, com import condicional (`dart.library.js_interop`) para manter `package:google_sign_in_web` fora do build Android/iOS e dos testes, que rodam na VM do Dart.
  - **Três armadilhas da sobreposição, encontradas inspecionando o DOM no navegador** (nenhuma é observável nos testes de widget, porque fora do web o componente vira um `SizedBox.shrink()`):
    - `Opacity(opacity: 0)` **não renderiza o botão**: `RenderOpacity.paint` retorna sem pintar o filho quando o alpha é zero (`proxy_box.dart`), e uma platform view só é anexada ao DOM quando pintada — o botão do Google não existia na página e o clique caía no vazio (era a causa de "o botão não clica, está estático"). Usado `0.01`, que vira alpha 3/255.
    - `IgnorePointer` **não protege uma platform view**: ele só afeta o hit-test do Flutter, e o botão do GIS é um elemento DOM que recebe o clique direto — dava para entrar **sem aceitar os termos de uso**. O botão passou a só ser construído quando o login está liberado.
    - O GIS renderiza o botão com **no máximo 400px**, centralizado no espaço disponível. Como o botão desenhado ocupava a largura toda, numa janela larga as extremidades ficavam sobre o container vazio do GIS e não respondiam ao clique. O desenho passou a ser limitado aos mesmos 400px.
  - `ServicoAutenticacaoGoogle` ganhou `suportaLoginProgramatico`; `entrarComGoogle()` encerra o carregamento sem chamar `entrar()` quando ele é `false`, senão o botão do Google ficaria coberto por um `IgnorePointer` permanente.
  - `inicializar()` passou a memorizar o `Future` — `GoogleSignIn.instance.initialize()` só pode rodar uma vez, e chamadas concorrentes apareciam no console como `google.accounts.id.initialize() is called multiple times`.
  - **Evita a segunda escolha de conta no web.** Autenticação e autorização são etapas separadas na 7.x, então um login abria dois popups: o botão do GIS (identidade) e, logo depois, o consentimento de escopos. O segundo ainda exigia escolher a conta de novo porque `google_sign_in_web` monta o token client com `prompt: 'select_account'` sempre que recebe um hint de usuário (`src/gis_client.dart`), e `conta.authorizationClient` envia a conta como hint. No web o app passou a usar `GoogleSignIn.instance.authorizationClient`, que não manda hint (`prompt: ''`): o Google reaproveita a sessão ativa e só mostra o seletor quando há ambiguidade real entre contas. Fora do web nada muda — `conta.authorizationClient` continua sendo usado no fluxo nativo, já validado no Android.
  - **Pendente de validação manual:** login no web, login no Android em device físico (a 7.x usa Credential Manager no nativo) e sessão com mais de 1h — no web o access token expira em 3600s e não é renovado pelo plugin; `obterHeaders()` resolve os headers a cada requisição justamente por isso. Total **277 testes**.

### Correções
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
