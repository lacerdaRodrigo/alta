# QA — Script de Testes E2E (Mobile)

Você é um Analista de Qualidade Sênior. Sua tarefa é criar scripts de teste E2E (passo a passo) para o sistema descrito abaixo, no formato definido neste documento.

---

## Informações do Sistema

**Nome:** Alta — Gestão de Fisioterapia Domiciliar

**Descrição:** Aplicativo mobile e web desenvolvido em Flutter para fisioterapeutas que atendem em domicílio. Permite autenticação via Google Sign-In, gestão de pacientes, agendamento de sessões, registro de evoluções clínicas e consulta operacional da agenda. Os dados são armazenados na planilha `__saas_fisio_db__` do Google Drive do próprio profissional (modelo BYODB), sem servidor central de prontuários, em conformidade com a LGPD.

**Plataformas:** Android (dispositivo físico ou emulador) e Web.

**Módulos a cobrir:** Login e Consentimento LGPD, Dashboard (Início), Pacientes, Cadastro de Paciente, Nova Sessão, Sessões (histórico da agenda), Registro de Evolução, Histórico de Evoluções, Configurações.

**Perfil de usuário:** Fisioterapeuta (Usuário Profissional).

**Regras de negócio relevantes:**
- **Login:** O botão "Entrar com Google" permanece desabilitado até o aceite explícito do termo LGPD (checkbox obrigatório).
- **Autenticação:** Integração obrigatória com Google Sign-In; na Web, a autorização de acesso ao Drive/Sheets ocorre em ação explícita separada do login.
- **Armazenamento:** Dados clínicos persistidos exclusivamente na planilha `__saas_fisio_db__` da conta Google do profissional; escopo OAuth restrito (`drive.file`).
- **Isolamento:** Cada fisioterapeuta possui sua própria planilha; não há acesso cruzado entre contas.
- **Agenda do dia:** Exibe somente sessões com `Situacao = "Agendado"` na data atual; sessões antigas sem desfecho aparecem em **Pendências**.
- **Desfechos de sessão:** `Realizado`, `Cancelado`, `Cancelado pelo paciente`, `Cancelado pelo profissional`, `Faltou com aviso`, `Faltou sem aviso`.
- **Nova sessão:** Não permite agendar horários retroativos (anteriores ao momento atual).
- **Pacientes:** Cadastro com validação de campos obrigatórios (nome, CPF, telefone, endereço, dados clínicos iniciais); filtros `Todos` e `Ativos`.
- **Evolução clínica:** Registro estruturado obrigatório após atendimento realizado.
- **Rotas:** Integração com Google Maps e Waze a partir do endereço do paciente.
- **LGPD:** O profissional atua como Controlador dos dados; o app exige consentimento na entrada e oferece ferramentas de privacidade em Configurações.

---

## Escopo dos Testes

Cobrir obrigatoriamente:
- Cenários positivos (fluxo feliz)
- Cenários negativos (erros, dados inválidos, permissões negadas)
- Validação de regras de negócio
- Fluxos principais e alternativos

Não incluir:
- Testes de performance, carga ou estresse
- Testes de segurança avançados

---

## Template do Script de Teste

Cada teste deve seguir exatamente este formato:

---

### CT[NN] - [Nome descritivo do caso de teste]

#### Pré-Condições
- [Condição 1]
- [Condição 2]

#### Passos

| # | Ação do Usuário | Resultado Esperado |
|---|-----------------|-------------------|
| 1 | [O que o testador faz] | [O que o sistema deve exibir/comportar] |
| 2 | ... | ... |

#### Critérios de Aceitação
- [ ] [Condição 1 para o teste passar]
- [ ] [Condição 2 para o teste passar]

---

## Instruções de Geração

1. Numere os testes sequencialmente: CT01, CT02, CT03...
2. Cada passo deve ser uma **ação concreta do usuário** seguida do **resultado esperado**.
3. Seja detalhado — qualquer pessoa deve conseguir executar o teste sem dúvidas.
4. Cubra no mínimo: fluxo feliz, fluxo com erro/validação, e fluxo alternativo para cada módulo.
5. Gere o arquivo em `test/e2e/[MODULO]_test.md`.
6. Não inclua comandos de ferramentas (mobile-mcp, adb, etc.) — apenas ação do usuário e resultado esperado.

---

## Automação com Mobilewright — Aprendizados Práticos

Esta seção documenta descobertas durante a implementação de testes automatizados com Mobilewright (Playwright-style para Android) em app Flutter.

### 1. Diálogos do Sistema (Google Play Services)

O modal "Escolha uma conta" do Google pertence ao processo `com.google.android.gms`, **não** ao app Flutter. O Mobilewright não enxerga esses elementos na view tree.

