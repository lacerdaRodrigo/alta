# Especificações de Telas: Painel, Nova Sessão, Paciente e Evolução

Este documento detalha os requisitos funcionais, técnicos e fluxos de navegação das principais telas do aplicativo de Fisioterapia Domiciliar.

---

# Especificação da Tela: Início (Dashboard)

Esta tela é o painel central de controle do fisioterapeuta, apresentando um resumo dinâmico da operação e o gerenciamento de agenda.

## 1. Requisitos Funcionais
* **Saudação Dinâmica:** O sistema deve exibir uma saudação personalizada ("Bom dia", "Boa tarde" ou "Boa noite") baseada no horário do sistema, seguida do nome do fisioterapeuta autenticado.
* **Data Atual:** Exibição da data completa (dia, mês e ano) no cabeçalho.
* **Resumo Operacional (Cards):** Quatro indicadores (cards) no topo da tela:
    1. **Pacientes Cadastrados:** Contagem total de pacientes registrados na aba `Pacientes`. Ao clicar, abre a tela de pacientes no filtro `Todos`.
    2. **Pacientes Ativos:** Contagem de pacientes com situação "Ativo". Ao clicar, abre a tela de pacientes no filtro `Ativos`.
    3. **Agenda do Dia:** Contagem de atendimentos `Agendado` para a data atual. Ao clicar, rola o Dashboard até a seção `Agenda de Hoje`.
    4. **Total de Evoluções:** Contagem acumulada de evoluções clínicas registradas na aba `Evolucoes`. Ao clicar, abre a tela de histórico geral de evoluções.
* **Pendências:** Exibe sessões de dias anteriores que continuam com `Situacao = "Agendado"`, permitindo que o profissional defina o desfecho sem misturar atendimentos antigos com a agenda do dia.
* **Agenda de Hoje:** Exibe somente sessões do dia atual com `Situacao = "Agendado"`. Ao virar o dia, sessões antigas sem desfecho saem desta lista e entram em `Pendências`.
* **Navegação Inferior:** O rodapé possui quatro áreas principais: `Início`, `Sessões`, `Pacientes` e `Financeiro`. O botão central `+` é contextual:
    * Em `Início` e `Financeiro`, o FAB não é exibido.
    * Em `Sessões`, abre `TelaNovaSessao`.
    * Em `Pacientes`, abre `TelaCadastroPaciente`.
* **Card de Atendimento da Agenda:**
    * Apresenta o nome do paciente, horário, badge de estado (`Agendado`, `Atrasado` ou `Pendente`) e, quando necessário, a data do agendamento.
    * Disponibiliza um menu de ações para `Registrar evolução`, `Faltou com aviso`, `Faltou sem aviso`, `Cancelar pelo paciente` e `Cancelar pelo profissional`.
    * **Integração de Rotas (Google Maps / Waze):** No modal de detalhes do paciente, o botão de rota abre um bottom sheet dedicado com Google Maps e Waze, usando o endereço codificado para URL.

## 2. Implementação Técnica
* **Gerenciamento de Estado:** Utilizar `Riverpod` para gerenciar os dados dos cards.
* **Lógica Dinâmica:** O widget de saudação deve ser um componente que utiliza `DateTime.now()` para determinar o período do dia (Manhã: 05h-12h; Tarde: 12h-18h; Noite: 18h-05h).
* **Integração de Dados:**
    * Os dados para os cards devem ser filtrados a partir da aba `Pacientes`, `Agenda` e `Evolucoes`.
    * O Dashboard separa os agendamentos por data e situação:
        * Hoje: `Data == DateTime.now()` e `Situacao == "Agendado"`.
        * Pendências: `Data < hoje` e `Situacao == "Agendado"`.
        * Desfechos: `Realizado`, `Cancelado`, `Cancelado pelo paciente`, `Cancelado pelo profissional`, `Faltou com aviso`, `Faltou sem aviso`.
    * As ações de desfecho atualizam apenas a coluna `Situacao` da aba `Agenda`.
* **Deep Link de Rotas:** Usar a biblioteca `url_launcher` para abrir:
  * Google Maps: `https://www.google.com/maps/search/?api=1&query=ENDERECO`
  * Waze: `https://waze.com/ul?q=ENDERECO`

---

# Especificação da Tela: Nova Sessão

Esta tela permite ao profissional agendar um novo atendimento domiciliar, garantindo que o horário selecionado seja válido.

