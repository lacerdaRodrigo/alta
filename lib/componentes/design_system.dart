import 'package:flutter/material.dart';

// =============================================================================
// CORES
// =============================================================================
class FisioCores {
  static const Color primary = Color(0xFF6C4CE0);
  static const Color primaryLight = Color(0xFF8A6FF0);
  static const Color primaryDark = Color(0xFF4A2FB2);
  static const Color secondary = Color(0xFF7CB9A8);
  static const Color secondaryDark = Color(0xFF5E9D8B);
  static const Color accent = Color(0xFFE8D5B7);

  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFC9515B);
  static const Color indigo = Color(0xFF6366F1);
  static const Color pink = Color(0xFFEC4899);

  static const Color surface = Color(0xFFF0F4F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color borda = Color(0xFFE8EEF2);
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const List<Color> avatarPalette = [primary, indigo, warning, pink];
}

class FisioGradients {
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FisioCores.primaryLight, FisioCores.primary, FisioCores.primaryDark],
    stops: [0.0, 0.5, 1.0],
  );
  static const LinearGradient sage = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FisioCores.secondary, FisioCores.secondaryDark],
  );
}

// =============================================================================
// TOKENS ANTIGOS (mantidos para compat)
// =============================================================================
class FisioEspacamentos {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class FisioRaios {
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

class FisioPontoQuebra {
  static const double tablet = 620;
  static const double desktop = 1024;
}

class FisioSombras {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

class FisioDecoracoes {
  static BoxDecoration card({
    Color color = FisioCores.card,
    double radius = FisioRaios.base,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: FisioCores.border.withValues(alpha: 0.7)),
      boxShadow: FisioSombras.card,
    );
  }

  static BoxDecoration tinted(Color color, {double radius = FisioRaios.md}) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    );
  }
}

// =============================================================================
// HELPERS DE AVATAR
// =============================================================================
const List<Color> _kAvatarPalette = [
  FisioCores.primary,
  Color(0xFF0EA5A4),
  FisioCores.warning,
  Color(0xFFEC4899),
  FisioCores.info,
  Color(0xFF8B5CF6),
];

Color fisioAvatarColor(String nome) =>
    _kAvatarPalette[nome.length % _kAvatarPalette.length];

String fisioIniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  return partes.take(2).map((p) => p[0]).join().toUpperCase();
}

// =============================================================================
// TEMA GLOBAL
// =============================================================================
ThemeData fisioTheme() {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: FisioCores.surface,
    colorScheme: base.colorScheme.copyWith(
      primary: FisioCores.primary,
      secondary: FisioCores.secondary,
      surface: FisioCores.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: FisioCores.textPrimary,
      displayColor: FisioCores.textPrimary,
    ),
  );
}

// =============================================================================
// LAYOUT
// =============================================================================
class FisioResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const FisioResponsiveCenter({super.key, required this.child, this.maxWidth = 620});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// =============================================================================
// HEADER EM GRADIENTE
// =============================================================================
class FisioGradientHeader extends StatelessWidget {
  final String? eyebrow;
  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final EdgeInsets padding;

  const FisioGradientHeader({
    super.key,
    required this.titulo,
    this.eyebrow,
    this.subtitulo,
    this.leading,
    this.trailing,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 52, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: FisioGradients.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null)
                      Text(eyebrow!.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: 0.66))),
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4)),
                    if (subtitulo != null)
                      Text(subtitulo!,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.72))),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

class FisioHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  const FisioHeaderIconButton(this.icon, {super.key, this.onTap, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

// =============================================================================
// CARD BASE
// =============================================================================
class FisioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const FisioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.onTap,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? FisioCores.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEBF0F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: card,
    );
  }
}

// =============================================================================
// STAT TILE
// =============================================================================
class FisioStatTile extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String valor;
  final String? sub;
  const FisioStatTile({
    super.key,
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.valor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return FisioCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icone, color: cor, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: FisioCores.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 11),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: FisioCores.textPrimary,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: FisioCores.textMuted)),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// STATUS PILL
// =============================================================================
class FisioStatusPill extends StatelessWidget {
  final String label;
  final Color cor;
  const FisioStatusPill({super.key, required this.label, required this.cor});

