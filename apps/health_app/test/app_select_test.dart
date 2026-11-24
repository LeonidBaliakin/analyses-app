import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('selection supports keyboard and dismissal, dark=$dark', (
      tester,
    ) async {
      var value = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setState) => AppSelect<int>(
                  label: 'Theme',
                  value: value,
                  options: const [
                    AppSelectOption(value: 0, label: 'System'),
                    AppSelectOption(value: 1, label: 'Dark'),
                    AppSelectOption(value: 2, label: 'Light'),
                  ],
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNWidgets(3));
      final menu = find.byWidgetPredicate(
        (widget) => widget is Material && widget.elevation == 8,
      );
      expect(tester.getSize(menu).height, lessThanOrEqualTo(180));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNWidgets(3));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, 1);
      expect(find.byType(MenuItemButton), findsNothing);
      expect(find.text('Dark'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection fits narrow screen at 200% text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var value = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setState) => AppSelect<int>(
                  label: 'Язык интерфейса',
                  value: value,
                  options: const [
                    AppSelectOption(
                      value: 0,
                      label: 'Как в системе',
                      icon: Icons.language_rounded,
                    ),
                    AppSelectOption(
                      value: 1,
                      label: 'Русский',
                      icon: Icons.language_rounded,
                    ),
                    AppSelectOption(
                      value: 2,
                      label: 'English',
                      icon: Icons.language_rounded,
                    ),
                  ],
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      for (final item in find.byType(MenuItemButton).evaluate()) {
        final rect = tester.getRect(find.byWidget(item.widget));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(value, 1);
      expect(find.text('Русский'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