**Solução:** usar `child_process.execSync` para enviar toques diretamente via ADB:

```ts
execSync(`adb -s ${DEVICE} shell input tap ${x} ${y}`);
```

Isso funciona porque `adb shell input tap` opera no nível do sistema Android.

### 2. `getByLabel` vs Coordenadas

Em apps Flutter, todo conteúdo de texto vai para o campo `label` da acessibilidade, com `text` vazio. Isso significa:

- Elementos que você espera como `getByText(...)` **não funcionam**
- Use `getByLabel(...)` com o texto exato visível no app
- Para interagir com elementos que não aparecem na view tree (ex: checkbox Flutter), use coordenadas fixas via `screen.tap(x, y)` ou `adb shell input tap`

### 3. Estados de Sessão e Ordem dos Testes

Testes de login precisam de estado determinístico. Após um login bem-sucedido, a sessão persiste em disco e o app pula a tela de login nos próximos lançamentos.

**Regras:**
- Use `test.beforeAll()` com `adb shell pm clear com.app.package` para limpar dados antes da suíte
- Testes que dependem da tela de login (CT01, CT02, CT05) devem vir **antes** dos testes que logam (CT03)
- Testes que precisam de sessão (CT04, CT07) devem verificar se já estão logados e fazer login como fallback

### 4. `launchApp` e Diálogos Residuais

Se um diálogo do Google Play Services ficar aberto após um teste (ex: o app foi terminado enquanto o modal estava visível), o `launchApp` do teste seguinte falha porque o overlay impede o app de ir para foreground.

**Solução:** sempre garantir que diálogos do sistema estão fechados antes de relançar o app. Use `adb shell input keyevent KEYCODE_BACK` para fechar qualquer diálogo residual.

### 5. Scroll e Elementos Fora da Tela

Para clicar em elementos que exigem scroll (ex: botão "Sair da conta" na tela de Configurações), use `screen.swipe('up', { distance: ... })` antes de interagir com o elemento.

### 6. Padrão Recomendado para Helpers

```ts
import { execSync } from 'child_process';
const DEVICE = 'RQ8R70GZTLA';

function adbTap(x: number, y: number) {
  execSync(`adb -s ${DEVICE} shell input tap ${x} ${y}`);
}

function adbBack() {
  execSync(`adb -s ${DEVICE} shell input keyevent KEYCODE_BACK`);
}
```

Use este helper para interagir com qualquer elemento na tela, seja do app ou do sistema.

### 7. Validação de Campos Obrigatórios via AlertDialog

A validação de campos obrigatórios (Nome, CPF, Telefone, Data de Nascimento, Endereço) no cadastro de paciente usa `AlertDialog` em vez de validadores inline do `TextFormField`, pois os erros inline do Flutter **não são expostos na árvore de acessibilidade do Android**.

**Comportamento:**
- Ao clicar "Salvar Paciente" com campos vazios → `AlertDialog` com título "Campos obrigatórios" e lista dos itens faltando
- Cada item da lista aparece como texto acessível → `getByLabel('Nome Completo')` funciona
- Botão "OK" fecha o dialog → `getByLabel('OK').tap()`
- `barrierDismissible: false` — só fecha clicando no botão OK

**Mock para testes Flutter:**
```dart
class MockListaPacientesNotifier extends ListaPacientesNotifier {
  @override
  List<Paciente> pacientes = [];
  @override
  Future<void> adicionarPaciente(Paciente paciente) async {
    pacientes.add(paciente);
  }
}
```

**Testes unitários (6):**
- CT-F1: 5 campos vazios → dialog com 5 itens
- CT-F2: só Nome preenchido → dialog com 4 itens
- CT-F3: só CPF preenchido → dialog com 4 itens
- CT-F4: Nome+CPF+Telefone → dialog com 2 itens (Data, Endereço)
- CT-F5: todos preenchidos → salva sem dialog
- CT-F6: dialog fecha ao clicar OK

### 8. `getByLabel` em AlertDialog

O Flutter expõe `AlertDialog.title`, `AlertDialog.content` Text widgets e `TextButton` como labels acessíveis. Para testar:

```ts
// Esperar o dialog aparecer
await expect(screen.getByLabel('Campos obrigatórios')).toBeVisible();
// Verificar itens da lista
await expect(screen.getByLabel('Nome Completo')).toBeVisible();
await expect(screen.getByLabel('CPF')).toBeVisible();
// Fechar o dialog
await screen.getByLabel('OK').tap();
// Confirmar que fechou
await expect(screen.getByLabel('Campos obrigatórios')).not.toBeVisible();
```
