# 🎨 Testes de Widget (181 testes)

Testes de componentes visuais: telas, componentes reutilizáveis e utilitários
de UI, interação do usuário e estados visuais.

---

## test/widgets/telas/ (154 testes | 13 arquivos)

Cada arquivo de teste representa uma tela da aplicação.

---

### tela_splash_test.dart (7 testes)

**Tela:** Abertura animada (`TelaSplash`) — gradiente da marca, logotipo,
traçado de ECG e handoff para o login.

```dart
// Conteúdo da marca
✓ mostra logotipo, título e subtítulo da marca
✓ desenha o traçado de ECG durante a abertura

// Navegação
✓ não navega antes de terminar a animação
✓ vai para o destino ao fim da animação
✓ substitui a rota: não dá para voltar para a splash

// Acessibilidade e ciclo de vida
✓ com "reduzir movimento" pula direto para o destino
✓ descartar a tela no meio da animação não quebra
```

**Notas:**
- O destino é injetável (`construirDestino`), então os testes não precisam
  montar autenticação nem o SDK do Google.
- Os elementos animados têm chaves estáveis (`splash_logotipo`, `splash_ecg`)
  porque a aparência é feita em `CustomPainter` — não há widget de texto ou
  ícone para localizar o traçado.
- `MediaQuery(disableAnimations: true)` reproduz "reduzir movimento" do sistema.

---

### tela_dashboard_test.dart (16 testes)

**Tela:** Início (home após login) — cabeçalho, stat tiles, agenda do dia,
pendências, navegação inferior e FAB.

```dart
// Estados de carregamento
✓ Estado carregando exibe indicador de progresso
✓ Estado erro exibe mensagem e botão tentar novamente

// Cabeçalho e cards
✓ Cabeçalho mostra nome e iniciais do usuário
✓ Tocar no avatar abre as Configurações
✓ Stat tiles exibem pacientes ativos e pendências
✓ Agenda vazia exibe estado vazio com mensagem
✓ Link "Ver tudo" navega para aba Sessões
✓ Link Histórico de evoluções navega para a tela

// Navegação inferior e FAB
✓ Barra inferior alterna abas
✓ FAB na aba Pacientes abre cadastro

// Agenda e pendências
✓ Lista sessões de hoje na agenda
✓ Contador de sessões do dia exibido no header
✓ Pendências são contabilizadas no stat tile

// Layout do header
✓ Header apresenta a data antes do contador
✓ Cards não cobrem o contador de sessões
```

> Usa notifiers de teste (`CarregamentoComEstado`, `PacientesComDados`,
> `AgendamentosComDados`) para injetar o estado "carregado" e evitar a chamada
> real ao Google Sheets disparada no `initState`.
>
> **"Cards não cobrem o contador" é geométrico, não textual.** Os stat tiles
> sobem 38px (`Transform.translate`) para flutuar sobre o gradiente; quando o
> padding inferior do `FisioGradientHeader` era menor que isso, eles cortavam o
> número do dia — e nenhum teste percebia, porque o texto continuava na árvore.
> A asserção compara `getTopLeft` do primeiro `FisioStatTile` com
> `getBottomLeft` do texto "sessão".

---

### tela_nova_sessao_test.dart (9 testes)

**Tela:** Agendamento de nova sessão — seleção de paciente, data, horário,
valor e observações.

```dart
// Renderização
✓ Exibe título, campos e valor padrão preenchido (150,00)
✓ Sem pacientes ativos exibe aviso de cadastro

// Validação
✓ Agendar sem selecionar paciente mostra erro de validação
✓ Paciente selecionado sem data/hora não agenda (retorno silencioso)

// Seletores e agendamento
✓ Selecionar data preenche o campo de data
✓ Data/horário retroativo exibe mensagem de erro
✓ Agendamento válido salva e volta para a tela anterior
✓ Falha ao salvar exibe snackbar de erro

// Navegação
✓ Botão fechar (X) aciona o retorno
```

