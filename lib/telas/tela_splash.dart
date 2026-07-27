import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../componentes/design_system.dart';
import 'tela_login.dart';

/// Duração total da coreografia de abertura.
const Duration kDuracaoSplash = Duration(milliseconds: 2400);

/// Duração do cross-fade entre a splash e a tela de destino.
const Duration kDuracaoTransicaoSplash = Duration(milliseconds: 420);

/// Tela de abertura animada.
///
/// A coreografia é montada sobre o gradiente da marca e termina com o logotipo
/// exatamente na posição/tamanho em que a [TelaLogin] o desenha — o cross-fade
/// final fica imperceptível, dando sensação de continuidade.
///
/// Linha do tempo (fração de [kDuracaoSplash]):
/// - 0.00–0.24 brilho radial abre atrás do logotipo
/// - 0.05–0.34 tile do logotipo entra (escala + leve rotação)
/// - 0.22–0.72 traçado do ECG é desenhado da esquerda para a direita
/// - 0.34–0.64 título revelado por wipe + brilho passando
/// - 0.44–0.70 subtítulo sobe e aparece
/// - 0.74–0.90 ECG some, restando só o logotipo (estado da TelaLogin)
class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key, this.construirDestino});

  /// Permite trocar o destino nos testes. Em produção é a [TelaLogin].
  final WidgetBuilder? construirDestino;

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  bool _iniciou = false;
  bool _navegou = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, duration: kDuracaoSplash);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciou) return;
    _iniciou = true;
    if (MediaQuery.of(context).disableAnimations) {
      // Acessibilidade: com "reduzir movimento" ligado não seguramos o usuário.
      _controlador.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _irParaDestino());
    } else {
      // `whenComplete` só dispara no fim real; se o widget for descartado no
      // meio, o ticker é cancelado e o callback nunca roda.
      _controlador.forward().whenComplete(_irParaDestino);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _irParaDestino() {
    if (_navegou || !mounted) return;
    _navegou = true;
    final construir = widget.construirDestino ?? (_) => const TelaLogin();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: kDuracaoTransicaoSplash,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => construir(context),
        transitionsBuilder: (context, animacao, _, filho) =>
            FadeTransition(opacity: animacao, child: filho),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FisioCores.primaryDark,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: FisioGradients.header),
        child: AnimatedBuilder(
          animation: _controlador,
          builder: (context, _) => _ConteudoSplash(t: _controlador.value),
        ),
      ),
    );
  }
}

// =============================================================================
// CONTEÚDO
// =============================================================================

class _ConteudoSplash extends StatelessWidget {
  const _ConteudoSplash({required this.t});

  /// Progresso global da coreografia (0–1).
  final double t;