## 1. Requisitos Funcionais
* **Seleção de Paciente:** O sistema deve buscar e listar todos os pacientes cadastrados na aba `Pacientes` do Google Sheets para que o usuário possa selecionar o paciente desejado.
* **Validação de Horário:**
    * O sistema deve impedir a seleção de horários retroativos (passados).
    * A regra de validação deve ser baseada no `DateTime.now()`. O usuário só pode selecionar horários a partir do minuto corrente.
* **Campos de Cadastro:**
    * **Paciente:** Seleção via lista.
    * **Data/Hora:** Seletor de data e hora (respeitando a validação de tempo).
    * **Valor do Atendimento:** Campo numérico para registro do valor financeiro.
    * **Observações Clínicas:** Campo de texto (opcional) para anotações rápidas ou lembretes antes da sessão.
* **Ação de Agendar:** Botão "Agendar Sessão" que envia os dados para a aba `Agenda`.

## 2. Implementação Técnica
* **Gerenciamento de Estado:** Utilizar `Riverpod` para gerenciar a lista de pacientes (buscada via `FutureProvider`) e o estado do formulário de agendamento.
* **Validação de Data/Hora:**
    * Implementar lógica comparativa: `if (dataHoraSelecionada.isBefore(DateTime.now())) { exibirMensagemErro(); }`.
* **Integração de Dados:**
    * Ao confirmar o agendamento, o app deve disparar uma requisição POST para a Google Sheets API para criar uma nova linha na aba `Agenda`.

## 3. Fluxo de Navegação
1. Tela de Início -> Clicar no botão central "+" enquanto está na aba Início.
2. Abrir `TelaNovaSessao`.
3. Selecionar paciente, definir data/hora, inserir valor e observação.
4. Validar preenchimento e regra de horário retroativo.
5. Confirmar agendamento -> Persistir no Google Sheets -> Retornar à Tela de Início.

---

# Especificação da Tela: Edição de Sessão

Permite reagendar ou ajustar os dados de uma sessão existente sem cancelar e recriar. Implementada em `lib/telas/tela_editar_sessao.dart`.

## 1. Requisitos Funcionais
* **Acesso:** No menu de ações da sessão (Dashboard e Sessões), opção **"Editar sessão"** aparece apenas para sessões com `situacao == "Agendado"`. Sessões finalizadas (Realizado, Cancelado, Faltou) não exibem esta opção.
* **Campos travados (não editáveis):** **Paciente** — exibido preenchido porém desabilitado (com ícone de cadeado). Regra de negócio: a sessão permanece vinculada ao mesmo paciente.
* **Campos editáveis:** Data (DatePicker), Hora de início e término (TimePicker), Valor da sessão e Observações.
* **Campos preservados automaticamente:** `ID_Agendamento`, `ID_Paciente`, `Situacao`, `Data_Criacao` — mantidos do agendamento original.
* **Validação de data retroativa:** Data e horário selecionados não podem ser anteriores ao momento atual.
* **Campo obrigatório:** Valor da sessão (não pode ficar vazio).

## 2. Implementação Técnica
* **Persistência:** `atualizarAgendamentoReal(ref, agendamento)` (provedor) → `RepositorioDadosGoogle.atualizarAgendamento(agendamento)` reescreve a linha existente na aba `Agenda` (range `A:I`, 9 colunas). Registra auditoria `EDITAR_AGENDAMENTO`.
* **Construção do objeto:** a tela constrói o `Agendamento` diretamente preservando identidade (`idAgendamento`, `idPaciente`, `situacao`, `dataCriacao`) do agendamento original.

## 3. Fluxo de Navegação
1. Dashboard/Sessões → menu de ações → "Editar sessão".
2. Abrir `TelaEditarSessao` com dados pré-preenchidos.
3. Alterar campos editáveis → "Salvar Alterações".
4. Atualizar a linha no Google Sheets → Retornar para a tela anterior.

---

# Especificação da Tela: Sessões

Esta tela é o histórico operacional da agenda e centraliza todas as sessões, incluindo futuras, pendentes, realizadas, canceladas e faltas. Ela evita poluir o Dashboard e serve como local de consulta para sessões que já saíram da agenda de hoje.