> Usa `FakeRepositorioDadosGoogle` / `RepositorioQueFalha` para os caminhos de
> sucesso e erro. O seletor de horário é acionado em modo de digitação, com o
> finder escopado ao `Dialog` (evita capturar os campos da tela por trás);
> `MediaQuery.alwaysUse24HourFormat` força o formato 24h.

---

### tela_login_test.dart (9 testes)

**Tela:** Login com Google — checkbox LGPD, links legais, botão de entrada.

```dart
✓ Exibir título, subtítulo e botão "Entrar com Google"
✓ Exibir checkbox de termos e os links legais (Termos de Uso, Política LGPD)
✓ Checkbox começa desmarcado e sem mensagem de erro
✓ Tocar no checkbox marca os termos como aceitos
✓ Entrar sem aceitar os termos exibe erro e não chama o serviço
✓ Aceitar termos e entrar chama o serviço e exibe indicador de carregamento
✓ Tocar de novo enquanto carrega não chama o serviço uma segunda vez
✓ Login que emite conta e sessão navega para o Dashboard uma única vez
✓ Onde o login não é programático (web) não chama entrar nem trava o botão
```

> Usa `ServicoAutenticacaoGoogleControlavel` (fake com `Completer`) para
> inspecionar o estado de carregamento sem disparar a navegação ao dashboard.
>
> `ServicoAutenticacaoGoogleControlavel(suportaLoginProgramatico: false)`
> reproduz o web, onde `GoogleSignIn.authenticate()` lança `UnsupportedError` e o
> login parte do botão renderizado pelo GIS: `entrar()` não pode ser chamado e o
> estado de carregamento precisa ser desfeito, senão o botão do Google ficaria
> coberto por um `IgnorePointer` permanente.
>
> `ServicoAutenticacaoGoogleDuplaEmissao` reproduz o pior caso do serviço real:
> um único login publica em `sessoesConectadas` **e** em `contasConectadas`,
> gerando duas mudanças de estado com `estaAutenticado == true`. Como
> `pushReplacement` troca a rota no lugar, contar `TelaDashboard` na árvore não
> distingue uma navegação de duas — o teste usa um `NavigatorObserver`
> (`ContadorDeNavegacoes`) e exige exatamente **uma** substituição de rota.

---

### tela_cadastro_paciente_test.dart (23 testes)

**Tela:** Cadastro de novo paciente — formulário com validação de campos obrigatórios.

#### Seção Endereço (6 testes)
```dart
✓ Exibir "Toque para preencher endereço" quando vazio
✓ Tocar no endereço abre modal com 4 campos
  • Rua/Avenida *
  • Número
  • Bairro *
  • Cidade *
✓ Preencher campos e confirmar atualiza endereço exibido
✓ Campos obrigatórios impedem confirmar sem preenchimento
✓ Endereço com apenas rua e cidade é composto corretamente
✓ Cancelar não altera o endereço
```

#### Seção Anamnese Clínica (3 testes)
```dart
✓ Exibir seção de Anamnese com todos os campos
✓ Permitir salvar paciente sem preencher anamnese
✓ Bloquear digitação de valor > 10 na escala de dor
```

#### Validação de Campos Obrigatórios — CT-F (6 testes)
```dart
✓ CT-F1: 5 campos vazios → dialog com 5 itens
  (Nome, CPF, Telefone, Data de Nascimento, Endereço)
✓ CT-F2: Só Nome preenchido → dialog com 4 itens
✓ CT-F3: Só CPF preenchido → dialog com 4 itens
✓ CT-F4: Nome+CPF+Telefone → dialog com 2 itens
  (Faltam Data e Endereço)
✓ CT-F5: Todos preenchidos → salva sem dialog
✓ CT-F6: Dialog fecha ao clicar OK
```

#### Cobertura adicional (8 testes)
```dart
✓ Botão fechar (X) aciona o retorno
✓ Selecionar gênero no dropdown atualiza a seleção
✓ Validação do formulário aceita o gênero selecionado
✓ Telefone com menos de 10 dígitos é sinalizado
✓ CPF já cadastrado exibe snackbar de erro
✓ Salvar com todos os campos gera próximo ID (P005 → P006) e persiste a anamnese
✓ Falha ao salvar exibe snackbar de erro
✓ Popup de campos definitivos: "Revisar" cancela sem salvar
```