  factory FisioStatusPill.sessao(String status) {
    final s = status.toLowerCase();
    Color c;
    if (s.contains('realiz')) {
      c = FisioCores.success;
    } else if (s.contains('agend')) {
      c = FisioCores.info;
    } else if (s.contains('pend')) {
      c = FisioCores.warning;
    } else if (s.contains('cancel')) {
      c = FisioCores.danger;
    } else {
      c = FisioCores.textSecondary;
    }
    return FisioStatusPill(label: status, cor: c);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
        ],
      ),
    );
  }
}

// =============================================================================
// AVATAR
// =============================================================================
class FisioAvatar extends StatelessWidget {
  final String nome;
  final double size;
  final double radius;
  const FisioAvatar(this.nome, {super.key, this.size = 44, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    final cor = fisioAvatarColor(nome);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(fisioIniciais(nome),
          style: TextStyle(
              color: cor, fontWeight: FontWeight.w800, fontSize: size * 0.32)),
    );
  }
}

// =============================================================================
// SEGMENTED CONTROL
// =============================================================================
class FisioSegmented extends StatelessWidget {
  final List<String> opcoes;
  final int selecionado;
  final ValueChanged<int> onChanged;
  const FisioSegmented({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < opcoes.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selecionado ? FisioCores.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == selecionado
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]
                        : null,
                  ),
                  child: Text(opcoes[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: i == selecionado
                              ? FisioCores.primary
                              : FisioCores.textSecondary)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// FILTER CHIPS
// =============================================================================
class FisioFilterChips extends StatelessWidget {
  final List<String> filtros;
  final int selecionado;
  final ValueChanged<int> onChanged;
  // Item de ação opcional, rolando junto com os chips no mesmo scroll.
  final Widget? trailing;
  const FisioFilterChips({
    super.key,
    required this.filtros,
    required this.selecionado,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final total = filtros.length + (trailing != null ? 1 : 0);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i >= filtros.length) return trailing!;
          final sel = i == selecionado;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: sel ? FisioCores.primary : FisioCores.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: sel ? FisioCores.primary : const Color(0xFFE2E8F0)),
              ),
              child: Text(filtros[i],
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : FisioCores.textSecondary)),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// CAMPO DE BUSCA
// =============================================================================
class FisioSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool sobreGradiente;
  const FisioSearchField({
    super.key,
    this.hint = 'Buscar…',
    this.onChanged,
    this.sobreGradiente = true,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = sobreGradiente ? Colors.white : FisioCores.textPrimary;
    final corHint = sobreGradiente
        ? Colors.white.withValues(alpha: 0.78)
        : FisioCores.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      decoration: BoxDecoration(
        color: sobreGradiente
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: sobreGradiente
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: corHint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w500, color: corTexto),
              cursorColor: corTexto,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500, color: corHint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LABEL DE SEÇÃO (novo estilo)
// =============================================================================
class FisioSectionLabel extends StatelessWidget {
  final String texto;
  const FisioSectionLabel(this.texto, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(texto.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FisioCores.primary,
            letterSpacing: 0.6));
  }
}

// =============================================================================
// BOTÃO PRIMÁRIO
// =============================================================================
class FisioPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const FisioPrimaryButton(this.label, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: FisioGradients.sage,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: FisioCores.secondary.withValues(alpha: 0.6),
                blurRadius: 22,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

// =============================================================================
// ESCALA DE DOR
// =============================================================================
class FisioPainSlider extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  final String legendaEsq;
  final String legendaDir;
  const FisioPainSlider({
    super.key,
    required this.valor,
    required this.onChanged,
    this.legendaEsq = 'Sem dor',
    this.legendaDir = 'Máxima',
  });

  static Color cor(int v) {
    if (v <= 3) return FisioCores.success;
    if (v <= 6) return FisioCores.warning;
    return FisioCores.danger;
  }

  @override
  Widget build(BuildContext context) {
    final c = cor(valor);
    return FisioCard(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(legendaEsq,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FisioCores.textMuted)),
              Text('$valor',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: c,
                      height: 1,
                      letterSpacing: -0.5)),
              Text(legendaDir,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FisioCores.textMuted)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: c,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: Colors.white,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            ),
            child: Slider(
              value: valor.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================
class FisioEmptyState extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;
  const FisioEmptyState({
    super.key,
    required this.icone,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icone, size: 30, color: const Color(0xFFB6C2CC)),
          ),
          const SizedBox(height: 14),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569))),
          if (subtitulo != null) ...[
            const SizedBox(height: 3),
            Text(subtitulo!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: FisioCores.textMuted)),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM NAV com FAB central