## 1. Requisitos Funcionais
* **Filtros:** A tela possui filtros `Todas`, `Hoje`, `Futuras`, `Pendentes`, `Canceladas`, `Faltas` e `Realizadas`.
* **Busca:** Permite pesquisar sessões por nome/CPF do paciente, data, horário ou situação.
* **Visualização:** Permite alternar entre lista operacional e agrupamento `Por paciente`, facilitando ver todas as agendas de uma mesma pessoa.
* **Consulta de Canceladas:** Sessões marcadas como `Cancelado`, `Cancelado pelo paciente` ou `Cancelado pelo profissional` aparecem no filtro `Canceladas`.
* **Consulta de Faltas:** Sessões com `Faltou com aviso` ou `Faltou sem aviso` aparecem no filtro `Faltas`.
* **Consulta de Pendências:** Sessões `Agendado` atrasadas no dia atual ou de dias anteriores aparecem no filtro `Pendentes`.
* **Ações por Sessão:** Cada card permite registrar evolução ou aplicar desfechos operacionais.

## 2. Implementação Técnica
* **Dados:** Usa `provedorListaAgendamentos` e cruza `ID_Paciente` com `provedorListaPacientes`.
* **Persistência:** Não cria nova aba nem nova coluna. Desfechos são gravados em `Agenda.Situacao`.
* **Design:** Tela acessada pelo rodapé, com busca, chips horizontais de filtro, alternância de visualização e cards alinhados ao design system do app.

---

# Especificação da Tela: Cadastro de Paciente (Anamnese)

Esta tela permite realizar o cadastro completo do paciente no aplicativo e preencher sua ficha de anamnese clínica inicial, alinhada aos padrões dos conselhos de fisioterapia.

## 1. Requisitos Funcionais
* **Formulário de Cadastro:**
    * **Campos Pessoais:** Nome Completo, CPF (com máscara de validação), Telefone, Data de Nascimento e Endereço Residencial.
    * **Campos Clínicos (Anamnese) - Organizados em Subseções:**
        * **Sintomas e Queixas:**
            * Queixa Principal (QP)
            * Histórico da Doença Atual (HDA) - EVA, fatores de piora/melhora
            * Gênero (Masculino, Feminino, Outro)
            * **Escala de Dor (0-10)** - Campo numérico com validação em tempo real (bloqueia letras e valores fora de 0-10)
        * **Histórico Clínico:**
            * Comorbidades/Doenças Prévias (Ex: Hipertensão, Diabetes)
            * Medicamentos em Uso
            * Alergias (crucial para eletroterapia, agulhamento, pomadas)
            * Cirurgias/Traumas Prévios (fraturas, implantes metálicos)
        * **Estilo de Vida:**
            * Hábitos de Vida / Atividade Física (sedentarismo, frequência exercícios, profissão)
* **Validação de CPF Único:**
    * O sistema deve validar se o CPF é estruturalmente válido.
    * O sistema deve consultar a lista de pacientes cadastrados e bloquear a criação se o CPF inserido já estiver registrado, exibindo a mensagem `"Este CPF já está cadastrado."`
* **Campos Obrigatórios:** Nome Completo, CPF, Telefone, Endereço e Escala de Dor são obrigatórios para habilitar o botão de cadastro.
* **Situação Inicial:** Todo paciente cadastrado é criado com a situação `"Ativo"` por padrão na planilha.
* **Aviso de Campos Definitivos:** Ao clicar em "Salvar Paciente" com os dados válidos, antes de gravar é exibido um popup de confirmação avisando que **Nome, CPF, Data de Nascimento e Gênero** não poderão ser alterados depois do cadastro. O usuário pode "Revisar" (cancela) ou "Confirmar e salvar".

## 2. Implementação Técnica
* **Gerenciamento de Estado:** Utilizar `Riverpod` (`StateNotifierProvider` ou `AsyncNotifierProvider`) para gerenciar as validações do formulário e o estado de submissão.
* **Integração com API:** Dispara uma requisição de escrita (POST) adicionando uma nova linha à aba `Pacientes` do Google Sheets, gerando automaticamente um ID único (Ex: P001, P002...).

## 3. Fluxo de Navegação
1. Tela de Pacientes -> Clicar no botão "+" (Novo Paciente).
2. Abrir `TelaCadastroPaciente`.
3. Preencher campos obrigatórios e anamnese clínica.
4. Clicar em "Salvar Paciente" -> Confirmar aviso de campos definitivos -> Gravar no Google Sheets -> Retornar para a lista de Pacientes atualizada.

---

# Especificação da Tela: Edição de Paciente

