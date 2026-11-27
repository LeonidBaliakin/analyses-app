import 'package:design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';

class DemoPage extends ReferencePage {
  const DemoPage({required super.children, super.key})
    : super(showDemoNotice: true);
}

class ReferencePage extends StatelessWidget {
  const ReferencePage({
    required this.children,
    this.showDemoNotice = false,
    super.key,
  });
  final List<Widget> children;
  final bool showDemoNotice;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          key: PageStorageKey(runtimeType),
          padding: EdgeInsets.fromLTRB(
            c.maxWidth < 760 ? 12 : 16,
            14,
            c.maxWidth < 760 ? 12 : 16,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDemoNotice) const DemoBanner(),
              if (showDemoNotice &&
                  (children.isEmpty || children.first is! RecordActions))
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
        color: p.accentSoft.withValues(alpha: 0.7),
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
              style: const TextStyle(fontSize: 12, height: 1.7),
            ),
          ),
          const SizedBox(width: 14),
          FilledButton(
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.configuration
                  .findMatch(Uri.parse('/account'))
                  .isError) {
                showUnavailable(context, l.signIn);
              } else {
                context.push('/account');
              }
            },
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
  bool fullscreen = false,
  bool plainHeader = false,
  Widget? titleWidget,
  double maxWidth = 640,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    alignment: MediaQuery.sizeOf(context).width <= 760 && !fullscreen
        ? Alignment.bottomCenter
        : Alignment.center,
    insetPadding: fullscreen || MediaQuery.sizeOf(context).width <= 760
        ? EdgeInsets.zero
        : const EdgeInsets.all(24),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: fullscreen ? MediaQuery.sizeOf(context).width : maxWidth,
        maxHeight: MediaQuery.sizeOf(context).height * (fullscreen ? 1 : .92),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: fullscreen ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: orange
                    ? OrangePalette.orangeGradient
                    : plainHeader
                    ? null
                    : OrangePalette.violetGradient,
                color: orange
                    ? null
                    : plainHeader
                    ? OrangePalette.of(context).card
                    : OrangePalette.of(context).accentSoft,
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                plainHeader ? 9 : 14,
                16,
                plainHeader ? 9 : 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        titleWidget ??
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: plainHeader ? 18 : 16,
                            fontWeight: FontWeight.w800,
                            color: plainHeader ? null : Colors.white,
                          ),
                        ),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context).close,
                    style: IconButton.styleFrom(
                      backgroundColor: plainHeader
                          ? OrangePalette.of(context).accentSoft
                          : Colors.white.withValues(alpha: .18),
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    color: plainHeader
                        ? OrangePalette.of(context).accent
                        : Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: child,
              ),
            ),
          ],
        ),
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
  const RecordActions({this.onAddEvent, this.onDiary, super.key});
  final VoidCallback? onAddEvent, onDiary;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          for (final (index, pair) in [
            (l.addEvent, onAddEvent),
            (l.measurementDiary, onDiary),
          ].indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                ),
                onPressed: pair.$2 ?? () => showUnavailable(context, pair.$1),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: index == 0 ? p.orangeSoft : p.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        index == 0
                            ? Icons.event_note_outlined
                            : Icons.menu_book_outlined,
                        size: 16,
                        color: index == 0 ? const Color(0xFF893900) : p.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pair.$1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: OrangePalette.of(context).ink,
    ),
  );
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
