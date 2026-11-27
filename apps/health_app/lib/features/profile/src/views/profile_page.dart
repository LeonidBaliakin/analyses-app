import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:medical_domain/medical_domain.dart';

import '../view_models/profile_editor_view_model.dart';
import '../view_models/profile_overview_state.dart';
import '../view_models/demo_profile.dart';
import 'profile_editor.dart';
import 'profile_preview.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_labels.dart';
import '../../../../presentation/reference_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.catalog,
    this.onAddEvent,
    this.onDiary,
    this.localProfile,
    this.medications = const [],
    this.measurements = const [],
    this.onSaveProfile,
    this.onPreviewSave,
    this.newId,
    this.onMedication,
    this.onWeight,
    this.onDocuments,
    this.extraChildren = const [],
    super.key,
  });
  final DemoCatalog catalog;
  final MedicalProfile? localProfile;
  final List<Widget> extraChildren;
  final List<MedicationCourse> medications;
  final List<HomeMeasurement> measurements;
  final Future<bool> Function(MedicalProfile, String)? onSaveProfile;
  final Future<void> Function()? onPreviewSave;
  final String Function()? newId;
  final VoidCallback? onMedication, onWeight, onDocuments;
  final VoidCallback? onAddEvent, onDiary;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final state = localProfile == null
        ? null
        : ProfileOverviewState(localProfile!, medications, measurements);
    return ReferencePage(
      showDemoNotice: localProfile == null,
      children: [
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(l.profile),
              const SizedBox(height: 5),
              Text(
                l.profileOverview,
                style: TextStyle(
                  color: p.secondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state == null
                    ? l.profileComplete
                    : l.profileFilledPercent(state.completeness),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state == null ? 1 : state.completeness / 100,
                  minHeight: 3,
                  color: p.accent,
                  backgroundColor: p.accentSoft,
                ),
              ),
              QuietFold(
                compact: true,

                title: Text(l.profileHelp),
                children: [Text(l.profileHelpBody)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onDiary,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.accentSoft,
              border: Border.all(color: p.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: p.accent, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.measurementDiary,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l.diaryTileSubtitle,
                        style: TextStyle(fontSize: 11, color: p.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AdaptiveTiles(
          children: [
            for (final i in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
              SpotlightAnchor(
                id: 'profile-$i',
                child: ColorTile(
                  quiet: true,
                  title: profileTitle(context, i),
                  subtitle: profileSubtitle(context, i),
                  icon: SvgPicture.asset(
                    'assets/icons/profile_${['cmp', 'base', 'med', 'weight', 'ill', 'hosp', 'all', 'health', 'life', 'docs'][i]}.svg',
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF56359C),
                      BlendMode.srcIn,
                    ),
                  ),
                  color: const Color(0xFF926DDE),
                  footer: state == null
                      ? _ProfileFooter(raw: catalog.profileCards[i], index: i)
                      : Text(
                          l.profileEntries(state.count(i)),
                          style: TextStyle(fontSize: 11.5, color: p.muted),
                        ),
                  onTap: () => _open(context, i),
                ),
              ),
          ],
        ),
        ...extraChildren,
      ],
    );
  }

  void _open(BuildContext context, int index) {
    final l = AppLocalizations.of(context);
    if (index == 2 && onMedication != null) {
      onMedication!();
      return;
    }
    if (index == 3 && onWeight != null) {
      onWeight!();
      return;
    }
    if (index == 9) {
      if (onDocuments != null) {
        onDocuments!();
      } else {
        showUnavailable(context, l.profileDocuments);
      }
      return;
    }
    if (index == 2 || index == 3) {
      showDemoCourses(
        context,
        catalog,
        weight: index == 3,
        onSaveAttempt: onPreviewSave,
      );
      return;
    }
    var sequence = 0;
    showProfileSectionEditor(
      context,
      title: profileTitle(context, index),
      section: ProfileSection.values[index],
      profile: localProfile ?? demoProfile(catalog),
      newId: newId ?? () => 'preview-${sequence++}',
      save:
          onSaveProfile ??
          (profile, operation) async {
            await onPreviewSave?.call();
            return false;
          },
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
