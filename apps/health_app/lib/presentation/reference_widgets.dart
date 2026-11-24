import 'package:design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          key: PageStorageKey(runtimeType),
          padding: EdgeInsets.fromLTRB(
            c.maxWidth < 600 ? 12 : 24,
            14,
            c.maxWidth < 600 ? 12 : 24,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoBanner(),
              if (children.isEmpty || children.first is! RecordActions)
                const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l.demoTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' ${l.demoIntro}'),
                ],
              ),
              style: const TextStyle(fontSize: 12.5, height: 1.55),
            ),
          ),
          const SizedBox(width: 14),
          FilledButton(
            onPressed: () => showUnavailable(context, l.signIn),
            child: Text(l.signIn),
          ),
        ],
      ),
    );
  }
}

Future<void> showReferenceSheet(
  BuildContext context,
  String title,
  Widget child, {
  bool orange = false,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(14),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 850,
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: orange ? OrangePalette.orangeGradient : null,
              color: orange ? null : OrangePalette.of(context).accentSoft,
            ),
            padding: const EdgeInsets.fromLTRB(16, 5, 4, 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: orange ? Colors.white : null,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).close,
                  icon: const Icon(Icons.close),
                  color: orange ? Colors.white : null,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),
        ],
      ),
    ),
  ),
);

Future<void> showUnavailable(BuildContext context, String title) =>
    showReferenceSheet(
      context,
      title,
      Text(AppLocalizations.of(context).previewOnly),
    );

class RecordActions extends StatelessWidget {
  const RecordActions({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final text in [l.addEvent, l.measurementDiary])
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 32),
                backgroundColor: p.orangeSoft,
                foregroundColor:
                    Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF893900)
                    : const Color(0xFFFFBE88),
                side: const BorderSide(color: Color(0xFFEAB387)),
              ),
              onPressed: () => showUnavailable(context, text),
              child: Text(text),
            ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class OriginalIcon extends StatelessWidget {
  const OriginalIcon(this.name, {this.color, this.size = 22, super.key});
  final String name;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/ui_$name.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}
