import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../presentation/demo_catalog.dart';
import '../../presentation/reference_widgets.dart';
import '../results/results.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({required this.catalog, super.key});
  final DemoCatalog catalog;
  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  int duration = 1, scope = 0;
  bool events = false;
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
              FilledButton(
                onPressed: () => showHistory(context, widget.catalog),
                child: Text('${l.doctorView} →'),
              ),
              const SizedBox(height: 8),
              Text(l.sharingIntro, style: TextStyle(color: p.secondary)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 20,
                children: [
                  Semantics(
                    label: l.shareExample,
                    image: true,
                    child: Image.asset(
                      'assets/demo/share-qr.png',
                      width: 180,
                      height: 180,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.accessDuration,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (var i = 0; i < 3; i++)
                              ChoiceChip(
                                label: Text(
                                  [
                                    l.durationHour,
                                    l.durationDay,
                                    l.durationWeek,
                                  ][i],
                                ),
                                selected: duration == i,
                                onSelected: (_) => setState(() => duration = i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppSelect<int>(
                          label: l.analysisPeriod,
                          value: 0,
                          options: [
                            AppSelectOption(
                              value: 0,
                              label: l.allHistory,
                              icon: Icons.history_rounded,
                            ),
                          ],
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.whatToShow,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (var i = 0; i < 2; i++)
                              ChoiceChip(
                                label: Text(
                                  [l.allSystems, l.selectedSystems][i],
                                ),
                                selected: scope == i,
                                onSelected: (_) => setState(() => scope = i),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l.includeEvents,
                  style: const TextStyle(fontSize: 12),
                ),
                value: events,
                onChanged: (v) => setState(() => events = v ?? false),
              ),
              Text(
                l.sharingDemo,
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.paper,
                  border: Border.all(color: p.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'orange-health.ru/s/7K2-QX9',
                      style: TextStyle(fontSize: 12),
                    ),
                    OutlinedButton(
                      onPressed: () => showUnavailable(context, l.copyLink),
                      child: Text(l.copyLink),
                    ),
                    OutlinedButton(
                      onPressed: () => showUnavailable(context, l.printPdf),
                      child: Text(l.printPdf),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
