# Diagrama de Fluxo e Navegação do Aplicativo

Este documento apresenta a estrutura visual de navegação do aplicativo de Fisioterapia Domiciliar, mapeando as telas, botões de ação e conexões entre cada área do sistema.

```mermaid
graph TD
    %% Elementos com textos em aspas duplas para evitar erros de sintaxe
    Start(["Inicialização do App"])
    Splash{"Sessão Ativa < 24h?"}
    
    %% Fluxo de Login
    LoginScreen["Tela de Login"]
    CheckboxLGPD{"Aceitou LGPD?"}
    TermsModal["Visualizar Termos LGPD"]
    GoogleAuth["Autenticação Google Sign-In"]
    DbLoading["Loading: Criar/Validar Tabelas"]
    
    %% Fluxo Principal
    Dashboard["Dashboard / Início"]
    SessoesScreen["Tela de Sessões"]
    PacientesScreen["Tela de Pacientes"]
    ConfiguracoesScreen["Tela de Configurações"]
    FinanceiroScreen["Tela de Financeiro"]
    
    %% Subfluxos do Dashboard
    NovaSessaoScreen["Tela: Nova Sessão"]
    PendenciasAgenda["Seção: Pendências"]
    AcoesSessao["Menu: Desfecho da Sessão"]
    EditarSessao["Tela: Editar Sessão"]
    HistoricoGeral["Tela: Histórico Geral de Evoluções"]
    ModalEvolucao["Modal: Detalhes da Evolução (somente leitura)"]
    JanelaEdicao{"Menos de 24h do registro?"}
    RegistroFechado["Rodapé: Registro fechado — sem edição"]
    DateValidator{"Data Futura?"}
    GoogleSheets[("Google Sheets Backend")]
    
    %% Subfluxos de Pacientes
    EditarPaciente["Tela: Editar Paciente"]
    ConfirmacaoCampos{"Confirmar Campos Definitivos?"}
    CadastroPaciente["Tela: Cadastro & Anamnese"]
    CpfValidator{"CPF Único?"}
    DetailsModal["Modal: Detalhes do Paciente"]
    TimelineScreen["Tela: Linha do Tempo / Prontuário"]
    EvolucaoScreen["Tela: Registro de Evolução"]
    SpeechToText["Speech-to-Text Microfone"]
    
    %% Ações Comuns / Externas
    RouteSelection["Menu: Como Chegar"]
    GmapsWaze["Google Maps / Waze Externo"]
    LogoutAction["Ação: Sair / Logout"]

    %% Relações e Caminhos
    Start --> Splash
    Splash -- Sim --> Dashboard
    Splash -- Não --> LoginScreen
    
    LoginScreen -->|Clique nos Termos| TermsModal
    LoginScreen -->|Checkbox Desmarcado| LoginScreen
    LoginScreen -->|Checkbox Marcado| GoogleAuth
    GoogleAuth -->|Sucesso| DbLoading
    GoogleAuth -->|Cancelado| LoginScreen
    DbLoading -->|Planilha OK| Dashboard
    
    %% Navegação Principal (Menu Inferior)
    Dashboard <-->|Menu Inferior| SessoesScreen
    Dashboard <-->|Menu Inferior| PacientesScreen
    Dashboard <-->|Menu Inferior| FinanceiroScreen
    Dashboard -.->|Configurações fora da navegação principal| ConfiguracoesScreen
    
    %% Fluxo Nova Sessão
    Dashboard -->|Botão Central + no Início| NovaSessaoScreen
    NovaSessaoScreen -->|Selecionar Data/Hora| DateValidator
    DateValidator -- Não -->|Alerta de Erro| NovaSessaoScreen
    DateValidator -- Sim -->|Confirmar Agendamento| GoogleSheets
    GoogleSheets -->|Retorna| Dashboard
    
    %% Rotas no Dashboard
    Dashboard -->|Agenda de Hoje| AcoesSessao
    Dashboard -->|Sessões antigas sem desfecho| PendenciasAgenda
    SessoesScreen -->|Filtrar futuras, pendentes, canceladas, faltas, realizadas| SessoesScreen
    SessoesScreen -->|Resolver sessão| AcoesSessao
    PendenciasAgenda -->|Resolver sessão| AcoesSessao
    PacientesScreen -->|Pílula Evoluções| HistoricoGeral
    AcoesSessao -->|Editar sessão (só Agendado)| EditarSessao
    AcoesSessao -->|Registrar evolução| EvolucaoScreen
    AcoesSessao -->|Falta ou cancelamento| GoogleSheets
    
    %% Fluxo Cadastro Paciente
    PacientesScreen -->|Botão Central + em Pacientes| CadastroPaciente
    CadastroPaciente -->|Salvar| CpfValidator
    CpfValidator -- Duplicado -->|Alerta: CPF Existente| CadastroPaciente
    CpfValidator -- Único -->|Popup de campos definitivos| ConfirmacaoCampos
    ConfirmacaoCampos -- Revisar --> CadastroPaciente
    ConfirmacaoCampos -- Confirmar -->|Salvar Ativo| GoogleSheets
    GoogleSheets -->|Retorna Atualizado| PacientesScreen
    
    %% Busca e Detalhes
    PacientesScreen -->|Digitar Nome/CPF| PacientesScreen
    PacientesScreen -->|Selecionar Card| DetailsModal
    
    %% Detalhes do Paciente
    DetailsModal -->|Botão: Como Chegar| RouteSelection
    RouteSelection -->|Deep Link| GmapsWaze
    DetailsModal -->|Ação: Arquivar| GoogleSheets
    DetailsModal -->|Botão: Editar Paciente| EditarPaciente
    DetailsModal -->|Botão: Ver Histórico| TimelineScreen
    DetailsModal -->|Botão: Nova Evolução| EvolucaoScreen
    
    %% Leitura de evoluções
    HistoricoGeral -->|Tocar em um card (sempre abre)| ModalEvolucao
    ModalEvolucao -->|Ler registro completo| JanelaEdicao
    JanelaEdicao -- Sim --> EvolucaoScreen
    JanelaEdicao -- Não --> RegistroFechado
    TimelineScreen -->|Botão: Editar (só menos de 24h)| EvolucaoScreen

    %% Evolução
    EvolucaoScreen -->|Botão Microfone| SpeechToText
    SpeechToText -->|Preencher Texto| EvolucaoScreen
    EvolucaoScreen -->|Salvar Evolução| GoogleSheets
    GoogleSheets -->|Grava evolução & Agenda.Situacao Realizado| PacientesScreen

    %% Fluxo Editar Sessão
    EditarSessao -->|Salvar Alterações| GoogleSheets
    GoogleSheets -->|Atualiza linha na aba Agenda| Dashboard

    %% Fluxo Editar Paciente
    EditarPaciente -->|Salvar Alterações| GoogleSheets
    GoogleSheets -->|Atualiza linha na aba Pacientes| PacientesScreen

    %% Fluxo Configurações
    ConfiguracoesScreen -->|Alterar Valor Padrão| GoogleSheets
    ConfiguracoesScreen -->|Visualizar Planilha| GoogleSheets
    ConfiguracoesScreen -->|Ação: Sair| LogoutAction
    LogoutAction -->|Limpa Cache & Token| LoginScreen

    %% Definições de Estilo (Classes)
    classDef startEnd fill:#f9f,stroke:#333,stroke-width:2px,color:#000;
    classDef screen fill:#bbf,stroke:#333,stroke-width:1px,color:#000;
    classDef action fill:#fff,stroke:#333,stroke-dasharray: 5 5,color:#000;
    classDef sheets fill:#f96,stroke:#333,stroke-width:1px,color:#000;
    classDef external fill:#ddd,stroke:#333,stroke-width:1px,color:#000;

    %% Aplicação das classes nos elementos correspondentes
    class Start startEnd;
    
    class LoginScreen,TermsModal,Dashboard,SessoesScreen,PacientesScreen,NovaSessaoScreen,CadastroPaciente,EditarPaciente,EditarSessao,DetailsModal,TimelineScreen,EvolucaoScreen,ConfiguracoesScreen,HistoricoGeral,FinanceiroScreen,ModalEvolucao screen;
    
    class Splash,CheckboxLGPD,DbLoading,DateValidator,CpfValidator,ConfirmacaoCampos,SpeechToText,RouteSelection,LogoutAction,AcoesSessao,PendenciasAgenda,JanelaEdicao,RegistroFechado action;
    
    class GoogleSheets sheets;
    
    class GoogleAuth,GmapsWaze external;
```
