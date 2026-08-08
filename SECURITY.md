# Política de Segurança

O Alta lida com dados de saúde. Levamos relatos de segurança a sério e
respondemos a todos.

## Como reportar uma vulnerabilidade

**Não abra uma issue pública.** Envie um e-mail para:

**lacerdaa.rodrigo@gmail.com** — assunto: `[SEGURANÇA] Alta`

Inclua, se possível:

- Descrição da falha e do impacto
- Passos para reproduzir (ou prova de conceito)
- Versão do app (`web/version.json` ou o rodapé de versão dentro do aplicativo)
- Plataforma (web / Android)

| Etapa | Prazo |
|---|---|
| Confirmação de recebimento | até 72 horas |
| Avaliação inicial e classificação | até 7 dias |
| Correção de falha crítica | o mais rápido possível, com aviso ao relator |

Pedimos divulgação coordenada: aguarde a correção ser publicada antes de tornar
o relato público. Damos crédito ao relator, salvo pedido em contrário.

## Modelo de dados — o que está e o que não está em risco

O Alta é **BYODB** (*Bring Your Own Database*): não existe servidor central nem
prontuário de terceiros.

- Os dados clínicos vivem em uma planilha (`__saas_fisio_db__`) **dentro da conta
  Google do próprio fisioterapeuta**.
- O acesso se dá por **OAuth 2.0**, com escopos restritos a Drive e Sheets, e o
  token é emitido pelo Google diretamente ao aplicativo.
- Nenhum dado de paciente transita ou é armazenado em infraestrutura do
  mantenedor. O Firebase Hosting serve apenas os arquivos estáticos do app.

Consequência prática: um vazamento neste repositório **não expõe dados de
pacientes**. O que importa aqui são falhas de autenticação, de escopo OAuth,
de manipulação de tokens ou de lógica que possam levar o app a ler/gravar na
planilha errada.

Detalhamento completo em [`documentacao/SEGURANCA_E_DADOS.md`](documentacao/SEGURANCA_E_DADOS.md).

## Escopo

**No escopo:**

- Autenticação e autorização Google (fluxo OAuth, cache e renovação de token)
- Vazamento de credencial ou segredo no código, no build ou no histórico do Git
- Falhas de controle de acesso a dados (ler/gravar planilha de outra conta)
- Injeção via dados da planilha renderizados na interface
- Configuração indevida do Firebase Hosting

**Fora do escopo:**

- Vulnerabilidades da própria infraestrutura Google (Sheets, Drive, Sign-In) —
  reporte ao [Google VRP](https://bughunters.google.com/)
- Ataques que exijam acesso físico ao aparelho desbloqueado do profissional
- Engenharia social contra usuários
- Relatórios automáticos de scanner sem impacto demonstrado

## Segredos e configuração

Credenciais nunca são commitadas. Estão no `.gitignore`:

```
.env
.env.local
documentacao/chaves.md
android/app/google-services.json
ios/GoogleService-Info.plist
```

Os client IDs OAuth entram no build via `--dart-define`, e no CI via GitHub
Secrets (ver [`documentacao/CI_CD.md`](documentacao/CI_CD.md)). Se encontrar
algum segredo exposto no repositório ou no histórico, trate como vulnerabilidade
e reporte pelo canal acima.

## Conformidade

O projeto segue a **LGPD** (Lei 13.709/2018) por arquitetura: o profissional de
saúde é o controlador dos dados, e o aplicativo é apenas a interface de acesso à
base que já é dele.
