import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_terminology/medical_terminology.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'result_coding_view_model.dart';

class ResultCodingFields extends StatelessWidget {
  const ResultCodingFields({
    required this.model,
    required this.onChanged,
    super.key,
  });
  final ResultCodingViewModel model;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final coding = model.coding;
        final matches = model.matches;
        final active = model.catalog.active;
        final savedConcept = model.release.indicator(coding?.indicatorId ?? '');
        final savedUnit = model.release.unit(coding?.unitId ?? '');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.terminologyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l.terminologyHint),
            const SizedBox(height: 12),
            if (coding == null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  model.invalidated
                      ? l.terminologyChanged
                      : switch (matches.status) {
                          MatchStatus.unknown => l.terminologyUnknown,
                          MatchStatus.ambiguous => l.terminologyAmbiguous,
                          MatchStatus.unique => l.terminologySuggestion(
                            active
                                .indicator(matches.conceptIds.single)!
                                .label
                                .inLanguage(language),
                          ),
                        },
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppSelect<String>(
              key: const Key('term-indicator'),
              label: l.terminologyIndicator,
              value: coding?.indicatorId ?? '',
              options: [
                AppSelectOption(value: '', label: l.terminologyUnlinked),
                for (final c in active.indicators)
                  AppSelectOption(
                    value: c.id,
                    label: coding?.indicatorId == c.id
                        ? savedConcept?.label.inLanguage(language) ??
                              c.label.inLanguage(language)
                        : c.label.inLanguage(language),
                  ),
                if (coding != null &&
                    active.indicator(coding.indicatorId) == null)
                  AppSelectOption(
                    value: coding.indicatorId,
                    label:
                        savedConcept?.label.inLanguage(language) ??
                        coding.indicatorId,
                  ),
              ],
              onChanged: model.canSelect
                  ? (id) {
                      model.selectIndicator(id);
                      onChanged();
                    }
                  : null,
            ),
            if (coding != null) ...[
              const SizedBox(height: 16),
              AppSelect<String>(
                key: const Key('term-unit'),
                label: l.terminologyUnit,
                value: coding.unitId ?? '',
                options: [
                  AppSelectOption(value: '', label: l.terminologyUnlinked),
                  for (final u in model.units)
                    AppSelectOption(
                      value: u.id,
                      label: '${u.symbol} · ${u.label.inLanguage(language)}',
                    ),
                  if (coding.unitId != null &&
                      !model.units.any((u) => u.id == coding.unitId))
                    AppSelectOption(
                      value: coding.unitId!,
                      label: savedUnit?.symbol ?? coding.unitId!,
                    ),
                ],
                onChanged:
                    savedConcept == null || coding.sourceUnit.trim().isEmpty
                    ? null
                    : (id) {
                        model.selectUnit(id);
                        onChanged();
                      },
              ),
              const SizedBox(height: 12),
              Text(l.terminologySelected),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