// =============================================================================
class FisioNavItem {
  final IconData icon;
  final String label;
  const FisioNavItem(this.icon, this.label);
}

class FisioBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback? onFab;
  final List<FisioNavItem> itens;

  const FisioBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    this.onFab,
    this.itens = const [
      FisioNavItem(Icons.home_rounded, 'Início'),
      FisioNavItem(Icons.event_note_rounded, 'Sessões'),
      FisioNavItem(Icons.people_alt_rounded, 'Pacientes'),
      FisioNavItem(Icons.account_balance_wallet_rounded, 'Financeiro'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: FisioCores.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEEF2F5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 14)),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  _navBtn(i),
                  if (i == 1) const SizedBox(width: 50),
                ],
              ],
            ),
          ),
          if (onFab != null)
            Positioned(
              top: -16,
              child: GestureDetector(
                onTap: onFab,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: FisioGradients.sage,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                          color: FisioCores.secondary.withValues(alpha: 0.7),
                          blurRadius: 22,
                          offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navBtn(int i) {
    final ativo = i == index;
    final cor = ativo ? FisioCores.primary : const Color(0xFFA8B4BE);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(itens[i].icon, color: cor, size: 22),
            const SizedBox(height: 3),
            Text(itens[i].label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: cor)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTES LEGADOS (mantidos para telas não migradas)
// =============================================================================

class FisioPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onBack;
  final bool closeIcon;
  final Widget? trailing;
  const FisioPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onBack,
    this.closeIcon = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    const foreground = FisioCores.textPrimary;
    const secondaryColor = FisioCores.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(FisioRaios.lg),
          bottomRight: Radius.circular(FisioRaios.lg),
        ),
        boxShadow: FisioSombras.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            IconButton(
              key: const Key('btn_fechar'),
              icon: Icon(
                closeIcon ? Icons.close_rounded : Icons.arrow_back_rounded,
              ),
              color: foreground,
              onPressed: onBack,
            ),
            const SizedBox(width: FisioEspacamentos.xs),
          ] else if (leadingIcon != null) ...[
            FisioIconBox(icon: leadingIcon!, color: FisioCores.primary),
            const SizedBox(width: FisioEspacamentos.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: FisioEspacamentos.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class FisioSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const FisioSectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FisioIconBox(icon: icon, color: FisioCores.primary, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: FisioCores.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class FisioBadge extends StatelessWidget {
  final String label;
  final Color color;

  const FisioBadge({
    super.key,
    required this.label,
    this.color = FisioCores.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FisioRaios.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FisioIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const FisioIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: FisioDecoracoes.tinted(color, radius: FisioRaios.base),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

enum FisioButtonVariant { filled, outlined, ghost }

class FisioButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final FisioButtonVariant variant;
  final Color? color;
  final VoidCallback? onPressed;

  const FisioButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = FisioButtonVariant.filled,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? FisioCores.primary;

    switch (variant) {
      case FisioButtonVariant.filled:
        return ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: FisioEspacamentos.xl,
              vertical: FisioEspacamentos.base,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FisioRaios.base),
            ),
          ),
        );
      case FisioButtonVariant.outlined:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c),
            padding: const EdgeInsets.symmetric(
              horizontal: FisioEspacamentos.xl,
              vertical: FisioEspacamentos.base,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FisioRaios.base),
            ),
          ),
        );
      case FisioButtonVariant.ghost:
        return TextButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: c,
            padding: const EdgeInsets.symmetric(
              horizontal: FisioEspacamentos.xl,
              vertical: FisioEspacamentos.base,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FisioRaios.base),
            ),
          ),
        );
    }
  }
}
