import 'package:material_ui/material_ui.dart';

import 'orange_palette.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final p = brightness == Brightness.light
        ? OrangePalette.light
        : OrangePalette.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF251739),
          surface: p.card,
          onSurface: p.ink,
          outline: p.line,
          error: p.red,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'packages/design_system/Manrope',
    );
    return base.copyWith(
      extensions: [p],
      scaffoldBackgroundColor: p.paper,
      textTheme: base.textTheme
          .apply(bodyColor: p.ink, displayColor: p.ink)
          .copyWith(
            bodyMedium: base.textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              height: 1.5,
              color: p.ink,
            ),
            bodyLarge: base.textTheme.bodyLarge!.copyWith(
              fontSize: 14,
              height: 1.5,
              color: p.secondary,
            ),
            titleLarge: base.textTheme.titleLarge!.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
            titleMedium: base.textTheme.titleMedium!.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.paper,
        foregroundColor: p.ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(
            fontFamily: 'packages/design_system/Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          backgroundColor: p.card,
          side: BorderSide(color: p.line),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(
            fontFamily: 'packages/design_system/Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: const TextStyle(
            fontFamily: 'packages/design_system/Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.line),
        ),
        hintStyle: TextStyle(color: p.muted, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        showDragHandle: true,
      ),
    );
  }
}