> Obs.: os testes que persistem o paciente confirmam o popup de campos
> definitivos (Nome/CPF/Data/Gênero) via `btn_confirmar_cadastro` antes de gravar.

### tela_editar_paciente_test.dart (6 testes)

**Tela:** Edição de paciente existente — campos de identidade travados.

```dart
✓ Pré-preenche os campos editáveis com o paciente
✓ Nome, CPF, nascimento e gênero estão desabilitados (campos editáveis seguem habilitados)
✓ Salvar atualiza editáveis e preserva identidade (id/nome/cpf/gênero/nascimento); campo limpo vira null
✓ Endereço vazio impede salvar (dialog de campos obrigatórios)
✓ Telefone com menos de 10 dígitos é sinalizado
✓ Falha ao atualizar exibe snackbar de erro
```

> Usa `FakeRepoEdicao` (captura o `Paciente` enviado a `atualizarPaciente`),
> `RepoEdicaoQueFalha` e `PacientesComDados`. Verifica o estado desabilitado pelo
> `TextField.enabled` interno de cada campo travado.

> Usa `FakeRepositorioDadosGoogle` / `RepositorioQueFalha` e `PacientesComDados`
> para os caminhos de sucesso, erro e CPF duplicado. Os testes que preenchem
> todos os campos montam a tela numa superfície alta (1000×4000) para evitar
> scroll e usam as `Key`s dos campos.

---

### tela_editar_sessao_test.dart (7 testes)

**Tela:** Edição/reagendamento de sessão existente — paciente travado, campos de data/hora/valor editáveis.

```dart
✓ Pré-preenche campos editáveis com o agendamento (hora, valor, observações)
✓ Paciente aparece desabilitado (campo travado)
✓ Salvar atualiza campos e preserva identidade (id/paciente/situação/dataCriação)
✓ Valor vazio impede salvar (dialog de campos obrigatórios)
✓ Falha ao atualizar exibe snackbar de erro
✓ Botão voltar aciona o retorno
✓ Observação vazia vira null no agendamento salvo
```

> Usa `FakeRepoEdicaoSessao` (captura o `Agendamento` enviado a `atualizarAgendamento`),
> `RepoEdicaoSessaoQueFalha` e `AgendamentosComDados`. Verifica o estado desabilitado pelo
> `TextField.enabled` interno do campo paciente.

---

### tela_pacientes_test.dart (11 testes)

**Tela:** Lista de pacientes agrupada por letra, com filtro por chips
(Ativos/Todos/Arquivados) e busca. `TelaPacientes` não abre mais um modal
diretamente — ela recebe um callback `onAbrir(Paciente)` e delega a navegação
para quem a hospeda.

```dart
// Filtro
✓ Exibir apenas pacientes ativos por padrão
✓ Exibir apenas arquivados ao selecionar o filtro
✓ Voltar a exibir apenas ativos ao reselecionar o filtro
✓ Filtro "Todos" exibe ativos e arquivados

// Cabeçalho
✓ Exibe o total de pacientes cadastrados
✓ Paciente arquivado exibe o rótulo "Arquivado"

// Busca
✓ Busca filtra por nome
✓ Busca por CPF filtra a lista
✓ Lista vazia exibe estado vazio
✓ Busca sem resultado exibe estado vazio

// Interação
✓ Tocar no card aciona onAbrir com o paciente selecionado
```

> Usa `PacientesNotifierComDados` para injetar a lista. O filtro (`FiltroPacientes`)
> é estado interno do widget, trocado via `FisioFilterChips` — não existe mais
> `filtroInicial`/`didUpdateWidget`.

---

### tela_registro_evolucao_test.dart (23 testes)

**Tela:** Registro de evolução clínica — criar novo, editar existente, transcrição
por voz. *(O arquivo também cobre a timeline `TelaHistoricoEvolucoes`.)*

