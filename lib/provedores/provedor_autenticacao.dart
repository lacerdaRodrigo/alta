import 'dart:async';
import 'dart:developer' as developer;

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
    final assinaturaContas = servico.contasConectadas.listen((conta) {
      state = state.copiarCom(
        estaCarregando: false,
        mensagemErro: null,
        contaConectada: conta,
      );
    });
    ref.onDispose(assinaturaContas.cancel);

    final assinaturaSessoes = servico.sessoesConectadas.listen(
      _autenticarComSessao,
      onError: (Object _) {
        state = state.copiarCom(
          estaCarregando: false,
          mensagemErro:
              'Falha ao autenticar. Verifique sua conexão e tente novamente.',
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
    // Não limpar `planilha_id` aqui: `entrarComGoogle` já faz isso (com
    // `await`) antes do login. Uma limpeza solta e não aguardada pode terminar
    // depois de `obterPlanilhaId()` ter gravado o ID da planilha recém-criada,
    // apagando a referência e forçando uma nova busca no Drive.
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
    await Preferencias.limparPlanilhaId();

    final servico = ref.read(provedorServicoAutenticacaoGoogle);

    try {
      // Tenta restaurar a sessão anterior antes do fluxo interativo. Na API
      // 7.x, `tentarRestaurarSessao` já valida a autorização dos escopos e
      // devolve `null` quando só há identidade sem access token — o app não
      // precisa mais checar isso por fora.
      final sessaoAnterior = await servico.tentarRestaurarSessao();
      if (sessaoAnterior != null) {
        _autenticarComSessao(sessaoAnterior);
        return;
      }

      // No web o login não pode ser disparado por código: o Google Identity
      // Services exige que parta do botão que ele mesmo renderiza. A
      // `TelaLogin` sobrepõe esse botão ao visual do app, e o login chega pelo
      // stream `sessoesConectadas`. Aqui só encerramos o estado de carregamento
      // para o botão do Google voltar a ficar utilizável.
      if (!servico.suportaLoginProgramatico) {
        state = state.copiarCom(estaCarregando: false);
        return;
      }

      // `servico.entrar()` já publica a sessão em `sessoesConectadas`, que o
      // listener registrado em `build()` consome chamando `_autenticarComSessao`
      // (atualiza `state` uma única vez). Definir `state` de novo aqui causaria
      // uma segunda notificação para o mesmo login, fazendo `TelaLogin` navegar
      // para `TelaDashboard` duas vezes seguidas — a primeira instância é
      // desmontada com o carregamento de dados ainda em andamento, e o uso de
      // `ref` depois do `await` nesse carregamento lança
      // "Bad state: ... unmounted".
      await servico.entrar();
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
