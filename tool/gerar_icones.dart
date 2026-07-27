// Gerador do ícone do aplicativo.
//
// Não faz parte do app nem da suíte de testes (fica fora de `test/`, então
// `flutter test` não o executa). Rode com:
//
//   make icones      # ou: flutter test tool/gerar_icones.dart
//
// O desenho é vetorial e renderizado pelo próprio engine do Flutter, em cada
// tamanho final — nada é obtido por redimensionamento, então o traço fica
// nítido também nos ícones pequenos.
//
// Marca: coração (mesmo símbolo da TelaLogin/TelaSplash) atravessado por um
// pulso de eletrocardiograma em espaço negativo, sobre o gradiente violeta.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alta/componentes/design_system.dart';

/// Como o fundo do ícone é tratado em cada plataforma.
enum FormatoIcone {
  /// Gradiente com cantos arredondados (Android legado, web, favicon).
  arredondado,

  /// Gradiente sangrando até a borda (iOS e ícones "maskable" do web, que
  /// recebem a máscara do próprio sistema).
  quadrado,

  /// Círculo cheio — `roundIcon` dos launchers anteriores ao Android 8.
  redondo,

  /// Gradiente arredondado com margem, no estilo dos ícones do macOS.
  squircle,

  /// Só a marca, sem fundo (camada de frente do ícone adaptativo do Android).
  transparente,

  /// Silhueta branca para o tema monocromático do Android 13+.
  monocromatico,
}

// Caixa de desenho da marca. O coração é mais baixo que largo.
const double _larguraMarca = 100;
const double _alturaMarca = 94;

/// Coração de lóbulos arredondados, alinhado ao `Icons.favorite_rounded`.
Path _caminhoCoracao() {
  return Path()
    ..moveTo(50, 88)
    ..cubicTo(20, 66, 4, 50, 4, 32)
    ..cubicTo(4, 16, 16, 6, 29, 6)
    ..cubicTo(38, 6, 46, 11, 50, 18)
    ..cubicTo(54, 11, 62, 6, 71, 6)
    ..cubicTo(84, 6, 96, 16, 96, 32)
    ..cubicTo(96, 50, 80, 66, 50, 88)
    ..close();
}

/// Pulso que atravessa o coração de ponta a ponta (vai além da caixa de
/// propósito, para o corte encostar nas duas bordas da silhueta).
Path _caminhoPulso() {
  // A base fica abaixo do meio do coração: mantém massa nos lóbulos e deixa a
  // ponta inferior inteira, então a silhueta continua lendo como coração.
  return Path()
    ..moveTo(-12, 53)
    ..lineTo(37, 53)
    ..lineTo(45, 27)
    ..lineTo(56, 73)
    ..lineTo(63, 53)
    ..lineTo(112, 53);
}

/// Desenha a marca dentro de [area], já recortada pelo pulso.
void _pintarMarca(Canvas canvas, Rect area, Color cor) {
  final escala = area.width / _larguraMarca;
  final matriz = Matrix4.identity()
    ..translateByDouble(area.left, area.top, 0, 1)
    ..scaleByDouble(escala, escala, 1, 1);

  final coracao = _caminhoCoracao().transform(matriz.storage);
  final pulso = _caminhoPulso().transform(matriz.storage);

  // saveLayer isola o BlendMode.clear: o corte remove só o coração, não o
  // fundo já pintado.
  canvas.saveLayer(area.inflate(area.width), Paint());
  canvas.drawPath(coracao, Paint()..color = cor);
  canvas.drawPath(
    pulso,
    Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * escala
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.restore();
}

void _pintarFundo(Canvas canvas, Rect area, double raio) {
  final rrect = RRect.fromRectAndRadius(area, Radius.circular(raio));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          FisioCores.primaryLight,
          FisioCores.primary,
          FisioCores.primaryDark,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(area),
  );

  // Brilho no canto superior esquerdo: dá volume sem sujar o ícone pequeno.
  canvas.save();
  canvas.clipRRect(rrect);
  canvas.drawCircle(
    area.topLeft + Offset(area.width * 0.22, area.height * 0.18),
    area.width * 0.62,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: area.topLeft + Offset(area.width * 0.22, area.height * 0.18),
          radius: area.width * 0.62,
        ),
      ),
  );
  canvas.restore();
}

