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
    this.quiet = false,
    this.badge,
    super.key,
  });
  final String title, subtitle;
  final Widget icon, footer;
  final Color color;
  final VoidCallback onTap;
  final bool empty, quiet;
  final Widget? badge;
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
                padding: EdgeInsets.fromLTRB(
                  quiet ? 10 : 12,
                  quiet ? 10 : 12,
                  quiet ? 10 : 12,
                  quiet ? 4 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      quiet
                          ? p.card
                          : empty
                          ? Color.lerp(color, p.card, .62)!
                          : Color.lerp(color, Colors.white, .07)!,
                      quiet
                          ? p.card
                          : empty
                          ? Color.lerp(color, p.card, .62)!
                          : Color.lerp(color, Colors.black, .13)!,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: quiet ? 30 : 25,
                        height: quiet ? 30 : 25,
                        padding: quiet
                            ? const EdgeInsets.all(6)
                            : EdgeInsets.zero,
                        decoration: quiet
                            ? BoxDecoration(
                                color: p.accentSoft,
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: icon,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: quiet ? p.ink : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: quiet
                              ? 12
                              : MediaQuery.sizeOf(context).width <= 760
                              ? 13.5
                              : 15,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (quiet || MediaQuery.sizeOf(context).width > 760)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    quiet ? 10 : 14,
                    quiet ? 5 : 8,
                    quiet ? 10 : 14,
                    0,
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: p.secondary,
                    ),
                  ),
                ),
              if (badge != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: badge!,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  quiet ? 5 : 8,
                  10,
                  quiet ? 10 : 14,
                ),
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
          : c.maxWidth >= 1036
          ? 4
          : c.maxWidth >= 774
          ? 3
          : c.maxWidth >= 300
          ? 2
          : 1;
      return Column(
        children: [
          for (var row = 0; row < children.length; row += columns)
            Padding(
              padding: EdgeInsets.only(
                bottom: row + columns < children.length ? 12 : 0,
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

/// A disclosure row whose children retain state while collapsed or resized.
class QuietFold extends StatefulWidget {
  const QuietFold({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.compact = false,
    super.key,
  });
  final Widget title;
  final List<Widget> children;
  final bool initiallyExpanded, compact;
  @override
  State<QuietFold> createState() => _QuietFoldState();
}

class _QuietFoldState extends State<QuietFold> {
  late bool _open = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) Divider(color: p.line, height: 1),
        Semantics(
          expanded: _open,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.compact ? 28 : 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    if (widget.compact)
                      Icon(
                        _open ? Icons.arrow_drop_down : Icons.arrow_right,
                        size: 13,
                        color: p.accent,
                      ),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: widget.compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: widget.compact ? p.accent : p.ink,
                        ),
                        child: widget.title,
                      ),
                    ),
                    if (!widget.compact)
                      Icon(
                        _open ? Icons.expand_less : Icons.expand_more,
                        size: 17,
                        color: p.accent,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Offstage(
          offstage: !_open,
          child: TickerMode(
            enabled: _open,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OptionChip extends StatelessWidget {
  const OptionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.softSelection = false,
    super.key,
  });
  final bool softSelection;
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? (softSelection ? p.accentSoft : p.accent) : p.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? p.accent : p.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 11,
              vertical: softSelection ? 9 : 6,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? (softSelection ? p.accent : Colors.white)
                    : p.secondary,
              ),
              child: label,
            ),
          ),
        ),
      ),
    );
  }
}
