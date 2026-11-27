import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_labels.dart';
import '../../../../presentation/reference_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.catalog,
    this.onAddEvent,
    this.onDiary,
    super.key,
  });
  final DemoCatalog catalog;
  final VoidCallback? onAddEvent, onDiary;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return DemoPage(
      children: [
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(l.profile),
              const SizedBox(height: 5),
              Text(l.profileOverview, style: TextStyle(color: p.secondary)),
              const SizedBox(height: 16),
              Text(
                l.profileComplete,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 1,
                  minHeight: 8,
                  color: p.accent,
                  backgroundColor: p.accentSoft,
                ),
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l.profileHelp),
                children: [Text(l.profileHelpBody)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RecordActions(onAddEvent: onAddEvent, onDiary: onDiary),
        AdaptiveTiles(
          children: [
            for (final i in [1, 0, 2, 3, 4, 5, 6, 7, 8, 9])
              ColorTile(
                title: profileTitle(context, i),
                subtitle: profileSubtitle(context, i),
                icon: SvgPicture.asset(
                  'assets/icons/profile_${['cmp', 'base', 'med', 'weight', 'ill', 'hosp', 'all', 'health', 'life', 'docs'][i]}.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                color: const Color(0xFF926DDE),
                footer: _ProfileFooter(raw: catalog.profileCards[i], index: i),
                onTap: () => _open(context, i),
              ),
          ],
        ),
      ],
    );
  }

  void _open(BuildContext context, int index) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final key = [
      'cmp',
      'base',
      'med',
      'weight',
      'ill',
      'hosp',
      'all',
      'health',
      'life',
      'docs',
    ][index];
    final value = catalog.events[key];
    final rows = value is List<dynamic>
        ? value.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    showReferenceSheet(
      context,
      profileTitle(context, index),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profileSubtitle(context, index),
            style: TextStyle(color: p.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (index == 1)
            for (final entry in [
              (l.nameLabel, catalog.profile['name']),
              (l.birthDate, catalog.profile['dob']),
              (l.heightLabel, catalog.profile['h']),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('${entry.$1}: ${entry.$2}'),
              ),
          if (index == 7)
            for (final key in ['dx', 'surg', 'fam', 'other'])
              if ('${catalog.profile[key] ?? ''}'.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('${catalog.profile[key]}'),
                ),
          if (index == 8)
            for (final key in ['city', 'act', 'sleep', 'food', 'smoke', 'alc'])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('${catalog.profile[key] ?? '—'}'),
              ),
          for (final row in rows)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: p.paper,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                row.values.where((v) => v is String || v is num).join(' · '),
              ),
            ),
          if (index == 6)
            for (final row in (catalog.profile['alls'] as List<dynamic>))
              Text((row as Map<String, dynamic>).values.join(' · ')),
          const SizedBox(height: 18),
          Text(l.demoAccount, style: TextStyle(fontSize: 12, color: p.muted)),
        ],
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({required this.raw, required this.index});
  final String raw;
  final int index;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = OrangePalette.of(context),
        lines = raw.split('\n');
    final label = lines.last == 'заполнено'
        ? l.filled
        : lines.last == 'скоро'
        ? l.comingSoon
        : lines.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lines.length > 2 ? lines[2] : '',
          style: TextStyle(fontSize: 11.5, color: p.muted),
        ),
        const SizedBox(height: 7),
        StatusPill(
          label: label,
          color: index == 9
              ? p.muted
              : index == 3
              ? const Color(0xFFC65B17)
              : p.green,
          background: index == 9
              ? p.paper
              : index == 3
              ? p.orangeSoft
              : p.greenSoft,
        ),
      ],
    );
  }
}