```dart
// Modos (originais)
✓ Modo novo: título "Registrar Evolução" + botão "Salvar Evolução"
✓ Modo edição (<24h): título "Editar Evolução" + botão "Atualizar Evolução"
✓ Pré-preenche campos a partir da evolução existente
✓ Sem banner de bloqueio quando <24h
✓ Modo readonly (>24h): exibe banner de bloqueio e oculta o botão salvar
✓ Timeline: botão "Editar" só aparece para evoluções <24h

// Inicialização com agendamento
✓ Usa horários do agendamento e exibe o horário no cabeçalho

// Interação de campos
✓ Status "Ausente" exibe "Condição: Faltou"
✓ Altera local de atendimento
✓ Altera condição clínica
✓ Seleciona horários reais pelo time picker (início e fim)

// Validação e salvamento
✓ Salvar sem evolução técnica mostra erro de validação
✓ Salvar nova evolução com sucesso volta à tela anterior
✓ Editar evolução existente atualiza com sucesso
✓ Falha ao salvar exibe snackbar de erro
✓ Salvar como Ausente grava condição "Faltou"

// Navegação e microfone
✓ Botão voltar aciona o retorno
✓ Microfone indisponível exibe aviso
✓ Microfone disponível transcreve (resultado final) e encerra
```

> Microfone testado com um fake de `SpeechToTextPlatform` (dev-dependency
> `speech_to_text_platform_interface`); o timer interno de "final timeout" (2s)
> é drenado descartando a tela e avançando o relógio. Time picker em modo de
> digitação com finder escopado ao `Dialog`.

---

### tela_sessoes_test.dart (10 testes)

**Tela:** Lista de sessões do mês agrupada por dia, com filtros por chip
(Todas/Hoje/Futuras/Pendentes/Realizadas) e busca por nome do paciente.

```dart
✓ Listar sessões realizadas pelo filtro Realizadas
✓ Listar pendências pelo filtro Pendentes
✓ Buscar sessões por nome do paciente

// Busca e estado vazio
✓ Busca por texto que não existe oculta resultados
✓ Estado vazio exibe mensagem quando não há sessões
✓ Cada filtro ativo exibe mensagem de estado vazio

// Filtros por período e status
✓ Filtro "Futuras" mostra apenas sessões futuras
✓ Filtro "Pendentes" mostra sessões atrasadas/anteriores
✓ Filtro "Realizadas" mostra apenas sessões realizadas
✓ Filtro "Hoje" mostra sessões do dia (exclui as já pendentes no mesmo dia)
```

> Usa notifiers de teste (`PacientesNotifierComDados`,
> `AgendamentosNotifierComDados`) para injetar pacientes e agendamentos.
> O filtro "Hoje" compara `inicioPrevisto` (data+hora) com `DateTime.now()`,
> não só a data, para não sobrepor com "Pendentes". Chips fora da tela são
> revelados com `tester.ensureVisible` antes do toque.

---

### tela_financeiro_test.dart (8 testes)

**Tela:** Resumo financeiro mensal — cards de faturado/previsto/sessões
realizadas, filtro por mês e lista de sessões com visão por paciente.

```dart
✓ Exibe cards com totais corretos
✓ Filtra por mês ao trocar chip
✓ Estado vazio quando não há sessões no mês
✓ Lista sessões com nome do paciente e badge
✓ Ignora cancelamentos e faltas nos totais
✓ Exibe contagem de sessões realizadas
✓ Visualização por paciente agrupa sessões
✓ Seletor de visualização alterna entre lista e por paciente
```

---

### tela_configuracoes_test.dart (14 testes)

**Tela:** Configurações — base de dados (planilha), valor padrão da sessão,
preferências, conta (logout) e logs de auditoria.

