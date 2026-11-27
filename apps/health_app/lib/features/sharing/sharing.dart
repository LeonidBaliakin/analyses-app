import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../presentation/demo_catalog.dart';
import '../../presentation/reference_labels.dart';
import '../../presentation/reference_widgets.dart';
import 'src/sharing_view_model.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({required this.catalog, this.onOpenSettings, super.key});
  final DemoCatalog catalog;
  final VoidCallback? onOpenSettings;
  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  final model = SharingViewModel();
  final start = TextEditingController(), end = TextEditingController();
  @override
  void dispose() {
    model.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => DemoPage(
        children: [
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(l.sharingTitle),
                const SizedBox(height: 3),
                Text(
                  l.sharingIntro,
                  style: TextStyle(
                    color: p.secondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                SpotlightAnchor(
                  id: 'share-access',
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: p.paper,
                      border: Border.all(color: p.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          label: l.shareExample,
                          image: true,
                          child: Image.asset(
                            'assets/demo/share-qr.png',
                            width: (MediaQuery.sizeOf(context).width * .34)
                                .clamp(130, 152),
                            height: (MediaQuery.sizeOf(context).width * .34)
                                .clamp(130, 152),
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SelectableText(
                                'orange-health.ru/s/7K2-QX9',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
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
                                      ).showSnackBar(
                                        SnackBar(content: Text(l.linkCopied)),
                                      );
                                    }
                                  } on Exception {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(l.copyFailed)),
                                      );
                                    }
                                  }
                                },
                                child: Text(l.copyLink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  l.accessDuration,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < 3; i++)
                      OptionChip(
                        softSelection: true,
                        label: Text(
                          [l.durationDay, l.durationWeek, l.durationMonth][i],
                        ),
                        selected: model.duration == i,
                        onSelected: (_) => model.selectDuration(i),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                QuietFold(
                  key: const PageStorageKey('share-options'),

                  title: Text(l.sharingOptions),
                  children: [
                    AppSelect<int>(
                      label: l.analysisPeriod,
                      value: model.period,
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
                      onChanged: model.selectPeriod,
                    ),
                    if (model.period == 3)
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
                          for (var i = 0; i < 3; i++)
                            OptionChip(
                              softSelection: true,
                              label: Text(
                                [
                                  l.allResults,
                                  l.onlyOutsideRange,
                                  l.selectedBlocks,
                                ][i],
                              ),
                              selected: model.scope == i,
                              onSelected: (_) => model.selectScope(i),
                            ),
                        ],
                      ),
                    ),
                    if (model.scope == 2)
                      for (var i = 0; i < widget.catalog.sections.length; i++)
                        CheckboxListTile(
                          title: Text(sectionTitle(context, i)),
                          value: model.groups.contains(i),
                          onChanged: (_) => model.selectGroup(i),
                        ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.includeEvents),
                      value: model.events,
                      onChanged: (value) => model.includeEvents(value ?? false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.sharingDemo,
                  style: TextStyle(fontSize: 12, color: p.secondary),
                ),
              ],
            ),
          ),
          if (widget.onOpenSettings != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onOpenSettings,
                child: Text(
                  l.manageSharing,
                  style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