void pintarIcone(Canvas canvas, double lado, FormatoIcone formato) {
  final tela = Rect.fromLTWH(0, 0, lado, lado);

  switch (formato) {
    case FormatoIcone.arredondado:
      _pintarFundo(canvas, tela, lado * 0.225);
      _pintarMarca(canvas, _areaMarca(tela, 0.60), Colors.white);
    case FormatoIcone.quadrado:
      _pintarFundo(canvas, tela, 0);
      // Zona segura dos ícones "maskable": a marca cabe no círculo central.
      _pintarMarca(canvas, _areaMarca(tela, 0.56), Colors.white);
    case FormatoIcone.redondo:
      _pintarFundo(canvas, tela, lado / 2);
      _pintarMarca(canvas, _areaMarca(tela, 0.54), Colors.white);
    case FormatoIcone.squircle:
      final area = tela.deflate(lado * 0.085);
      _pintarFundo(canvas, area, area.width * 0.225);
      _pintarMarca(canvas, _areaMarca(area, 0.60), Colors.white);
    case FormatoIcone.transparente:
    case FormatoIcone.monocromatico:
      // Camada de frente do ícone adaptativo: 108dp de tela, 66dp de zona
      // segura — a marca fica bem menor que o quadro.
      _pintarMarca(canvas, _areaMarca(tela, 0.50), Colors.white);
  }
}

/// Retângulo da marca, centrado em [area] e ocupando [fracao] da largura.
Rect _areaMarca(Rect area, double fracao) {
  final largura = area.width * fracao;
  final altura = largura * _alturaMarca / _larguraMarca;
  return Rect.fromCenter(
    center: area.center,
    width: largura,
    height: altura,
  );
}

Future<void> _gerar(String caminho, int lado, FormatoIcone formato) async {
  final gravador = ui.PictureRecorder();
  final canvas = Canvas(
    gravador,
    Rect.fromLTWH(0, 0, lado.toDouble(), lado.toDouble()),
  );
  pintarIcone(canvas, lado.toDouble(), formato);
  final imagem = await gravador.endRecording().toImage(lado, lado);
  final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
  File(caminho)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('  ✓ $caminho (${lado}px)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gera os ícones do aplicativo', (tester) async {
    await tester.runAsync(() async {
      // --- Android: ícone legado -------------------------------------------
      const ladosLegado = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      const ladosAdaptativo = {
        'mdpi': 108,
        'hdpi': 162,
        'xhdpi': 216,
        'xxhdpi': 324,
        'xxxhdpi': 432,
      };
      for (final densidade in ladosLegado.keys) {
        final dir = 'android/app/src/main/res/mipmap-$densidade';
        await _gerar(
          '$dir/ic_launcher.png',
          ladosLegado[densidade]!,
          FormatoIcone.arredondado,
        );
        await _gerar(
          '$dir/ic_launcher_round.png',
          ladosLegado[densidade]!,
          FormatoIcone.redondo,
        );
        await _gerar(
          '$dir/ic_launcher_foreground.png',
          ladosAdaptativo[densidade]!,
          FormatoIcone.transparente,
        );
        await _gerar(
          '$dir/ic_launcher_monochrome.png',
          ladosAdaptativo[densidade]!,
          FormatoIcone.monocromatico,
        );
      }

      // --- Web --------------------------------------------------------------
      await _gerar('web/favicon.png', 32, FormatoIcone.arredondado);
      await _gerar('web/icons/Icon-192.png', 192, FormatoIcone.arredondado);
      await _gerar('web/icons/Icon-512.png', 512, FormatoIcone.arredondado);
      await _gerar(
        'web/icons/Icon-maskable-192.png',
        192,
        FormatoIcone.quadrado,
      );
      await _gerar(
        'web/icons/Icon-maskable-512.png',
        512,
        FormatoIcone.quadrado,
      );

      // --- iOS ---------------------------------------------------------------
      const iosPasta = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      const iosIcones = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
      };
      for (final entrada in iosIcones.entries) {
        await _gerar('$iosPasta/${entrada.key}', entrada.value,
            FormatoIcone.quadrado);
      }

      // --- macOS -------------------------------------------------------------
      const macPasta = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
      for (final lado in [16, 32, 64, 128, 256, 512, 1024]) {
        await _gerar('$macPasta/app_icon_$lado.png', lado,
            FormatoIcone.squircle);
      }

      // --- Master para o .ico do Windows e para lojas -------------------------
      await _gerar('build/icone_mestre_1024.png', 1024,
          FormatoIcone.arredondado);
    });
  });
}