Permite corrigir e atualizar os dados de um paciente já cadastrado, sem recriá-lo. Implementada em `lib/telas/tela_editar_paciente.dart`.

## 1. Requisitos Funcionais
* **Acesso:** No modal de detalhes do paciente (`mostrarModalDetalhesPaciente`), botão **"Editar Paciente"** abre a `TelaEditarPaciente`, que recebe o `Paciente` e pré-preenche todos os campos.
* **Campos travados (não editáveis):** **Nome, CPF, Data de Nascimento e Gênero** — exibidos preenchidos, porém desabilitados (cinza, com ícone de cadeado e legenda "Campo não editável"). Regra de negócio: identidade do paciente não muda após o cadastro.
* **Campos editáveis:** Telefone, Endereço, e toda a anamnese clínica (Queixa Principal, HDA, História Pregressa, Ocupação, Escala de Dor, Comorbidades, Medicamentos, Alergias, Cirurgias, Hábitos de Vida).
* **Campos Obrigatórios:** Telefone (mínimo 10 dígitos), Endereço e Escala de Dor. Campos clínicos opcionais podem ser limpos (passam a ficar vazios/`null`).
* **Sem checagem de CPF duplicado:** o CPF não muda, então a validação de unicidade não se aplica na edição.

## 2. Implementação Técnica
* **Persistência:** `atualizarPacienteReal(ref, paciente)` (provedor) → `RepositorioDadosGoogle.atualizarPaciente(paciente)` reescreve a linha existente na aba `Pacientes` (range `A:S`, 19 colunas), preservando `ID_Paciente`, `Data_Cadastro` e `Situacao`. Registra auditoria/log `EDITAR_PACIENTE`.
* **Construção do objeto:** a tela constrói o `Paciente` diretamente (em vez de `copiarCom`) para permitir limpar campos opcionais para `null`, mantendo a identidade vinda do paciente original.

## 3. Fluxo de Navegação
1. Lista/detalhes do Paciente -> "Editar Paciente".
2. Abrir `TelaEditarPaciente` com dados pré-preenchidos.
3. Alterar campos editáveis -> "Salvar Alterações".
4. Atualizar a linha no Google Sheets -> Retornar para a lista atualizada.

---

# Especificação da Tela: Registro de Evolução

Esta tela permite que o fisioterapeuta registre a evolução clínica do paciente após realizar um atendimento domiciliar, com dados estruturados obrigatórios para garantir um prontuário completo e auditável.

## 1. Requisitos Funcionais
* **Identificação do Atendimento:** Exibe no cabeçalho o nome do paciente, idade, data e horário da sessão agendada.
* **Seção: Informações Básicas (Obrigatórias):**
    * **Status de Presença:** Dropdown com `"Presente"`, `"Ausente com aviso"`, `"Ausente sem aviso"`.
    * **Horários Reais:** Dois seletores de horário (Início e Fim) com validação de coerência.
    * **Local de Atendimento:** Dropdown com `"Domicílio"`, `"Clínica"`, `"Teleatendimento"`.
    * **Escala de Dor (0-10):** Campo numérico com validação de intervalo em tempo real.
* **Seção: Sinais Vitais (Opcional):**
    * **Pressão Arterial:** Campo de texto livre (ex: `"120/80"`).
    * **Frequência Cardíaca:** Campo numérico (bpm).
* **Seção: Evolução Clínica:**
    * **Campo de Evolução Técnica:** Campo de texto multilinhas para detalhamento dos exercícios, resposta do paciente e orientações dadas.
    * **Transcrição de Voz (Speech-to-Text) Gratuita:**
        * Exibe um botão de microfone ao lado do campo de texto da evolução.
        * Ao clicar no botão, o app aciona o microfone do celular usando o reconhecimento de voz nativo do sistema operacional.
        * O botão exibe um indicador visual ativo (ícone piscando ou ondas sonoras).
        * À medida que o profissional fala, o texto transcrito é concatenado automaticamente no campo de texto da evolução.
        * Clicar novamente no botão de microfone finaliza a captura de áudio.
* **Condição Clínica:** 
    * Se `Status_Presenca == "Presente"`: dropdown com `"Melhora"`, `"Estável"`, `"Piora"`.
    * Se `Status_Presenca != "Presente"`: automático para `"Faltou"` (exibido como badge laranja).
