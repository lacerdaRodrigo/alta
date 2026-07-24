import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../componentes/botao_google_renderizado.dart';
import '../componentes/design_system.dart';
import '../provedores/provedor_autenticacao.dart';
import 'tela_dashboard.dart';

class TelaLogin extends ConsumerStatefulWidget {
  const TelaLogin({super.key});

  @override
  ConsumerState<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends ConsumerState<TelaLogin> {
  bool _carregando = false;
  bool _navegou = false;
  ProviderSubscription<EstadoAutenticacao>? _assinaturaAuth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ouvirEstadoAutenticacao();
    });
  }

  @override
  void dispose() {
    _assinaturaAuth?.close();
    super.dispose();
  }

  void _ouvirEstadoAutenticacao() {
    // `initState` roda via addPostFrameCallback só uma vez por State, mas
    // guardamos e fechamos a assinatura em dispose() para nunca deixar um
    // listener duplicado escutando `provedorAutenticacao` (o que causaria
    // múltiplas navegações/logins para uma única mudança de estado).
    _assinaturaAuth?.close();
    _assinaturaAuth = ref.listenManual(provedorAutenticacao, (anterior, proximo) {
      // Um único login gera mais de uma notificação (a sessão e a conta
      // conectada chegam por streams distintos), e `TelaLogin` continua
      // montada durante a animação do `pushReplacement` — sem este guard a
      // segunda notificação empurra uma segunda `TelaDashboard` por cima da
      // primeira, desmontando-a com o carregamento de dados em andamento.
      if (!_navegou && proximo.estaAutenticado && mounted) {
        _navegou = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TelaDashboard(
              nomeUsuario: proximo.sessao?.nomeUsuario ?? 'Profissional',
            ),
          ),
        );
      }
      if (proximo.mensagemErro != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(proximo.mensagemErro!)),
        );
      }
    });
  }

  Future<void> _entrar() async {
    final auth = ref.read(provedorAutenticacao);
    if (!auth.termosAceitos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aceite os Termos de Uso e LGPD para continuar.')),
      );
      return;
    }
    setState(() => _carregando = true);
    try {
      await ref.read(provedorAutenticacao.notifier).entrarComGoogle();
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final termosAceitos = ref.watch(provedorAutenticacao).termosAceitos;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: FisioGradients.header),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.45),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 22),
                  const Text('Fisio Home Care',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6)),
                  const SizedBox(height: 6),
                  Text('Gestão de atendimentos\ndomiciliares de fisioterapia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82))),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: FisioCores.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BotaoEntrarGoogle(
                          carregando: _carregando,
                          termosAceitos: termosAceitos,
                          onTap: _entrar,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              key: const Key('checkbox_termos'),
                              onTap: () => ref
                                  .read(provedorAutenticacao.notifier)
                                  .aceitarTermos(!termosAceitos),
                              child: Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: termosAceitos
                                      ? FisioCores.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                      color: termosAceitos
                                          ? FisioCores.primary
                                          : const Color(0xFFCBD5E1),
                                      width: 2),
                                ),
                                child: termosAceitos
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                      color: FisioCores.textSecondary),
                                  children: [
                                    TextSpan(text: 'Li e concordo com a '),
                                    TextSpan(
                                        text: 'Política de Privacidade',
                                        style: TextStyle(
                                            color: FisioCores.primary,
                                            fontWeight: FontWeight.w700)),
                                    TextSpan(text: ' e os '),
                                    TextSpan(
                                        text: 'Termos de Uso',
                                        style: TextStyle(
                                            color: FisioCores.primary,
                                            fontWeight: FontWeight.w700)),
                                    TextSpan(
                                        text:
                                            ', e autorizo o tratamento dos meus dados conforme a LGPD.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 15, color: FisioCores.textMuted),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Seus dados ficam na sua própria planilha Google. Nada é armazenado em nossos servidores.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        color: FisioCores.textMuted)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão "Continuar com Google".
///
/// No web o Google Identity Services só aceita login iniciado pelo widget que
/// ele mesmo renderiza (`GoogleSignIn.authenticate()` lança `UnsupportedError`
/// e `supportsAuthenticate()` devolve `false`). Para preservar o visual do app,
/// o botão do Google fica invisível **sobre** o desenho, capturando o toque.
///
/// ⚠️ A sobreposição depende do widget do GIS ocupar a área do botão desenhado.
/// Se uma atualização do SDK mudar o tamanho ou o DOM do botão, o toque para de
/// cair no lugar certo — nesse caso, a saída suportada é exibir o botão do
/// Google diretamente, sem o desenho por baixo.
///
/// Fora do web `construirBotaoGoogleRenderizado` devolve um `SizedBox.shrink()`
/// e o toque é tratado pelo `GestureDetector` normalmente.
class _BotaoEntrarGoogle extends StatelessWidget {
  final bool carregando;
  final bool termosAceitos;
  final VoidCallback onTap;

  const _BotaoEntrarGoogle({
    required this.carregando,
    required this.termosAceitos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = !carregando && termosAceitos;
    final largura = MediaQuery.of(context).size.width - 44;

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          key: const Key('btn_entrar_google'),
          onTap: habilitado ? onTap : null,
          child: Opacity(
            opacity: termosAceitos ? 1 : 0.55,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (carregando)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: FisioCores.primary))
                  else
                    const _GoogleG(),
                  const SizedBox(width: 11),
                  const Text('Continuar com Google',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FisioCores.textPrimary)),
                ],
              ),
            ),
          ),
        ),
        // Só recebe o toque quando o login está liberado; enquanto os termos
        // não forem aceitos, `IgnorePointer` deixa o clique chegar ao
        // `GestureDetector` abaixo, que exibe a mensagem de erro.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !habilitado,
            child: Opacity(
              opacity: 0,
              child: OverflowBox(
                maxWidth: largura,
                child: construirBotaoGoogleRenderizado(larguraMinima: largura),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: const Text('G',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4285F4))),
    );
  }
}
