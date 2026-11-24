import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'orange_palette.dart';

class OrangeLogo extends StatelessWidget {
  const OrangeLogo({this.size = 36, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: OrangePalette.orangeGradient,
        borderRadius: BorderRadius.circular(11),
      ),
      padding: EdgeInsets.all(size * .30),
      child: CustomPaint(painter: _OrangePainter()),
    ),
  );
}

class _OrangePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    for (var i = 0; i < 4; i++) {
      final d =
          Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) * radius;
      canvas.drawLine(center - d, center + d, paint);
    }
  }

  @override
  bool shouldRepaint(_OrangePainter oldDelegate) => false;
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.stripe,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? stripe;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: p.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stripe != null)
                  SizedBox(height: 3, child: ColoredBox(color: stripe!)),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });
  final String label;
  final Color color, background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    ),
  );
}

class ColorTile extends StatelessWidget {
  const ColorTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.footer,
    required this.color,
    required this.onTap,
    this.empty = false,
    super.key,
  });
  final String title, subtitle;
  final Widget icon, footer;
  final Color color;
  final VoidCallback onTap;
  final bool empty;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      empty
                          ? color.withValues(alpha: .5)
                          : Color.lerp(color, Colors.white, .07)!,
                      empty
                          ? color.withValues(alpha: .45)
                          : Color.lerp(color, Colors.black, .13)!,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(width: 25, height: 25, child: icon),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 6),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: p.secondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdaptiveTiles extends StatelessWidget {
  const AdaptiveTiles({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = scale > 1.4 && c.maxWidth < 600
          ? 1
          : c.maxWidth >= 1000
          ? 4
          : c.maxWidth >= 650
          ? 3
          : c.maxWidth >= 300
          ? 2
          : 1;
      return Column(
        children: [
          for (var row = 0; row < children.length; row += columns)
            Padding(
              padding: EdgeInsets.only(
                bottom: row + columns < children.length ? 10 : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 10),
                      Expanded(
                        child: row + column < children.length
                            ? children[row + column]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
