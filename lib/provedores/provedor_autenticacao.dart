import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servicos/preferencias.dart';
import '../servicos/servico_autenticacao_google.dart';
import '../utilitarios/mensagens_erro_google.dart';

final provedorServicoAutenticacaoGoogle = Provider<ServicoAutenticacaoGoogle>(
  (ref) => ServicoAutenticacaoGoogleReal(),
);

class EstadoAutenticacao {
  final bool estaAutenticado;
  final bool estaCarregando;
  final bool termosAceitos;
  final String? mensagemErro;
  final SessaoGoogle? sessao;
  final ContaGoogleConectada? contaConectada;

  EstadoAutenticacao({
    this.estaAutenticado = false,
    this.estaCarregando = false,
    this.termosAceitos = false,
    this.mensagemErro,
    this.sessao,
    this.contaConectada,
  });

  EstadoAutenticacao copiarCom({
    bool? estaAutenticado,
    bool? estaCarregando,
    bool? termosAceitos,
    String? mensagemErro,
    SessaoGoogle? sessao,
    ContaGoogleConectada? contaConectada,
  }) {
    return EstadoAutenticacao(
      estaAutenticado: estaAutenticado ?? this.estaAutenticado,
      estaCarregando: estaCarregando ?? this.estaCarregando,
      termosAceitos: termosAceitos ?? this.termosAceitos,
      mensagemErro: mensagemErro,
      sessao: sessao ?? this.sessao,
      contaConectada: contaConectada ?? this.contaConectada,
    );
  }
}

// Notificador de Estado
class AutenticacaoNotificador extends Notifier<EstadoAutenticacao> {
  @override
  EstadoAutenticacao build() {
    final servico = ref.read(provedorServicoAutenticacaoGoogle);
    // O serviço encaminha os erros de `authenticationEvents` para este stream
    // (`servico_autenticacao_google.dart`). Sem `onError` eles viravam exceção
    // não tratada e a tela voltava sem explicação nenhuma — um erro de
    // configuração ficava indistinguível de o usuário ter desistido.
    final assinaturaContas = servico.contasConectadas.listen(
      (conta) {
        state = state.copiarCom(
          estaCarregando: false,
          mensagemErro: null,
          contaConectada: conta,
        );
      },
      onError: (Object erro) {
        state = state.copiarCom(
          estaCarregando: false,
          mensagemErro: mensagemErroLoginGoogle(erro),
        );
      },
    );
    ref.onDispose(assinaturaContas.cancel);

    final assinaturaSessoes = servico.sessoesConectadas.listen(
      _autenticarComSessao,
      onError: (Object erro) {
        state = state.copiarCom(
          estaCarregando: false,
          mensagemErro: mensagemErroLoginGoogle(erro),
        );
      },
    );
    ref.onDispose(assinaturaSessoes.cancel);

    unawaited(
      servico.inicializar().catchError((Object _) {
        state = state.copiarCom(
          mensagemErro: 'Falha ao inicializar o login Google.',
        );
      }),
    );

    return EstadoAutenticacao();
  }

  void _autenticarComSessao(SessaoGoogle sessao) {
    // Não limpar `planilha_id` aqui: `entrarComGoogle` já garante (com
    // `await`) que a limpeza terminou antes de qualquer sessão ser publicada.
    // Uma limpeza solta e não aguardada pode terminar depois de
    // `obterPlanilhaId()` ter gravado o ID da planilha recém-criada, apagando
    // a referência e forçando uma nova busca no Drive.
    state = state.copiarCom(
      estaAutenticado: true,
      estaCarregando: false,
      mensagemErro: null,
      sessao: sessao,
    );
  }

  void aceitarTermos(bool aceitou) {
    state = state.copiarCom(termosAceitos: aceitou, mensagemErro: null);
  }

  Future<void> entrarComGoogle() async {
    if (!state.termosAceitos) {
      state = state.copiarCom(
        mensagemErro: 'Você precisa aceitar os Termos de Uso e LGPD.',
      );
      return;
    }

    state = state.copiarCom(estaCarregando: true, mensagemErro: null);

    final servico = ref.read(provedorServicoAutenticacaoGoogle);

    try {
      // Tenta restaurar a sessão anterior antes do fluxo interativo — mas só
      // no nativo. No web esse cache fica em memória e nunca sobrevive a um
      // recarregamento de página (é sempre `null` no caso comum), então a
      // checagem quase nunca evita o popup; ela só atrasaria, com uma
      // operação de rede de verdade, o toque do usuário até `servico.entrar()`
      // — e no Safari/WebKit do iOS isso já é o bastante para o navegador
      // deixar de reconhecer o popup como originado do clique e bloqueá-lo.
      // Na API 7.x, `tentarRestaurarSessao` já valida a autorização dos
      // escopos e devolve `null` quando só há identidade sem access token —
      // o app não precisa mais checar isso por fora.
      if (!kIsWeb) {
        final sessaoAnterior = await servico.tentarRestaurarSessao();
        if (sessaoAnterior != null) {
          await Preferencias.limparPlanilhaId();
          _autenticarComSessao(sessaoAnterior);
          return;
        }
      }

      if (!servico.suportaLoginProgramatico) {
        state = state.copiarCom(estaCarregando: false);
        return;
      }

      // `servico.entrar()` abre o popup de login do Google (no web) — precisa
      // ser chamado o quanto antes, sem `await` na frente, para não arriscar
      // que o navegador deixe de reconhecer a chamada como originada do toque
      // do usuário e bloqueie o popup (é rígido demais nisso no Safari/WebKit
      // do iOS). Por isso a limpeza de `planilha_id` roda em paralelo com o
      // login em vez de antes dele — mas ainda é aguardada até o fim antes de
      // qualquer sessão ser publicada, preservando a garantia descrita em
      // `_autenticarComSessao`.
      //
      // `servico.entrar()` já publica a sessão em `sessoesConectadas`, que o
      // listener registrado em `build()` consome chamando `_autenticarComSessao`
      // (atualiza `state` uma única vez). Definir `state` de novo aqui causaria
      // uma segunda notificação para o mesmo login, fazendo `TelaLogin` navegar
      // para `TelaDashboard` duas vezes seguidas — a primeira instância é
      // desmontada com o carregamento de dados ainda em andamento, e o uso de
      // `ref` depois do `await` nesse carregamento lança
      // "Bad state: ... unmounted".
      final entrando = servico.entrar();
      await Preferencias.limparPlanilhaId();
      await entrando;
    } catch (e, stackTrace) {
      developer.log(
        'Erro ao fazer login com Google',
        error: e,
        stackTrace: stackTrace,
        name: 'Autenticacao',
      );
      state = state.copiarCom(
        estaCarregando: false,
        mensagemErro: mensagemErroLoginGoogle(e),
      );
    }
  }

  Future<void> sair() async {
    await ref.read(provedorServicoAutenticacaoGoogle).sair();
    await Preferencias.limparPlanilhaId();
    state = EstadoAutenticacao();
  }
}

// Provedor
final provedorAutenticacao =
    NotifierProvider<AutenticacaoNotificador, EstadoAutenticacao>(
      AutenticacaoNotificador.new,
    );