```dart
✓ Exibe o título "Configurações"
✓ Exibe seção "Base de dados"
✓ Exibe botões "Sincronizar" e "Abrir no Drive"
✓ Exibe seção "Valor padrão da sessão"
✓ Exibe seção "Preferências" com switches
✓ Exibe link "Sair da conta"
✓ Exibe link "Exportar logs de auditoria"
✓ Planilha conectada exibe status Ativa quando ID presente
✓ Planilha sem ID exibe status Inativa
✓ Toggle "Notificações" responde ao toque
✓ Exibe nome de usuário no cabeçalho

// Cobertura adicional
✓ Confirmar logout navega para o login
✓ Logs de auditoria são copiados ao tocar exportar
✓ Abrir planilha com falha exibe snackbar
```

> Usa `FakeRepoConfig` / `RepoConfigQueFalha` para os caminhos de sucesso e
> erro ao salvar o valor padrão, `LogsComDados` para injetar os logs de
> auditoria e `_PlanilhaIdFixo` para o ID da planilha. A abertura da planilha
> é testada via mock do canal `plugins.flutter.io/url_launcher` retornando
> `false` (falha de abertura).

---

### tela_historico_geral_evolucoes_test.dart (10 testes)

**Tela:** Histórico geral de todas as evoluções clínicas, com busca e duas
visualizações (lista e por paciente).

```dart
✓ Buscar evolução por texto clínico
✓ Agrupar evoluções por paciente (visualização "Por paciente")
✓ Estado vazio quando não há evoluções ("Nenhuma evolução registrada ainda.")
✓ Botão limpar restaura a lista completa
✓ Cores de condição (Piora e Faltou) são exibidas
✓ Visão por paciente ordena vários pacientes (comparador de nomes)
✓ Tocar no card abre o modal de detalhes
✓ Tocar no card dentro da visão por paciente abre o modal
✓ Modal abre para evolução com mais de 24h (registro fechado, sem "Editar")
✓ Botão voltar aciona o retorno
```

> Regressão: o card era um `FisioCard` sem `onTap`, então o registro não tinha
> porta de entrada nenhuma e o texto cortado em 3 linhas ficava inacessível.

---

## test/widgets/componentes/ (21 testes | 3 arquivos)

### modal_detalhes_evolucao_test.dart (6 testes)

**Componente:** Bottom sheet somente leitura de uma evolução — é o único lugar
onde o texto clínico aparece inteiro (o card da lista corta em 3 linhas).

```dart
✓ Exibe o texto clínico completo, sem truncar (SelectableText, maxLines nulo)
✓ Exibe paciente, data, condição e metadados (status, horário real, dor, PA/FC)
✓ Exibe botão "Editar" quando a evolução tem menos de 24h
✓ Abre mesmo com mais de 24h, com "Registro fechado — mais de 24h" no rodapé
✓ Sem paciente não oferece edição, mesmo dentro das 24h
✓ Evolução sem texto mostra "Registro sem descrição clínica."
```

> A janela de 24h (`Evolucao.janelaEdicao`) só decide se o botão "Editar"
> aparece — nunca se o registro pode ser lido. Sem `Paciente` a edição é
> impossível de qualquer forma: `TelaRegistroEvolucao` exige um não-nulo.

---

### modal_detalhes_paciente_test.dart (12 testes)

**Componente:** Bottom sheet de detalhes do paciente — dados cadastrais,
anamnese, última evolução, rotas (Maps/Waze) e ações de editar/arquivar/restaurar.

```dart
✓ Exibe nome, telefone, endereço e seções clínicas preenchidas
✓ Mostra a ação "Editar Paciente"
✓ Paciente ativo mostra a ação "Arquivar Paciente"
✓ Paciente arquivado mostra a ação "Restaurar Paciente"
✓ Última evolução é exibida para paciente ativo
✓ Abrir opções de rota mostra Google Maps e Waze
✓ Abrir rota com falha exibe snackbar
✓ Cancelar o diálogo de arquivar mantém o modal
✓ Arquivar com sucesso fecha o modal e mostra confirmação
✓ Arquivar com erro exibe snackbar de erro
✓ Restaurar com sucesso fecha o modal e mostra confirmação
✓ Restaurar com erro exibe snackbar de erro
```

