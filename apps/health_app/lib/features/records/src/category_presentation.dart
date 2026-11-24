import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';

/// UI-only mapping by stable category, independent of demo array positions.
({String title, IconData icon, Color color}) categoryPresentation(
  BuildContext context,
  AnalysisCategory category,
) {
  final l = AppLocalizations.of(context);
  final (title, icon, color) = switch (category) {
    AnalysisCategory.blood => (
      l.systemBlood,
      Icons.bloodtype_outlined,
      OrangePalette.bloodGroup,
    ),
    AnalysisCategory.iron => (
      l.systemIron,
      Icons.bloodtype_outlined,
      OrangePalette.bloodGroup,
    ),
    AnalysisCategory.coagulation => (
      l.systemCoag,
      Icons.bloodtype_outlined,
      OrangePalette.bloodGroup,
    ),
    AnalysisCategory.carbohydrate => (
      l.systemCarbs,
      Icons.grain,
      OrangePalette.metabolismGroup,
    ),
    AnalysisCategory.lipid => (
      l.systemLipids,
      Icons.water_drop_outlined,
      OrangePalette.metabolismGroup,
    ),
    AnalysisCategory.vitamin => (
      l.systemVitamins,
      Icons.wb_sunny_outlined,
      OrangePalette.metabolismGroup,
    ),
    AnalysisCategory.electrolyte => (
      l.systemElectro,
      Icons.bolt,
      OrangePalette.metabolismGroup,
    ),
    AnalysisCategory.hormone => (
      l.systemHormones,
      Icons.hub_outlined,
      OrangePalette.hormoneGroup,
    ),
    AnalysisCategory.liver => (
      l.systemLiver,
      Icons.monitor_heart_outlined,
      OrangePalette.organGroup,
    ),
    AnalysisCategory.kidney => (
      l.systemKidney,
      Icons.water_drop_outlined,
      OrangePalette.organGroup,
    ),
    AnalysisCategory.gut => (
      l.systemGut,
      Icons.monitor_heart_outlined,
      OrangePalette.organGroup,
    ),
    AnalysisCategory.urine => (
      l.systemUrine,
      Icons.water_drop_outlined,
      OrangePalette.organGroup,
    ),
    AnalysisCategory.allergy => (
      l.systemAllergy,
      Icons.shield_outlined,
      OrangePalette.immunityGroup,
    ),
    AnalysisCategory.inflammation => (
      l.systemInflammation,
      Icons.shield_outlined,
      OrangePalette.immunityGroup,
    ),
    AnalysisCategory.infection => (
      l.systemInfections,
      Icons.shield_outlined,
      OrangePalette.immunityGroup,
    ),
    AnalysisCategory.tumor => (
      l.systemTumor,
      Icons.biotech_outlined,
      OrangePalette.tumorGroup,
    ),
  };
  return (title: title, icon: icon, color: color);
}
