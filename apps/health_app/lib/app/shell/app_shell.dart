import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/capture/capture.dart';
import '../../features/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../presentation/reference_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.settings,
    this.onAdd,
    this.modeControl,
    this.accountCaption,
    this.onDirectoryOpened,
    super.key,
  });
  final StatefulNavigationShell navigationShell;
  final SettingsViewModel settings;
  final VoidCallback? onAdd;
  final Widget? modeControl, accountCaption;
  final VoidCallback? onDirectoryOpened;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final labels = [
      l.summary,
      l.results,
      l.addAnalysis,
      l.labsNav,
      l.doctorsNav,
    ];
    void select(int i) {
      if (i == 2) {
        if (onAdd != null) {
          onAdd!();
        } else {
          showAddAnalysis(context);
        }
      } else {
        navigationShell.goBranch(i > 2 ? i - 1 : i);
        if (i == 3 || i == 4) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) onDirectoryOpened?.call();
          });
        }
      }
    }

    final current = navigationShell.currentIndex;
    final active = current < 2
        ? current
        : current < 4
        ? current + 1
        : -1;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= AppLayout.railBreakpoint;
        return PopScope(
          canPop: current == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) navigationShell.goBranch(0);
          },
          child: Scaffold(
            extendBody: !wide,
            appBar: AppBar(
              toolbarHeight: scale > 1.4
                  ? 68
                  : wide
                  ? 61
                  : 53,
              automaticallyImplyLeading: false,
              titleSpacing: 12,
              title: Row(
                children: [
                  const OrangeLogo(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                          ),
                        ),
                        if (wide)
                          accountCaption ??
                              Text(
                                l.guestCaption,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: p.muted,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                for (final a in [
                  (5, Icons.qr_code_2, l.sharingAccess),
                  (4, Icons.person_outline, l.profile),
                  (6, Icons.settings_outlined, l.settings),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: current == a.$1
                            ? OrangePalette.orange
                            : p.card,
                        foregroundColor: current == a.$1
                            ? Colors.white
                            : p.secondary,
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(38, 38),
                        padding: const EdgeInsets.all(8),
                      ),
                      tooltip: a.$3,
                      onPressed: () => navigationShell.goBranch(a.$1),
                      icon: OriginalIcon(
                        a.$1 == 5
                            ? 'share'
                            : a.$1 == 4
                            ? 'person'
                            : 'gear',
                        size: 21,
                        color: current == a.$1 ? Colors.white : p.secondary,
                      ),
                    ),
                  ),
                const SizedBox(width: 5),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: ColoredBox(
                  color: p.line,
                  child: const SizedBox(height: 1),
                ),
              ),
            ),
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1, -1),
                  radius: 1.4,
                  colors: [
                    Color.lerp(
                      p.paper,
                      p.accent,
                      Theme.of(context).brightness == Brightness.light
                          ? 0.035
                          : 0.06,
                    )!,
                    p.paper,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: wide,
                child: Column(
                  children: [
                    ?modeControl,
                    ListenableBuilder(
                      listenable: settings,
                      builder: (context, _) =>
                          settings.error == SettingsError.load
                          ? MaterialBanner(
                              content: Text(l.preferencesLoadError),
                              actions: [
                                TextButton(
                                  onPressed: () => navigationShell.goBranch(6),
                                  child: Text(l.settings),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: navigationShell),
                          if (wide)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  18,
                                  16,
                                  18,
                                ),
                                child: Container(
                                  key: const Key('desktop-navigation'),
                                  width: 92,
                                  decoration: BoxDecoration(
                                    color: p.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: p.line),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (var i = 0; i < labels.length; i++)
                                          _NavButton(
                                            label: labels[i],
                                            index: i,
                                            selected: i == active,
                                            onTap: () => select(i),
                                            rail: true,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: wide
                ? null
                : SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: SizedBox(
                      key: const Key('bottom-navigation'),
                      height: scale > 1.4 ? 104 : 86,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            height: scale > 1.4 ? 88 : 70,
                            decoration: BoxDecoration(
                              color: p.paper,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: p.card),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3C2878)
                                      .withValues(alpha: .12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < labels.length; i++)
                                Expanded(
                                  child: i == 2
                                      ? SizedBox(
                                          height: scale > 1.4 ? 104 : 86,
                                          child: Column(
                                            children: [
                                              Semantics(
                                                button: true,
                                                label: l.addAnalysis,
                                                child: InkWell(
                                                  key: const Key(
                                                    'add-analysis',
                                                  ),
                                                  onTap: () => select(2),
                                                  customBorder:
                                                      const CircleBorder(),
                                                  child: Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      gradient: OrangePalette
                                                          .orangeGradient,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 4,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: OrangePalette
                                                              .orange
                                                              .withValues(
                                                                alpha: .3,
                                                              ),
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                            0,
                                                            5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 25,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Flexible(
                                                child: Text(
                                                  l.addAnalysis.replaceFirst(
                                                    ' ',
                                                    '\n',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFFE8590C),
                                                    fontSize: 9.5,
                                                    height: 1.15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _NavButton(
                                          label: labels[i],
                                          index: i,
                                          selected: i == active,
                                          onTap: () => select(i),
                                        ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    this.rail = false,
  });
  final String label;
  final int index;
  final bool selected, rail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context),
        scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('nav-$index'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                height: rail
                    ? scale > 1.4
                          ? 100
                          : 58
                    : scale > 1.4
                    ? 76
                    : 56,
                decoration: BoxDecoration(
                  gradient: selected ? OrangePalette.orangeGradient : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: OrangePalette.orange.withValues(alpha: .27),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: OriginalIcon(
                          ['summary', 'files', 'add', 'book', 'docs'][index],
                          color: selected ? Colors.white : p.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: rail ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: rail ? 10.5 : 10,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: selected ? Colors.white : p.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
