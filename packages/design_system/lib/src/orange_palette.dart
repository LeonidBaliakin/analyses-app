import 'package:material_ui/material_ui.dart';

@immutable
class OrangePalette extends ThemeExtension<OrangePalette> {
  const OrangePalette({
    required this.paper,
    required this.card,
    required this.line,
    required this.ink,
    required this.secondary,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.orangeSoft,
    required this.green,
    required this.greenSoft,
    required this.red,
    required this.redSoft,
    required this.blue,
    required this.blueSoft,
  });

  final Color paper, card, line, ink, secondary, muted, accent, accentSoft;
  final Color orangeSoft, green, greenSoft, red, redSoft, blue, blueSoft;
  static const violetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9A77E0), Color(0xFF7F5FBC)],
  );
  static const orange = Color(0xFFF97316);
  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB923C), Color(0xFFE8590C)],
  );
  static const bloodGroup = Color(0xFFC8364B);
  static const metabolismGroup = Color(0xFFC98410);
  static const hormoneGroup = Color(0xFF7B4FD0);
  static const organGroup = Color(0xFF14907F);
  static const immunityGroup = Color(0xFF2B6FD4);
  static const tumorGroup = Color(0xFFB83A82);

  // Legacy demo order. New records select named tokens by stable category.
  static const systemColors = [
    bloodGroup,
    metabolismGroup,
    hormoneGroup,
    organGroup,
    immunityGroup,
    tumorGroup,
  ];

  static const light = OrangePalette(
    paper: Color(0xFFF4F2F9),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE7E3F0),
    ink: Color(0xFF1C1930),
    secondary: Color(0xFF4A4660),
    muted: Color(0xFF685F78),
    accent: Color(0xFF7C5CE0),
    accentSoft: Color(0xFFF0EDFB),
    orangeSoft: Color(0xFFFFF1E8),
    green: Color(0xFF15803D),
    greenSoft: Color(0xFFE7F8EE),
    red: Color(0xFFDC2626),
    redSoft: Color(0xFFFEE2E2),
    blue: Color(0xFF2563EB),
    blueSoft: Color(0xFFDBEAFE),
  );
  static const dark = OrangePalette(
    paper: Color(0xFF17141F),
    card: Color(0xFF24202F),
    line: Color(0xFF494054),
    ink: Color(0xFFF4EFFB),
    secondary: Color(0xFFD0C7DD),
    muted: Color(0xFFB1A5C0),
    accent: Color(0xFFB49AFF),
    accentSoft: Color(0xFF36294F),
    orangeSoft: Color(0xFF42291F),
    green: Color(0xFF87D7A5),
    greenSoft: Color(0xFF203C2B),
    red: Color(0xFFFFAAA9),
    redSoft: Color(0xFF49262F),
    blue: Color(0xFF9ABEFF),
    blueSoft: Color(0xFF243550),
  );
  static OrangePalette of(BuildContext context) =>
      Theme.of(context).extension<OrangePalette>()!;

  @override
  OrangePalette copyWith() => this;

  @override
  OrangePalette lerp(OrangePalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return OrangePalette(
      paper: c(paper, other.paper),
      card: c(card, other.card),
      line: c(line, other.line),
      ink: c(ink, other.ink),
      secondary: c(secondary, other.secondary),
      muted: c(muted, other.muted),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      orangeSoft: c(orangeSoft, other.orangeSoft),
      green: c(green, other.green),
      greenSoft: c(greenSoft, other.greenSoft),
      red: c(red, other.red),
      redSoft: c(redSoft, other.redSoft),
      blue: c(blue, other.blue),
      blueSoft: c(blueSoft, other.blueSoft),
    );
  }
}