* **Ação de Finalizar Sessão:** Botão "Salvar Evolução" que:
    * Valida todos os campos obrigatórios.
    * Cria registro na aba `Evolucoes` (14 colunas).
    * Atualiza o agendamento na aba `Agenda` para `Situacao = "Realizado"`.
* **Evolução Avulsa:** Evoluções criadas pelo modal do paciente sem agendamento associado usam um identificador `AVULSA-*` para manter rastreabilidade.

## 2. Implementação Técnica
* **Modelo de Dados:** `Evolucao` agora possui 12 campos (6 originais + 6 novos obrigatórios + 2 opcionais). Serialização via `paraMapaPlanilha()` e `deLinhaPlanilha()`.
* **Biblioteca Speech-to-Text:** Utilizar o pacote oficial `speech_to_text` do Flutter.
* **Fluxo de Permissão:** O app deve solicitar permissão de uso do microfone na primeira tentativa de uso. Em caso de recusa, exibe a mensagem `"Permissão de microfone necessária para transcrição por voz."`
* **Persistência de Dados:** Realiza uma requisição POST na aba `Evolucoes` (14 colunas) e PATCH na aba `Agenda` para alterar `Situacao` do agendamento para `"Realizado"`.
* **Retrocompatibilidade:** A aba `Evolucoes` agora possui 14 colunas. Novas colunas foram adicionadas ao final. Registros antigos (6 colunas) são carregados com valores padrão.
* **Badge no Modal:** O modal de detalhes do paciente (`ModalDetalhesPaciente`) exibe a condição da última evolução com cor indicativa (🟢 Melhora / 🟡 Estável / 🔴 Piora / ⚫ Faltou).

---

# Especificação da Tela: Histórico de Evoluções (Linha do Tempo)

Esta tela exibe o prontuário clínico consolidado do paciente em ordem cronológica reversa, permitindo que o profissional analise a evolução do tratamento.

## 1. Requisitos Funcionais
* **Cabeçalho Clínico:** Exibição do nome e idade do paciente selecionado para contexto imediato.
* **Visualização em Linha do Tempo (Timeline):** Apresentação das evoluções em formato visual de linha do tempo:
    * **Ordenação:** As evoluções mais recentes devem aparecer no topo (ordem cronológica decrescente).
    * **Conteúdo do Card:** Cada nó da linha do tempo deve exibir a data da sessão (`Data_Atendimento`) e o texto completo da evolução técnica (`Evolucao_Texto`).
* **Estado Vazio:** Caso o paciente seja recém-cadastrado e não possua evoluções gravadas, o sistema deve exibir uma ilustração ou mensagem amigável: `"Nenhum registro clínico cadastrado para este paciente."`

## 2. Implementação Técnica
* **Filtro de Dados:** O aplicativo deve realizar a consulta na aba `Evolucoes` do Google Sheets aplicando o filtro `ID_Paciente == PacienteSelecionado.ID_Paciente`.
* **Ordenação no App:** A ordenação decrescente deve ser realizada via código (`list.sort()`) comparando as datas do campo `Data_Atendimento`.
* **Janela de Edição:** O botão `Editar` de cada nó aparece apenas quando `evolucao.editavel` (menos de `Evolucao.janelaEdicao` desde `Data_Registro`). O conteúdo permanece visível independentemente disso — a timeline já mostra o texto completo, sem truncar.

---

# Especificação da Tela: Histórico Geral de Evoluções

Esta tela consolida todas as evoluções registradas, independentemente do paciente, para apoiar auditoria rápida e navegação a partir do card `Total de Evoluções`.

## 1. Requisitos Funcionais
* **Lista Geral:** Exibe todas as evoluções da aba `Evolucoes` em ordem decrescente por `Data_Atendimento`.
* **Busca:** Permite pesquisar por paciente, CPF, data, texto da evolução, condição clínica, local ou presença.
* **Visualização:** Permite alternar entre lista geral e agrupamento `Por paciente`, reunindo todas as evoluções de uma pessoa em um grupo expansível.
* **Contexto do Paciente:** Cada card exibe o nome do paciente, data da evolução, condição clínica, texto resumido (3 linhas) e metadados de dor, local e presença.
* **Abrir um Registro:** Tocar em qualquer card — na lista geral ou dentro de um grupo `Por paciente` — abre um modal somente leitura com o registro completo, inclusive o texto clínico inteiro. O modal abre **sempre**, independente da idade do registro; a janela de 24h decide apenas se o botão `Editar` aparece. Passadas as 24h, o rodapé exibe `Registro fechado — mais de 24h`.
* **Estado Vazio:** Se não houver evoluções, exibe mensagem amigável informando que nenhum registro foi criado.

