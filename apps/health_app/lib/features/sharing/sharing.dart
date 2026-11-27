import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../presentation/demo_catalog.dart';
import '../../presentation/reference_labels.dart';
import '../../presentation/reference_widgets.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({required this.catalog, this.onOpenSettings, super.key});
  final DemoCatalog catalog;
  final VoidCallback? onOpenSettings;
  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  int duration = 1, scope = 0, period = 0;
  bool events = false;
  final groups = <int>{};
  final start = TextEditingController(), end = TextEditingController();
  @override
  void dispose() {
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return DemoPage(
      children: [
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(l.sharingTitle),
              const SizedBox(height: 8),
              Text(l.sharingIntro, style: TextStyle(color: p.secondary)),
              const SizedBox(height: 20),
              Center(
                child: Semantics(
                  label: l.shareExample,
                  image: true,
                  child: Image.asset(
                    'assets/demo/share-qr.png',
                    width: 180,
                    height: 180,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SelectableText('orange-health.ru/s/7K2-QX9'),
                  FilledButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(l.copyLink),
                    onPressed: () async {
                      try {
                        await Clipboard.setData(
                          const ClipboardData(
                            text: 'https://orange-health.ru/s/7K2-QX9',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(l.linkCopied)));
                        }
                      } on Exception {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(l.copyFailed)));
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l.accessDuration,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < 3; i++)
                    ChoiceChip(
                      label: Text(
                        [l.durationHour, l.durationDay, l.durationWeek][i],
                      ),
                      selected: duration == i,
                      onSelected: (_) => setState(() => duration = i),
                    ),
                ],
              ),
              ExpansionTile(
                key: const PageStorageKey('share-options'),
                tilePadding: EdgeInsets.zero,
                title: Text(l.sharingOptions),
                children: [
                  AppSelect<int>(
                    label: l.analysisPeriod,
                    value: period,
                    options: [
                      for (var i = 0; i < 4; i++)
                        AppSelectOption(
                          value: i,
                          label: [
                            l.historyAll,
                            l.history30Days,
                            l.history180Days,
                            l.historyCustom,
                          ][i],
                        ),
                    ],
                    onChanged: (value) => setState(() => period = value),
                  ),
                  if (period == 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: start,
                              decoration: InputDecoration(
                                labelText: l.reportFrom,
                                hintText: 'YYYY-MM-DD',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: end,
                              decoration: InputDecoration(
                                labelText: l.reportTo,
                                hintText: 'YYYY-MM-DD',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < 2; i++)
                          ChoiceChip(
                            label: Text([l.allSystems, l.selectedSystems][i]),
                            selected: scope == i,
                            onSelected: (_) => setState(() => scope = i),
                          ),
                      ],
                    ),
                  ),
                  if (scope == 1)
                    for (var i = 0; i < widget.catalog.sections.length; i++)
                      CheckboxListTile(
                        title: Text(sectionTitle(context, i)),
                        value: groups.contains(i),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            groups.add(i);
                          } else {
                            groups.remove(i);
                          }
                        }),
                      ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.includeEvents),
                    value: events,
                    onChanged: (value) =>
                        setState(() => events = value ?? false),
                  ),
                ],
              ),
              Text(
                l.sharingDemo,
                style: TextStyle(fontSize: 12, color: p.secondary),
              ),
            ],
          ),
        ),
        if (widget.onOpenSettings != null)
          TextButton(
            onPressed: widget.onOpenSettings,
            child: Text(l.manageSharing),
          ),
      ],
    );
  }
}
