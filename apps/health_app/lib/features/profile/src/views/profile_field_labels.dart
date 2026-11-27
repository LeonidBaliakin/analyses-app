import 'package:medical_domain/medical_domain.dart';

import '../../../../l10n/generated/app_localizations.dart';

String profileFieldLabel(AppLocalizations l, ProfileField field) =>
    switch (field) {
      ProfileField.sex => l.profileFieldSex,
      ProfileField.height => l.profileFieldHeight,
      ProfileField.waist => l.profileFieldWaist,
      ProfileField.hips => l.profileFieldHips,
      ProfileField.chest => l.profileFieldChest,
      ProfileField.cycle => l.profileFieldCycle,
      ProfileField.city => l.profileFieldCity,
      ProfileField.travel => l.profileFieldTravel,
      ProfileField.activity => l.profileFieldActivity,
      ProfileField.sport => l.profileFieldSport,
      ProfileField.foodNotes => l.profileFieldFoodNotes,
      ProfileField.stress => l.profileFieldStress,
      ProfileField.sleep => l.profileFieldSleep,
      ProfileField.diet => l.profileFieldDiet,
      ProfileField.smoking => l.profileFieldSmoking,
      ProfileField.packsPerDay => l.profileFieldPacksPerDay,
      ProfileField.smokingQuitPrecision => l.profileFieldSmokingQuitPrecision,
      ProfileField.smokingQuitDate => l.profileFieldSmokingQuitDate,
      ProfileField.smokingQuitYear => l.profileFieldSmokingQuitYear,
      ProfileField.alcohol => l.profileFieldAlcohol,
      ProfileField.alcoholAmount => l.profileFieldAlcoholAmount,
      ProfileField.alcoholQuitPrecision => l.profileFieldAlcoholQuitPrecision,
      ProfileField.alcoholQuitDate => l.profileFieldAlcoholQuitDate,
      ProfileField.alcoholQuitYear => l.profileFieldAlcoholQuitYear,
    };
