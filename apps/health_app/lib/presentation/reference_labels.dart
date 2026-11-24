import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

String systemTitle(BuildContext context, int id) {
  final l = AppLocalizations.of(context);
  return [
    l.systemCarbs,
    l.systemBlood,
    l.systemLipids,
    l.systemVitamins,
    l.systemIron,
    l.systemElectro,
    l.systemAllergy,
    l.systemHormones,
    l.systemLiver,
    l.systemKidney,
    l.systemGut,
    l.systemTumor,
    l.systemCoag,
    l.systemInflammation,
    l.systemInfections,
    l.systemUrine,
  ][id];
}

String systemSubtitle(BuildContext context, int id) {
  final l = AppLocalizations.of(context);
  return [
    l.subCarbs,
    l.subBlood,
    l.subLipids,
    l.subVitamins,
    l.subIron,
    l.subElectro,
    l.subAllergy,
    l.subHormones,
    l.subLiver,
    l.subKidney,
    l.subGut,
    l.subTumor,
    l.subCoag,
    l.subInflammation,
    l.subInfections,
    l.subUrine,
  ][id];
}

String sectionTitle(BuildContext context, int id) {
  final l = AppLocalizations.of(context);
  return [
    l.sectionBlood,
    l.sectionMetabolism,
    l.systemHormones,
    l.sectionOrgans,
    l.sectionImmunity,
    l.systemTumor,
  ][id];
}

String profileTitle(BuildContext context, int id) {
  final l = AppLocalizations.of(context);
  return [
    l.profileComplaints,
    l.profileBase,
    l.profileMedicines,
    l.profileWeight,
    l.profileIllness,
    l.profileHospital,
    l.profileAllergies,
    l.profileHistory,
    l.profileLifestyle,
    l.profileDocuments,
  ][id];
}

String profileSubtitle(BuildContext context, int id) {
  final l = AppLocalizations.of(context);
  return [
    l.profileComplaintsSub,
    l.profileBaseSub,
    l.profileMedicinesSub,
    l.profileWeightSub,
    l.profileIllnessSub,
    l.profileHospitalSub,
    l.profileAllergiesSub,
    l.profileHistorySub,
    l.profileLifestyleSub,
    l.profileDocumentsSub,
  ][id];
}