  double _fatia(double inicio, double fim, {Curve curva = Curves.linear}) =>
      curva.transform(((t - inicio) / (fim - inicio)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final brilho = _fatia(0.0, 0.24, curva: Curves.easeOut);
    final entradaTile = _fatia(0.05, 0.34, curva: Curves.easeOutCubic);
    final traco = _fatia(0.22, 0.72, curva: Curves.easeInOutCubic);
    final revelaTitulo = _fatia(0.34, 0.64, curva: Curves.easeOutCubic);
    final subtitulo = _fatia(0.44, 0.70, curva: Curves.easeOutCubic);
    // O trilho do ECG surge junto com o logotipo e some antes do handoff.
    final entradaEcg = _fatia(0.12, 0.28, curva: Curves.easeOut);
    final saidaEcg = entradaEcg * (1 - _fatia(0.74, 0.90, curva: Curves.easeIn));

    // O batimento acompanha o traçado: cada pico R do ECG bombeia o coração.
    final batimento = _intensidadeBatimento(traco);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Brilho radial que "acende" atrás do logotipo.
        Align(
          alignment: const Alignment(0, -0.45),
          child: Transform.scale(
            scale: 0.7 + 0.3 * brilho,
            child: Opacity(
              opacity: brilho * (0.55 + 0.45 * batimento),
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      FisioCores.secondary.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Reflexo diagonal lento, dá profundidade ao gradiente.
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.6 + 2.6 * t, -1),
                    end: Alignment(-0.6 + 2.6 * t, 1),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bloco do logotipo — mesma métrica da TelaLogin.
        Align(
          alignment: const Alignment(0, -0.45),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: entradaTile,
                child: Transform.rotate(
                  angle: (1 - entradaTile) * -0.14,
                  child: Transform.scale(
                    scale: (0.62 + 0.38 * entradaTile) * (1 + 0.10 * batimento),
                    child: SizedBox(
                      key: const Key('splash_logotipo'),
                      width: 74,
                      height: 74,
                      child: CustomPaint(
                        painter: _PintorOndasPulso(
                          progressoTraco: traco,
                          entrada: entradaTile,
                        ),
                        child: _TileLogotipo(batimento: batimento),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _TituloRevelado(progresso: revelaTitulo),
              const SizedBox(height: 6),
              Opacity(
                opacity: subtitulo,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - subtitulo)),
                  child: Text(
                    'Gestão de atendimentos\ndomiciliares de fisioterapia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Traçado do ECG, logo abaixo do bloco central.
        Align(
          alignment: const Alignment(0, 0.12),
          child: Opacity(
            opacity: saidaEcg,
            child: SizedBox(
              key: const Key('splash_ecg'),
              width: math.min(MediaQuery.of(context).size.width * 0.78, 320),
              height: 72,
              child: CustomPaint(
                painter: _PintorEcg(progresso: traco),
                isComplex: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TileLogotipo extends StatelessWidget {
  const _TileLogotipo({required this.batimento});

  final double batimento;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.22 * batimento),
            blurRadius: 28 * batimento,
            spreadRadius: 2 * batimento,
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: Color.lerp(
          Colors.white,
          FisioCores.accent,
          0.35 * batimento,
        ),
        size: 38,
      ),
    );
  }
}

/// Título revelado por um wipe com brilho passando na borda do corte.
class _TituloRevelado extends StatelessWidget {
  const _TituloRevelado({required this.progresso});

  final double progresso;

  @override
  Widget build(BuildContext context) {
    // Wordmark de 4 letras: pede corpo maior e tracking apertado para ter
    // presença. A TelaLogin repete estes valores — o handoff depende disso.
    const texto = Text(
      'Alta',
      style: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -1.5,
      ),
    );

    if (progresso >= 1) return texto;

    const borda = 0.28;
    final fim = (progresso * (1 + borda)).clamp(0.0, 1.0);
    final inicio = (fim - borda).clamp(0.0, 1.0);

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, inicio, fim],
      ).createShader(rect),
      child: texto,
    );
  }
}

// =============================================================================
// ANIMAÇÃO DO BATIMENTO
// =============================================================================

/// Posição (em fração do traçado) dos picos R de cada complexo PQRST.
const List<double> _picosR = [0.20, 0.70];

/// Curva de um batimento real: sístole forte seguida do eco mais fraco
/// ("lub-dub"), em vez de um seno uniforme.
double _curvaBatimento(double desdeOPico) {
  if (desdeOPico < 0) return 0;
  double bump(double centro, double largura, double amplitude) {
    final x = (desdeOPico - centro) / largura;
    return amplitude * math.exp(-x * x);
  }

  return (bump(0, 0.05, 1.0) + bump(0.14, 0.07, 0.45)).clamp(0.0, 1.0);
}

/// Intensidade agregada do batimento no instante do traçado.
double _intensidadeBatimento(double progressoTraco) {
  var maior = 0.0;
  for (final pico in _picosR) {
    final v = _curvaBatimento(progressoTraco - pico);
    if (v > maior) maior = v;
  }
  return maior;
}

// =============================================================================
// PAINTERS
// =============================================================================

/// Anéis que se propagam a cada batimento, a partir do centro do logotipo.
class _PintorOndasPulso extends CustomPainter {
  _PintorOndasPulso({required this.progressoTraco, required this.entrada});

  final double progressoTraco;
  final double entrada;

  @override
  void paint(Canvas canvas, Size size) {
    if (entrada <= 0) return;
    final centro = size.center(Offset.zero);
    const alcance = 0.32; // quanto do traçado a onda leva para se dissipar

    for (final pico in _picosR) {
      final decorrido = progressoTraco - pico;
      if (decorrido < 0 || decorrido > alcance) continue;
      final e = decorrido / alcance;
      final raio = 40 + 110 * Curves.easeOutCubic.transform(e);
      final opacidade = (1 - e) * 0.45 * entrada;
      canvas.drawCircle(
        centro,
        raio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - e) + 0.6
          ..color = Color.lerp(
            Colors.white,
            FisioCores.secondary,
            e,
          )!.withValues(alpha: opacidade),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorOndasPulso antigo) =>
      antigo.progressoTraco != progressoTraco || antigo.entrada != entrada;
}

/// Traçado de eletrocardiograma com morfologia PQRST, desenhado
/// progressivamente da esquerda para a direita com um ponto luminoso na ponta.
class _PintorEcg extends CustomPainter {
  _PintorEcg({required this.progresso});

  final double progresso;

  /// Monta um complexo PQRST em coordenadas do canvas.
  ///
  /// [inicio] é o x de origem, [largura] o comprimento do complexo e
  /// [amplitude] a altura do pico R em pixels.
  void _complexo(
    Path path,
    double inicio,
    double largura,
    double base,
    double amplitude,
  ) {
    double x(double f) => inicio + largura * f;
    double y(double a) => base - amplitude * a;

    // Onda P (átrios) — arredondada e baixa.
    path.lineTo(x(0.10), base);
    path.quadraticBezierTo(x(0.155), y(0.20), x(0.21), base);
    path.lineTo(x(0.30), base);

    // Complexo QRS (ventrículos) — retas, é o pico agudo do sinal.
    path.lineTo(x(0.34), y(-0.13));
    path.lineTo(x(0.40), y(1.00));
    path.lineTo(x(0.46), y(-0.34));
    path.lineTo(x(0.51), base);

    // Onda T (repolarização) — larga e suave.
    path.lineTo(x(0.62), base);
    path.quadraticBezierTo(x(0.72), y(0.30), x(0.82), base);
    path.lineTo(x(1.00), base);
  }

  Path _construirTracado(Size size) {
    final base = size.height * 0.58;
    final amplitude = size.height * 0.42;
    final largura = size.width / 2;
    final path = Path()..moveTo(0, base);
    for (var i = 0; i < 2; i++) {
      _complexo(path, largura * i, largura, base, amplitude);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final completo = _construirTracado(size);

    // Trilho apagado: sugere o sinal inteiro antes de ser percorrido.
    canvas.drawPath(
      completo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    if (progresso <= 0) return;

    final metrica = completo.computeMetrics().first;
    final ateAqui = metrica.length * progresso.clamp(0.0, 1.0);
    final desenhado = metrica.extractPath(0, ateAqui);

    // Halo do traçado.
    canvas.drawPath(
      desenhado,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..color = FisioCores.accent.withValues(alpha: 0.35),
    );

    // Linha principal.
    canvas.drawPath(
      desenhado,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );

    // Ponto luminoso na ponta, como o cursor de um monitor cardíaco.
    final ponta = metrica.getTangentForOffset(ateAqui)?.position;
    if (ponta != null && progresso < 1) {
      canvas.drawCircle(
        ponta,
        9,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
          ..color = Colors.white.withValues(alpha: 0.55),
      );
      canvas.drawCircle(ponta, 3.2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_PintorEcg antigo) => antigo.progresso != progresso;
}
