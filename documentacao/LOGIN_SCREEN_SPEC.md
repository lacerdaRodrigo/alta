# Especificação da Tela: Login

Esta tela é a porta de entrada do aplicativo, responsável pela autenticação do usuário via Google Sign-In e pelo registro de consentimento LGPD.

## 1. Requisitos Funcionais
* **Autenticação:** Integração obrigatória com Google Sign-In[cite: 2, 3].
    * Na Web, o login deve usar o botão oficial do Google renderizado pelo SDK.
      **Como está implementado:** o botão do SDK é de fato quem dispara o login,
      mas fica sobreposto (praticamente transparente) ao botão desenhado pelo
      design system, para preservar a identidade visual da tela. É o SDK que
      recebe o clique — o desenho por baixo é apenas aparência.
    * Após selecionar a conta Google, a autorização de acesso ao Drive/Sheets ocorre em uma segunda ação explícita do usuário para evitar bloqueio de popup pelo navegador.
      Quando a conta já concedeu os escopos, essa etapa não pede nova escolha de
      conta — o App solicita a autorização sem enviar hint de usuário, o que faz
      o Google reaproveitar a sessão ativa.
* **LGPD e Consentimento:**
    * O sistema deve apresentar o "Termo de Consentimento para Tratamento de Dados Pessoais e de Saúde".
    * **Regra de Negócio:** O acesso à funcionalidade de login deve ser condicionado ao aceite explícito do termo através de um campo de verificação (checkbox).
    * O botão de "Entrar com Google" deve permanecer desabilitado até que o aceite seja formalizado pelo usuário.
      **Na Web isso exige não construir o botão do SDK** enquanto o termo não for
      aceito: ele é um elemento DOM e receberia o clique mesmo "desabilitado" pelo
      Flutter, permitindo entrar sem o aceite.
* **Persistência de Sessão:** O aplicativo deve realizar a verificação automática de token de sessão ao inicializar[cite: 2].
* **Estado de Processamento:** O sistema deve sinalizar o status de carregamento (`loading`) durante a tentativa de autenticação[cite: 2].
* **Tratamento de Exceções:** Exibição de mensagens de erro amigáveis caso ocorram falhas na autenticação[cite: 2].

## 2. Termo de Consentimento, Uso e Privacidade (LGPD)
> **Termo de Uso e Política de Privacidade - Licença de Uso do Aplicativo "Alta"**
>
> **1. Escopo e Objeto:** O "Alta" é um aplicativo cliente que atua como ferramenta de gestão clínica e operacional. Este termo regula a relação entre a plataforma ("Alta") e o fisioterapeuta ("Usuário Profissional"), visando à conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/18).
>
> **2. Soberania e Armazenamento dos Dados:**
> * **Sem Servidor Central:** O aplicativo opera sob o modelo de soberania local do usuário. Nenhum dado de paciente ou evolução clínica é armazenado ou processado em servidores de terceiros ou sob controle da equipe de desenvolvimento do aplicativo.
> * **Integração Google Drive:** O armazenamento dos dados ocorre exclusivamente na conta pessoal do Google Drive do próprio Usuário Profissional (Google Sheets), utilizando a API oficial do Google.
> * **Responsabilidade Técnica:** O Usuário Profissional é o único titular da credencial de acesso do Google (OAuth 2.0). A guarda, proteção e confidencialidade destas credenciais são de exclusiva responsabilidade do Usuário Profissional.
>
> **3. Natureza dos Dados Processados:**
> * **Dados do Profissional:** E-mail e nome obtidos via Google Sign-In para validação de acesso.
> * **Dados de Pacientes (Inseridos pelo Profissional):** Nome, CPF, telefone, endereço, histórico clínico (Queixa Principal, HDA, HP), dados sensíveis de saúde (registro de evoluções, exames, nível de dor).
>
> **4. Funções da LGPD e Responsabilidade sobre Terceiros:**
> * **Controlador:** Sob a ótica da LGPD, o Usuário Profissional (Fisioterapeuta) atua como o **Controlador** dos dados pessoais e sensíveis dos pacientes cadastrados, definindo as finalidades do tratamento.
> * **Obtenção de Consentimento do Paciente:** É obrigação legal exclusiva do Usuário Profissional obter o consentimento prévio, expresso, livre e informado dos seus respectivos pacientes (titulares dos dados) para realizar o registro e tratamento de seus prontuários clínicos na nuvem pessoal (Google Drive).
> * **Direito ao Esquecimento:** O profissional garante a exclusão dos dados do paciente quando solicitados por este, podendo fazê-lo diretamente no aplicativo ou na planilha.
>
> **5. Obrigações e Segurança:**
> * **Guarda de Prontuários:** O uso do aplicativo é uma ferramenta de auxílio operacional e não exime o Usuário Profissional do estrito cumprimento das normas éticas e legais estabelecidas pelo COFFITO (Conselho Federal de Fisioterapia e Terapia Ocupacional) quanto à guarda formal e sigilo dos prontuários.
> * **Segurança do Aparelho:** O Usuário Profissional compromete-se a utilizar o aplicativo em dispositivos móveis seguros, com uso ativo de senhas, biometria e criptografia nativa de armazenamento.
>
> **6. Consentimento do Usuário Profissional:**
> Ao marcar o checkbox de consentimento, clicar em "Entrar com Google" e autorizar o acesso aos dados, o Usuário Profissional declara ter lido, compreendido e aceitado todos os termos de uso e políticas de privacidade aqui descritos, autorizando o aplicativo a interagir com sua conta do Google Drive/Sheets exclusivamente para os fins operacionais propostos.

## 3. Implementação Técnica
* **Gerenciamento de Estado:** Utilizar `Riverpod` para gerenciar os estados: `estaAutenticado`, `estaCarregando`, `termosAceitos`, `googleConectado`, `precisaAutorizarDados` e `mensagemErro`.
* **Framework:** Flutter para Android e Web.
* **Integração:** O token de acesso obtido via Google Sign-In/Google Identity Services deve ser utilizado para autorizar as requisições às APIs Google Drive e Google Sheets.