## 2. Implementação Técnica
* **Dados:** Usa `provedorListaEvolucoes` e `provedorListaPacientes` para cruzar `ID_Paciente` com o nome do paciente.
* **Persistência:** Não grava dados. É uma tela somente leitura.
* **Ordenação:** A lista geral e os grupos por paciente mantêm as evoluções mais recentes no topo.
* **Modal de Detalhes:** `mostrarModalDetalhesEvolucao` (`lib/componentes/modal_detalhes_evolucao.dart`). O botão `Editar` só é construído quando `evolucao.editavel` **e** o paciente foi encontrado na lista carregada — `TelaRegistroEvolucao` exige um `Paciente` não-nulo.

---

# Especificação da Tela: Financeiro

Esta tela exibe o resumo financeiro mensal do fisioterapeuta, mostrando faturamento realizado e previsto com base nas sessões da aba `Agenda`. Implementada em `lib/telas/tela_financeiro.dart`.

## 1. Requisitos Funcionais
* **Acesso:** 4ª aba do bottom nav ("Financeiro", ícone carteira). O FAB não é exibido nesta aba.
* **Cards de Resumo (topo):**
    * **Faturado:** soma dos valores das sessões com `Situacao = "Realizado"` no mês selecionado.
    * **Previsto:** soma dos valores das sessões com `Situacao = "Agendado"` no mês selecionado.
    * **Sessões Realizadas:** contagem de sessões realizadas no mês.
* **Filtro por Mês:** chips horizontais com os meses que possuem sessões (padrão: mês atual). Ao trocar o chip, os cards e a lista são atualizados.
* **Lista de Sessões:** exibe as sessões realizadas e agendadas do mês selecionado, ordenadas por data decrescente. Cada card mostra nome do paciente, data, horário, valor e badge de status (Realizado/Agendado).
* **Cancelamentos e Faltas:** são ignorados — não entram nos totais nem na lista.
* **Estado Vazio:** quando não há sessões no mês selecionado, exibe mensagem "Nenhuma sessão neste mês."

## 2. Implementação Técnica
* **Dados:** usa `provedorListaAgendamentos` e `provedorListaPacientes` para calcular os totais e exibir nomes.
* **Persistência:** tela somente leitura, não grava dados.
* **Utilitários:** `UtilitariosData.formatarMesAno()` e `mesmoMesAno()` para formatação e comparação de meses.

---

# Especificação da Tela: Configurações

Esta tela centraliza o controle operacional e as ferramentas de privacidade e conformidade com a LGPD para o fisioterapeuta.

## 1. Requisitos Funcionais
* **Ajuste de Valor Padrão:** Campo de texto monetário para definir o valor padrão cobrado por sessão.
    * **Regra de Negócio:** Ao definir um valor (Ex: R$ 150,00), o sistema salva esta preferência. Ao abrir a `TelaNovaSessao` para agendar qualquer atendimento, o campo de valor é preenchido automaticamente com esta configuração.
* **Acesso Soberano ao Banco:** Botão "Visualizar Planilha de Dados". Ao ser clicado, abre o link oficial da planilha `__saas_fisio_db__` do Google Sheets no navegador do dispositivo, garantindo transparência total.
* **Privacidade (LGPD):** 
    * Botão "Visualizar Termos de Uso" para reexibir o documento legal aceito no login.
    * **Logs de Auditoria:** Seção que exibe a listagem dos logs da aba `Auditoria` (últimas ações de criação, alteração ou arquivamento realizadas no app) em formato somente leitura, garantindo conformidade com a rastreabilidade exigida pela LGPD.

## 2. Implementação Técnica
* **Persistência de Preferências:** Ao alterar o valor padrão, o aplicativo grava os dados na aba `Configuracoes` associando a chave `valor_sessao_padrao` ao valor inserido. No carregamento do app, esse valor é mantido em cache local.
* **Rastreabilidade (Logs):** Qualquer ação crítica no app (Ex: login, agendamento de sessão, arquivamento de paciente) dispara uma chamada assíncrona de escrita em background na aba `Auditoria` descrevendo a ação. A tela de configurações apenas lê e renderiza estas linhas.