> Usa `FakeRepoModal` / `RepoModalQueFalha` para os caminhos de sucesso e erro
> de arquivar/restaurar, `EvolucoesComDados` para a última evolução e mock do
> canal `url_launcher` para a falha de rota. O botão de rota é revelado com
> `tester.ensureVisible` antes do toque.

---

### rodape_versao_test.dart (3 testes)

**Componente:** Overlay que carimba a versão do app por cima de qualquer tela.

```dart
✓ Usa o valor padrão 0.0.0 quando APP_VERSION não é definido
✓ Exibe a versão sobre o conteúdo da tela
✓ Não intercepta toques (IgnorePointer)
```

---

## test/widgets/utilitarios/ (6 testes | 1 arquivo)

### acoes_agendamento_test.dart (6 testes — 96% de cobertura)

**Utilitário:** `executarAcaoAgendamento` — registrar evolução ou aplicar
desfecho (falta/cancelamento) a um agendamento.

```dart
✓ registrarEvolucao sem paciente não navega
✓ registrarEvolucao com paciente navega para a tela
✓ Ação de falta abre diálogo de confirmação
✓ Cancelar o diálogo não atualiza a sessão
✓ Confirmar atualiza a situação e exibe snackbar
✓ Falha ao atualizar exibe snackbar de erro
```

> Usa `FakeRepoAcoes` / `RepoAcoesQueFalha` e `AgendamentosComDados`. A ação é
> disparada a partir de um host `Consumer` que fornece o `WidgetRef`.

---

## Padrão: testWidgets + Arrange-Act-Assert

```dart
testWidgets('deve exibir apenas pacientes ativos por padrão', (tester) async {
  // Arrange: criar widget tree com dados
  await tester.pumpWidget(_criarApp([
    _pacienteAtivo('P001', 'João Ativo'),
    _pacienteArquivado('P002', 'Maria Arquivada'),
  ]));
  await tester.pumpAndSettle();

  // Act: verificar estado inicial
  // (não há ação aqui, é estado padrão)

  // Assert: validar resultado visual
  expect(find.text('João Ativo'), findsOneWidget);
  expect(find.text('Maria Arquivada'), findsNothing);
});
```

---

## Mocks Reutilizados

**Arquivo:** `test/unitarios/auxiliares/fakes.dart`

```dart
✓ ServicoAutenticacaoGoogleFake
  • Mock do login Google sem chamadas reais

✓ RepositorioDadosGoogleFake
  • Mock do repositório Sheets API
```

---

## Como Rodar Apenas Widgets

```bash
flutter test test/widgets/

# Um arquivo específico
flutter test test/widgets/telas/tela_pacientes_test.dart
```

---

## Cobertura de UI

| Tela | Status | Testes | Observação |
|---|---|---|---|
| Splash | ✅ | 7 | Abertura animada + handoff para o login |
| Login | ✅ | 9 | Termos LGPD, login Google, navegação única |
| Dashboard | ✅ | 16 | folga entre header e stat tiles coberta por teste geométrico |
| Cadastro Paciente | ✅ | 23 | — |
| Editar Paciente | ✅ | 6 | Campos travados + atualização |
| Editar Sessão | ✅ | 7 | Campos travados + atualização |
| Lista Pacientes | ✅ | 12 | — |
| Nova Sessão | ✅ | 9 | — |
| Registro Evolução | ✅ | 23 | inclui timeline e ditado por voz |
| Sessões/Agenda | ✅ | 10 | — |
| Financeiro | ✅ | 8 | — |
| Configurações | ✅ | 14 | — |
| Histórico Evoluções | ✅ | 10 | tap no card abre o modal, inclusive >24h |
| Modal Detalhes Evolução | ✅ | 6 | Leitura completa, edição só dentro das 24h |
| Modal Detalhes Paciente | ✅ | 12 | — |
| Rodapé Versão | ✅ | 3 | Overlay de versão |
| Ações de Agendamento | ✅ | 6 | — |
| **Total** | **✅** | **181** | Telas principais + componentes/utilitários |
