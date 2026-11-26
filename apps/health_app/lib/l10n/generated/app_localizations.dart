// Flutter 3.50 gen_l10n still emits deprecated compatibility delegates.
// Keep this exception limited to SDK-generated localization code.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Orange of Health'**
  String get appTitle;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @summaryIntro.
  ///
  /// In en, this message translates to:
  /// **'Your results and health history in one place.'**
  String get summaryIntro;

  /// No description provided for @summaryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your health history starts here'**
  String get summaryEmptyTitle;

  /// No description provided for @summaryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No results have been saved yet. Changes in your results and the context of each test will appear here.'**
  String get summaryEmptyMessage;

  /// No description provided for @openResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get openResults;

  /// No description provided for @resultsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get resultsEmptyTitle;

  /// No description provided for @resultsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your results and trends will appear here. Adding and saving results will be available in a future update.'**
  String get resultsEmptyMessage;

  /// No description provided for @documentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get documentsEmptyTitle;

  /// No description provided for @documentsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Original lab reports and discharge summaries will appear here. Document import is not available yet.'**
  String get documentsEmptyMessage;

  /// No description provided for @profileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is empty'**
  String get profileEmptyTitle;

  /// No description provided for @profileEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'A health profile will bring together one person’s results, events, medications and home measurements. Editing will be available in a future update.'**
  String get profileEmptyMessage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Language and appearance'**
  String get appearance;

  /// No description provided for @preferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'These preferences are saved on this device and work offline.'**
  String get preferencesDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get systemLanguage;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @savingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Saving preferences'**
  String get savingPreferences;

  /// No description provided for @preferencesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load preferences. Device defaults are in use. Please try again.'**
  String get preferencesLoadError;

  /// No description provided for @preferencesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your choice. Please select the value again.'**
  String get preferencesSaveError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @returnToSummary.
  ///
  /// In en, this message translates to:
  /// **'Go to summary'**
  String get returnToSummary;

  /// No description provided for @demoTitle.
  ///
  /// In en, this message translates to:
  /// **'You are viewing demo data.'**
  String get demoTitle;

  /// No description provided for @demoIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to upload your results and save changes.'**
  String get demoIntro;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @previewOnly.
  ///
  /// In en, this message translates to:
  /// **'This is an interface preview. Sign-in, medical record storage and external services are not connected yet.'**
  String get previewOnly;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @patientOffice.
  ///
  /// In en, this message translates to:
  /// **'Patient account'**
  String get patientOffice;

  /// No description provided for @addAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Add results'**
  String get addAnalysis;

  /// No description provided for @labsNav.
  ///
  /// In en, this message translates to:
  /// **'Find a lab'**
  String get labsNav;

  /// No description provided for @doctorsNav.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctorsNav;

  /// No description provided for @showDoctor.
  ///
  /// In en, this message translates to:
  /// **'Show a doctor'**
  String get showDoctor;

  /// No description provided for @latestVisit.
  ///
  /// In en, this message translates to:
  /// **'Latest tests'**
  String get latestVisit;

  /// No description provided for @visitCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare with {date}'**
  String visitCompare(String date);

  /// No description provided for @inRange.
  ///
  /// In en, this message translates to:
  /// **'In range'**
  String get inRange;

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get outOfRange;

  /// No description provided for @notRecently.
  ///
  /// In en, this message translates to:
  /// **'Not tested recently'**
  String get notRecently;

  /// No description provided for @allResults.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get allResults;

  /// No description provided for @visitEvents.
  ///
  /// In en, this message translates to:
  /// **'Events around testing'**
  String get visitEvents;

  /// No description provided for @eventCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String eventCount(int count);

  /// No description provided for @moreEvents.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreEvents;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add an event'**
  String get addEvent;

  /// No description provided for @measurementDiary.
  ///
  /// In en, this message translates to:
  /// **'Measurement diary'**
  String get measurementDiary;

  /// No description provided for @systemsHeading.
  ///
  /// In en, this message translates to:
  /// **'Results by body system'**
  String get systemsHeading;

  /// No description provided for @systemSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a result or body system'**
  String get systemSearch;

  /// No description provided for @shownSystems.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total} systems'**
  String shownSystems(int count, int total);

  /// No description provided for @chooseSystems.
  ///
  /// In en, this message translates to:
  /// **'Choose systems'**
  String get chooseSystems;

  /// No description provided for @showHints.
  ///
  /// In en, this message translates to:
  /// **'View tips'**
  String get showHints;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No results found. Check the spelling or search by body system.'**
  String get noMatches;

  /// No description provided for @sectionBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood'**
  String get sectionBlood;

  /// No description provided for @sectionMetabolism.
  ///
  /// In en, this message translates to:
  /// **'Metabolism'**
  String get sectionMetabolism;

  /// No description provided for @sectionOrgans.
  ///
  /// In en, this message translates to:
  /// **'Organs'**
  String get sectionOrgans;

  /// No description provided for @sectionImmunity.
  ///
  /// In en, this message translates to:
  /// **'Immunity and infections'**
  String get sectionImmunity;

  /// No description provided for @systemCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate metabolism'**
  String get systemCarbs;

  /// No description provided for @systemBlood.
  ///
  /// In en, this message translates to:
  /// **'Complete blood count'**
  String get systemBlood;

  /// No description provided for @systemLipids.
  ///
  /// In en, this message translates to:
  /// **'Lipid profile'**
  String get systemLipids;

  /// No description provided for @systemVitamins.
  ///
  /// In en, this message translates to:
  /// **'Vitamins'**
  String get systemVitamins;

  /// No description provided for @systemIron.
  ///
  /// In en, this message translates to:
  /// **'Iron metabolism'**
  String get systemIron;

  /// No description provided for @systemElectro.
  ///
  /// In en, this message translates to:
  /// **'Electrolytes and minerals'**
  String get systemElectro;

  /// No description provided for @systemAllergy.
  ///
  /// In en, this message translates to:
  /// **'Allergy profile'**
  String get systemAllergy;

  /// No description provided for @systemHormones.
  ///
  /// In en, this message translates to:
  /// **'Hormones'**
  String get systemHormones;

  /// No description provided for @systemLiver.
  ///
  /// In en, this message translates to:
  /// **'Liver and protein metabolism'**
  String get systemLiver;

  /// No description provided for @systemKidney.
  ///
  /// In en, this message translates to:
  /// **'Kidneys and purine metabolism'**
  String get systemKidney;

  /// No description provided for @systemGut.
  ///
  /// In en, this message translates to:
  /// **'Digestive system and infections'**
  String get systemGut;

  /// No description provided for @systemTumor.
  ///
  /// In en, this message translates to:
  /// **'Tumor markers'**
  String get systemTumor;

  /// No description provided for @systemCoag.
  ///
  /// In en, this message translates to:
  /// **'Coagulation tests'**
  String get systemCoag;

  /// No description provided for @systemInflammation.
  ///
  /// In en, this message translates to:
  /// **'Inflammation'**
  String get systemInflammation;

  /// No description provided for @systemInfections.
  ///
  /// In en, this message translates to:
  /// **'Infections'**
  String get systemInfections;

  /// No description provided for @systemUrine.
  ///
  /// In en, this message translates to:
  /// **'Urinalysis'**
  String get systemUrine;

  /// No description provided for @subCarbs.
  ///
  /// In en, this message translates to:
  /// **'Glucose, HbA1c, insulin'**
  String get subCarbs;

  /// No description provided for @subBlood.
  ///
  /// In en, this message translates to:
  /// **'Red cells, white cells, platelets'**
  String get subBlood;

  /// No description provided for @subLipids.
  ///
  /// In en, this message translates to:
  /// **'Cholesterol fractions, triglycerides'**
  String get subLipids;

  /// No description provided for @subVitamins.
  ///
  /// In en, this message translates to:
  /// **'D, B12, folic acid'**
  String get subVitamins;

  /// No description provided for @subIron.
  ///
  /// In en, this message translates to:
  /// **'Serum iron, ferritin'**
  String get subIron;

  /// No description provided for @subElectro.
  ///
  /// In en, this message translates to:
  /// **'Potassium, sodium, chloride, magnesium'**
  String get subElectro;

  /// No description provided for @subAllergy.
  ///
  /// In en, this message translates to:
  /// **'Total and specific IgE, IgG'**
  String get subAllergy;

  /// No description provided for @subHormones.
  ///
  /// In en, this message translates to:
  /// **'Thyroid hormones, testosterone'**
  String get subHormones;

  /// No description provided for @subLiver.
  ///
  /// In en, this message translates to:
  /// **'Liver enzymes, bilirubin, protein'**
  String get subLiver;

  /// No description provided for @subKidney.
  ///
  /// In en, this message translates to:
  /// **'Creatinine, urea, uric acid'**
  String get subKidney;

  /// No description provided for @subGut.
  ///
  /// In en, this message translates to:
  /// **'Helicobacter pylori'**
  String get subGut;

  /// No description provided for @subTumor.
  ///
  /// In en, this message translates to:
  /// **'PSA, CEA, CA 19-9 and others'**
  String get subTumor;

  /// No description provided for @subCoag.
  ///
  /// In en, this message translates to:
  /// **'INR, aPTT, fibrinogen, D-dimer'**
  String get subCoag;

  /// No description provided for @subInflammation.
  ///
  /// In en, this message translates to:
  /// **'CRP, ESR, rheumatology tests'**
  String get subInflammation;

  /// No description provided for @subInfections.
  ///
  /// In en, this message translates to:
  /// **'HIV, syphilis, hepatitis B and C'**
  String get subInfections;

  /// No description provided for @subUrine.
  ///
  /// In en, this message translates to:
  /// **'Specific gravity, protein, white cells'**
  String get subUrine;

  /// No description provided for @withData.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} with data'**
  String withData(int count, int total);

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultCount(int count);

  /// No description provided for @abnormalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} out of range'**
  String abnormalCount(int count);

  /// No description provided for @allNormal.
  ///
  /// In en, this message translates to:
  /// **'all in range'**
  String get allNormal;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get noData;

  /// No description provided for @notUploaded.
  ///
  /// In en, this message translates to:
  /// **'not uploaded yet'**
  String get notUploaded;

  /// No description provided for @noSystemData.
  ///
  /// In en, this message translates to:
  /// **'The uploaded reports contain no results for this system.'**
  String get noSystemData;

  /// No description provided for @fullHistory.
  ///
  /// In en, this message translates to:
  /// **'Complete result history'**
  String get fullHistory;

  /// No description provided for @historySub.
  ///
  /// In en, this message translates to:
  /// **'9 visits · 59 results'**
  String get historySub;

  /// No description provided for @openTable.
  ///
  /// In en, this message translates to:
  /// **'Open table'**
  String get openTable;

  /// No description provided for @sourceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The service displays values, units and laboratory reference ranges from reports. It does not diagnose or recommend treatment. Your doctor interprets the results.'**
  String get sourceDisclaimer;

  /// No description provided for @indicator.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get indicator;

  /// No description provided for @latestValue.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestValue;

  /// No description provided for @labReference.
  ///
  /// In en, this message translates to:
  /// **'Lab reference'**
  String get labReference;

  /// No description provided for @previousValue.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousValue;

  /// No description provided for @aboveRange.
  ///
  /// In en, this message translates to:
  /// **'above range'**
  String get aboveRange;

  /// No description provided for @belowRange.
  ///
  /// In en, this message translates to:
  /// **'below range'**
  String get belowRange;

  /// No description provided for @resultHistory.
  ///
  /// In en, this message translates to:
  /// **'Result history'**
  String get resultHistory;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @valueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// No description provided for @originalName.
  ///
  /// In en, this message translates to:
  /// **'Original report name'**
  String get originalName;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload test reports'**
  String get uploadTitle;

  /// No description provided for @uploadIntro.
  ///
  /// In en, this message translates to:
  /// **'Add a report from any laboratory. Review extracted results before saving. The original document stays with the results.'**
  String get uploadIntro;

  /// No description provided for @uploadDrop.
  ///
  /// In en, this message translates to:
  /// **'A photo, a screenshot from your lab app, or a PDF from email.'**
  String get uploadDrop;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get fromGallery;

  /// No description provided for @filePdf.
  ///
  /// In en, this message translates to:
  /// **'File or PDF'**
  String get filePdf;

  /// No description provided for @uploadPermission.
  ///
  /// In en, this message translates to:
  /// **'The app will ask for access to your camera, gallery or files when import is available.'**
  String get uploadPermission;

  /// No description provided for @photoScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Photo or screenshot'**
  String get photoScreenshot;

  /// No description provided for @photoAdvice.
  ///
  /// In en, this message translates to:
  /// **'Capture the full report, including its date and reference ranges.'**
  String get photoAdvice;

  /// No description provided for @pdfAdvice.
  ///
  /// In en, this message translates to:
  /// **'A file from your laboratory app or account.'**
  String get pdfAdvice;

  /// No description provided for @forwardMail.
  ///
  /// In en, this message translates to:
  /// **'Forward an email'**
  String get forwardMail;

  /// No description provided for @mailAdvice.
  ///
  /// In en, this message translates to:
  /// **'Forward a laboratory email to'**
  String get mailAdvice;

  /// No description provided for @demoEmail.
  ///
  /// In en, this message translates to:
  /// **'Example address'**
  String get demoEmail;

  /// No description provided for @labLabel.
  ///
  /// In en, this message translates to:
  /// **'Laboratory'**
  String get labLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileLabel;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get verified;

  /// No description provided for @openReport.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get openReport;

  /// No description provided for @testReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for testing'**
  String get testReason;

  /// No description provided for @profileIntro.
  ///
  /// In en, this message translates to:
  /// **'Information that helps your doctor interpret tests. Medications, weight and illnesses appear alongside results by date. The service does not assess your profile.'**
  String get profileIntro;

  /// No description provided for @profileComplete.
  ///
  /// In en, this message translates to:
  /// **'Profile 100% complete'**
  String get profileComplete;

  /// No description provided for @profileCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'All filled in. Update your weight and medications when something changes.'**
  String get profileCompleteHint;

  /// No description provided for @profileComplaints.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get profileComplaints;

  /// No description provided for @profileBase.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get profileBase;

  /// No description provided for @profileMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medications and supplements'**
  String get profileMedicines;

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileWeight;

  /// No description provided for @profileIllness.
  ///
  /// In en, this message translates to:
  /// **'Illnesses'**
  String get profileIllness;

  /// No description provided for @profileHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital stays'**
  String get profileHospital;

  /// No description provided for @profileAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get profileAllergies;

  /// No description provided for @profileHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical history'**
  String get profileHistory;

  /// No description provided for @profileLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get profileLifestyle;

  /// No description provided for @profileDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents and imaging'**
  String get profileDocuments;

  /// No description provided for @profileComplaintsSub.
  ///
  /// In en, this message translates to:
  /// **'What bothers you and since when'**
  String get profileComplaintsSub;

  /// No description provided for @profileBaseSub.
  ///
  /// In en, this message translates to:
  /// **'Sex, age, height'**
  String get profileBaseSub;

  /// No description provided for @profileMedicinesSub.
  ///
  /// In en, this message translates to:
  /// **'Courses and ongoing use'**
  String get profileMedicinesSub;

  /// No description provided for @profileWeightSub.
  ///
  /// In en, this message translates to:
  /// **'Weight history'**
  String get profileWeightSub;

  /// No description provided for @profileIllnessSub.
  ///
  /// In en, this message translates to:
  /// **'Recent illnesses, fever, antibiotics'**
  String get profileIllnessSub;

  /// No description provided for @profileHospitalSub.
  ///
  /// In en, this message translates to:
  /// **'When and where you stayed in hospital'**
  String get profileHospitalSub;

  /// No description provided for @profileAllergiesSub.
  ///
  /// In en, this message translates to:
  /// **'Triggers and reactions'**
  String get profileAllergiesSub;

  /// No description provided for @profileHistorySub.
  ///
  /// In en, this message translates to:
  /// **'Conditions, operations, injuries, family history'**
  String get profileHistorySub;

  /// No description provided for @profileLifestyleSub.
  ///
  /// In en, this message translates to:
  /// **'Activity, sleep, diet, alcohol'**
  String get profileLifestyleSub;

  /// No description provided for @profileDocumentsSub.
  ///
  /// In en, this message translates to:
  /// **'ECG, ultrasound, X-rays, CT, MRI'**
  String get profileDocumentsSub;

  /// No description provided for @filled.
  ///
  /// In en, this message translates to:
  /// **'filled in'**
  String get filled;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'coming soon'**
  String get comingSoon;

  /// No description provided for @addPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph a report'**
  String get addPhotoTitle;

  /// No description provided for @addGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo or screenshot from gallery'**
  String get addGalleryTitle;

  /// No description provided for @addFilesHint.
  ///
  /// In en, this message translates to:
  /// **'From email or your laboratory account'**
  String get addFilesHint;

  /// No description provided for @addGalleryHint.
  ///
  /// In en, this message translates to:
  /// **'For example, a screenshot from your lab app'**
  String get addGalleryHint;

  /// No description provided for @addMailTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward a laboratory email'**
  String get addMailTitle;

  /// No description provided for @labsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a laboratory'**
  String get labsTitle;

  /// No description provided for @locationExample.
  ///
  /// In en, this message translates to:
  /// **'Saint Petersburg, Nevsky Prospekt 28'**
  String get locationExample;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @labSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a test: ferritin, complete blood count…'**
  String get labSearch;

  /// No description provided for @basicSet.
  ///
  /// In en, this message translates to:
  /// **'+ Basic set'**
  String get basicSet;

  /// No description provided for @basicSetHint.
  ///
  /// In en, this message translates to:
  /// **'Blood count, chemistry, urinalysis, glucose, vitamin D'**
  String get basicSetHint;

  /// No description provided for @testList.
  ///
  /// In en, this message translates to:
  /// **'My test list'**
  String get testList;

  /// No description provided for @nearbyLabs.
  ///
  /// In en, this message translates to:
  /// **'Nearby laboratories'**
  String get nearbyLabs;

  /// No description provided for @nearbyDoctors.
  ///
  /// In en, this message translates to:
  /// **'Nearby doctors'**
  String get nearbyDoctors;

  /// No description provided for @selectedSpecialists.
  ///
  /// In en, this message translates to:
  /// **'Selected specialties'**
  String get selectedSpecialists;

  /// No description provided for @specialistSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a specialty: primary care, endocrinology…'**
  String get specialistSearch;

  /// No description provided for @demoDirectory.
  ///
  /// In en, this message translates to:
  /// **'Demo: laboratories, doctors and prices are illustrative. Booking is not connected.'**
  String get demoDirectory;

  /// No description provided for @bookWebsite.
  ///
  /// In en, this message translates to:
  /// **'Book on website'**
  String get bookWebsite;

  /// No description provided for @bestChoice.
  ///
  /// In en, this message translates to:
  /// **'Best option'**
  String get bestChoice;

  /// No description provided for @lowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get lowestPrice;

  /// No description provided for @nearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearest;

  /// No description provided for @whatTests.
  ///
  /// In en, this message translates to:
  /// **'Which results to bring →'**
  String get whatTests;

  /// No description provided for @sharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Share results with a doctor'**
  String get sharingTitle;

  /// No description provided for @doctorView.
  ///
  /// In en, this message translates to:
  /// **'Open doctor view'**
  String get doctorView;

  /// No description provided for @sharingIntro.
  ///
  /// In en, this message translates to:
  /// **'For one-time access a doctor scans a QR code or opens a link. Permanent access uses a registered account. You can revoke access at any time.'**
  String get sharingIntro;

  /// No description provided for @sharingDemo.
  ///
  /// In en, this message translates to:
  /// **'The link and QR code are illustrative. They do not grant access to health records.'**
  String get sharingDemo;

  /// No description provided for @accessDuration.
  ///
  /// In en, this message translates to:
  /// **'Access duration'**
  String get accessDuration;

  /// No description provided for @durationHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get durationHour;

  /// No description provided for @durationDay.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get durationDay;

  /// No description provided for @durationWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get durationWeek;

  /// No description provided for @analysisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Result period'**
  String get analysisPeriod;

  /// No description provided for @allHistory.
  ///
  /// In en, this message translates to:
  /// **'All history'**
  String get allHistory;

  /// No description provided for @whatToShow.
  ///
  /// In en, this message translates to:
  /// **'What to show'**
  String get whatToShow;

  /// No description provided for @allSystems.
  ///
  /// In en, this message translates to:
  /// **'All systems'**
  String get allSystems;

  /// No description provided for @selectedSystems.
  ///
  /// In en, this message translates to:
  /// **'Selected systems'**
  String get selectedSystems;

  /// No description provided for @includeEvents.
  ///
  /// In en, this message translates to:
  /// **'Include events and measurements for the selected period'**
  String get includeEvents;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @printPdf.
  ///
  /// In en, this message translates to:
  /// **'Printable PDF'**
  String get printPdf;

  /// No description provided for @shareExample.
  ///
  /// In en, this message translates to:
  /// **'Example QR code'**
  String get shareExample;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @accessToMine.
  ///
  /// In en, this message translates to:
  /// **'Who can access my results'**
  String get accessToMine;

  /// No description provided for @sharedWithMe.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get sharedWithMe;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appPermissions.
  ///
  /// In en, this message translates to:
  /// **'App permissions'**
  String get appPermissions;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportHint.
  ///
  /// In en, this message translates to:
  /// **'Something not working, or have an idea? Let us know.'**
  String get supportHint;

  /// No description provided for @supportSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubject;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supportMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @appIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get appIntroduction;

  /// No description provided for @restartTour.
  ///
  /// In en, this message translates to:
  /// **'Start the introduction again'**
  String get restartTour;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @demoAccount.
  ///
  /// In en, this message translates to:
  /// **'Example profile. No account is connected.'**
  String get demoAccount;

  /// No description provided for @noSharedAccess.
  ///
  /// In en, this message translates to:
  /// **'Shared access will appear here when accounts are available.'**
  String get noSharedAccess;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @localTitle.
  ///
  /// In en, this message translates to:
  /// **'My records'**
  String get localTitle;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Cloud sync is not connected yet.'**
  String get localOnly;

  /// No description provided for @localExample.
  ///
  /// In en, this message translates to:
  /// **'View example'**
  String get localExample;

  /// No description provided for @localBack.
  ///
  /// In en, this message translates to:
  /// **'Back to my records'**
  String get localBack;

  /// No description provided for @localEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get localEmpty;

  /// No description provided for @localStart.
  ///
  /// In en, this message translates to:
  /// **'Create a profile, then add a lab result, medication course or home measurement.'**
  String get localStart;

  /// No description provided for @localCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get localCreateProfile;

  /// No description provided for @localEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get localEditProfile;

  /// No description provided for @localAddResult.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get localAddResult;

  /// No description provided for @localAddMedication.
  ///
  /// In en, this message translates to:
  /// **'Add course'**
  String get localAddMedication;

  /// No description provided for @localAddMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get localAddMeasurement;

  /// No description provided for @localResults.
  ///
  /// In en, this message translates to:
  /// **'Lab results'**
  String get localResults;

  /// No description provided for @localMedications.
  ///
  /// In en, this message translates to:
  /// **'Medication courses'**
  String get localMedications;

  /// No description provided for @localMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Home measurements'**
  String get localMeasurements;

  /// No description provided for @localSave.
  ///
  /// In en, this message translates to:
  /// **'Save on device'**
  String get localSave;

  /// No description provided for @localSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved on device'**
  String get localSaved;

  /// No description provided for @localCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get localCancel;

  /// No description provided for @localClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get localClose;

  /// No description provided for @localEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get localEdit;

  /// No description provided for @localDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get localDelete;

  /// No description provided for @localDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this record? Previous revisions will remain in history.'**
  String get localDeleteQuestion;

  /// No description provided for @localDiscard.
  ///
  /// In en, this message translates to:
  /// **'Close without saving?'**
  String get localDiscard;

  /// No description provided for @localDiscardText.
  ///
  /// In en, this message translates to:
  /// **'Your entered changes will not be saved.'**
  String get localDiscardText;

  /// No description provided for @localKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get localKeepEditing;

  /// No description provided for @localLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not open local records. Retry loading. The browser needs persistent storage that safely supports multiple tabs.'**
  String get localLoadError;

  /// No description provided for @localSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your input is still in the form; you can retry.'**
  String get localSaveError;

  /// No description provided for @localConflict.
  ///
  /// In en, this message translates to:
  /// **'The saved record has changed. Your input remains in this form. Review the saved version, then close this form and refresh the list before editing again.'**
  String get localConflict;

  /// No description provided for @localInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the entered fields.'**
  String get localInvalid;

  /// No description provided for @localRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get localRequired;

  /// No description provided for @localDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date as YYYY-MM-DD'**
  String get localDateInvalid;

  /// No description provided for @localDateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get localDateHint;

  /// No description provided for @localOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get localOptional;

  /// No description provided for @localOriginalName.
  ///
  /// In en, this message translates to:
  /// **'Original test name'**
  String get localOriginalName;

  /// No description provided for @localValue.
  ///
  /// In en, this message translates to:
  /// **'Value as recorded'**
  String get localValue;

  /// No description provided for @localValueKind.
  ///
  /// In en, this message translates to:
  /// **'Value type'**
  String get localValueKind;

  /// No description provided for @localNumeric.
  ///
  /// In en, this message translates to:
  /// **'Numeric'**
  String get localNumeric;

  /// No description provided for @localComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison: <, ≤, >, ≥'**
  String get localComparison;

  /// No description provided for @localQualitative.
  ///
  /// In en, this message translates to:
  /// **'Qualitative answer'**
  String get localQualitative;

  /// No description provided for @localMissing.
  ///
  /// In en, this message translates to:
  /// **'No value'**
  String get localMissing;

  /// No description provided for @localValueHint.
  ///
  /// In en, this message translates to:
  /// **'Decimal separator, precision and comparison operator are preserved.'**
  String get localValueHint;

  /// No description provided for @localValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the value and selected value type'**
  String get localValueInvalid;

  /// No description provided for @localUnit.
  ///
  /// In en, this message translates to:
  /// **'Original unit'**
  String get localUnit;

  /// No description provided for @localReference.
  ///
  /// In en, this message translates to:
  /// **'Original reference'**
  String get localReference;

  /// No description provided for @localCategory.
  ///
  /// In en, this message translates to:
  /// **'Display group'**
  String get localCategory;

  /// No description provided for @localMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get localMethod;

  /// No description provided for @localSpecimen.
  ///
  /// In en, this message translates to:
  /// **'Specimen'**
  String get localSpecimen;

  /// No description provided for @localNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get localNotes;

  /// No description provided for @localDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get localDosage;

  /// No description provided for @localSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get localSchedule;

  /// No description provided for @localPrescribedBy.
  ///
  /// In en, this message translates to:
  /// **'Prescribed by'**
  String get localPrescribedBy;

  /// No description provided for @localStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get localStartDate;

  /// No description provided for @localEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get localEndDate;

  /// No description provided for @localEndInvalid.
  ///
  /// In en, this message translates to:
  /// **'End date is before start date'**
  String get localEndInvalid;

  /// No description provided for @localMeasurementName.
  ///
  /// In en, this message translates to:
  /// **'Measurement name'**
  String get localMeasurementName;

  /// No description provided for @localSource.
  ///
  /// In en, this message translates to:
  /// **'Device or source'**
  String get localSource;

  /// No description provided for @localTime.
  ///
  /// In en, this message translates to:
  /// **'Local time (HH:MM)'**
  String get localTime;

  /// No description provided for @localOffset.
  ///
  /// In en, this message translates to:
  /// **'UTC offset (±HH:MM)'**
  String get localOffset;

  /// No description provided for @localTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if time is unknown. If entering a time, specify its UTC offset.'**
  String get localTimeHint;

  /// No description provided for @localTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check time and UTC offset'**
  String get localTimeInvalid;

  /// No description provided for @localManual.
  ///
  /// In en, this message translates to:
  /// **'Manually entered and confirmed'**
  String get localManual;

  /// No description provided for @localNoInterpretation.
  ///
  /// In en, this message translates to:
  /// **'References are stored as text. Results are not automatically assessed or merged yet.'**
  String get localNoInterpretation;

  /// No description provided for @localHistory.
  ///
  /// In en, this message translates to:
  /// **'Revision history'**
  String get localHistory;

  /// No description provided for @localRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get localRevision;

  /// No description provided for @localDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get localDeleted;

  /// No description provided for @localActive.
  ///
  /// In en, this message translates to:
  /// **'Active on the selected date'**
  String get localActive;

  /// No description provided for @localOnDate.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get localOnDate;

  /// No description provided for @localSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name, value or laboratory'**
  String get localSearch;

  /// No description provided for @localRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh records'**
  String get localRefresh;

  /// No description provided for @localHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Could not read history. Try again.'**
  String get localHistoryError;

  /// No description provided for @deviceAccessWelcome.
  ///
  /// In en, this message translates to:
  /// **'Device access'**
  String get deviceAccessWelcome;

  /// No description provided for @deviceAccessIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose what to allow. You can continue without permissions and return when adding a document or choosing a clinic. Camera access is requested when taking a photo.'**
  String get deviceAccessIntro;

  /// No description provided for @fileAccessExplanation.
  ///
  /// In en, this message translates to:
  /// **'Files and photos are accessed through the system picker when you choose a document or photo. The app receives only the selected file.'**
  String get fileAccessExplanation;

  /// No description provided for @chooseAttachment.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseAttachment;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueToApp;

  /// No description provided for @accessIntroSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your choice. Try continuing again.'**
  String get accessIntroSaveError;

  /// No description provided for @locationAccessExplanation.
  ///
  /// In en, this message translates to:
  /// **'Location is used to choose nearby clinics. Use your device location or enter a city and address manually.'**
  String get locationAccessExplanation;

  /// No description provided for @locationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Location not selected'**
  String get locationNotSelected;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocation;

  /// No description provided for @deviceAccessBusy.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your device'**
  String get deviceAccessBusy;

  /// No description provided for @manualLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter location manually'**
  String get manualLocation;

  /// No description provided for @manualLocationHint.
  ///
  /// In en, this message translates to:
  /// **'City, street and building'**
  String get manualLocationHint;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a city or address'**
  String get locationRequired;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this address'**
  String get useThisLocation;

  /// No description provided for @chooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get chooseLocation;

  /// No description provided for @deviceAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access was denied. Try again, change the permission in your device settings or choose another method.'**
  String get deviceAccessDenied;

  /// No description provided for @deviceAccessPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission requests are blocked. Change the permission in your device or browser settings. You can enter an address manually.'**
  String get deviceAccessPermanentlyDenied;

  /// No description provided for @deviceAccessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Access is restricted by your device settings. Choose another method.'**
  String get deviceAccessRestricted;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off or unavailable. Enable them in device settings; use HTTPS in a browser. You can also enter an address manually.'**
  String get locationServicesDisabled;

  /// No description provided for @deviceAccessUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This feature is unavailable on this device. Choose another method; you can enter a location manually.'**
  String get deviceAccessUnsupported;

  /// No description provided for @attachmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Selection cancelled. No file was added.'**
  String get attachmentCancelled;

  /// No description provided for @locationTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Finding your location timed out. Try again or enter an address manually.'**
  String get locationTimedOut;

  /// No description provided for @deviceAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action. Try again or choose another method.'**
  String get deviceAccessFailed;

  /// No description provided for @openDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Open device settings'**
  String get openDeviceSettings;

  /// No description provided for @selectedAttachments.
  ///
  /// In en, this message translates to:
  /// **'Selected files'**
  String get selectedAttachments;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove selected file'**
  String get removeAttachment;

  /// No description provided for @attachmentSessionOnly.
  ///
  /// In en, this message translates to:
  /// **'Files are selected for this app session. Saving to medical history and processing are not connected yet; select the files again after restarting.'**
  String get attachmentSessionOnly;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Taking photos is unavailable on this device. Choose a photo from your library or files.'**
  String get cameraUnavailable;

  /// No description provided for @directoryLocationPreview.
  ///
  /// In en, this message translates to:
  /// **'Your selected location does not yet change the demo addresses and distances.'**
  String get directoryLocationPreview;

  /// No description provided for @introductionStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String introductionStep(int current, int total);

  /// No description provided for @introductionProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get introductionProfileTitle;

  /// No description provided for @introductionProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Start with age, sex and height in Profile. Add medications, symptoms and other events as needed to keep your health history together.'**
  String get introductionProfileBody;

  /// No description provided for @introductionReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first test report'**
  String get introductionReportsTitle;

  /// No description provided for @introductionReportsBody.
  ///
  /// In en, this message translates to:
  /// **'The Tests section contains your results. The plus button opens the available ways to add data. Review recognised values against the original report before confirming them.'**
  String get introductionReportsBody;

  /// No description provided for @introductionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore your results'**
  String get introductionSummaryTitle;

  /// No description provided for @introductionSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Summary brings results together. In the example you can open a body system, select a marker and view its history. Show your doctor opens the section for sharing reports.'**
  String get introductionSummaryBody;

  /// No description provided for @introductionLabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare laboratories'**
  String get introductionLabsTitle;

  /// No description provided for @introductionLabsBody.
  ///
  /// In en, this message translates to:
  /// **'In Find a lab, search for tests or providers in Saint Petersburg and Voronezh. Choose an address or device location to see the nearest branches. Confirm availability of network-listed tests at the branch.'**
  String get introductionLabsBody;

  /// No description provided for @introductionDoctorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a specialist'**
  String get introductionDoctorsTitle;

  /// No description provided for @introductionDoctorsBody.
  ///
  /// In en, this message translates to:
  /// **'In Doctors, search for a specialty or a doctor and open a card. It shows the clinic and information about the appointment.'**
  String get introductionDoctorsBody;

  /// No description provided for @introductionAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan an appointment'**
  String get introductionAppointmentTitle;

  /// No description provided for @introductionAppointmentBody.
  ///
  /// In en, this message translates to:
  /// **'The card links to the provider’s booking website and phone number. The clinic confirms your booking. You can repeat this introduction in Settings.'**
  String get introductionAppointmentBody;

  /// No description provided for @introductionNotice.
  ///
  /// In en, this message translates to:
  /// **'This introduction shows sections without changing your records. Actions unavailable in this version are labelled in the interface.'**
  String get introductionNotice;

  /// No description provided for @introductionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introductionSkip;

  /// No description provided for @introductionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get introductionBack;

  /// No description provided for @introductionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introductionNext;

  /// No description provided for @introductionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get introductionDone;

  /// No description provided for @introductionSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save completion. Tap Skip or Done again to retry.'**
  String get introductionSaveError;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// No description provided for @terminologyTitle.
  ///
  /// In en, this message translates to:
  /// **'Indicator dictionary'**
  String get terminologyTitle;

  /// No description provided for @terminologyHint.
  ///
  /// In en, this message translates to:
  /// **'Link this result to an indicator and unit. Your original text is kept. Linking is optional.'**
  String get terminologyHint;

  /// No description provided for @terminologyUnknown.
  ///
  /// In en, this message translates to:
  /// **'No exact match. Choose a concept or save without linking.'**
  String get terminologyUnknown;

  /// No description provided for @terminologyAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Several concepts match. Check the specimen and choose, or leave unlinked.'**
  String get terminologyAmbiguous;

  /// No description provided for @terminologySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {name}. Select explicitly to link.'**
  String terminologySuggestion(String name);

  /// No description provided for @terminologyChanged.
  ///
  /// In en, this message translates to:
  /// **'Source details changed. Choose the concept again if needed.'**
  String get terminologyChanged;

  /// No description provided for @terminologyIndicator.
  ///
  /// In en, this message translates to:
  /// **'Dictionary indicator'**
  String get terminologyIndicator;

  /// No description provided for @terminologyUnit.
  ///
  /// In en, this message translates to:
  /// **'Dictionary unit'**
  String get terminologyUnit;

  /// No description provided for @terminologyUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Leave unlinked'**
  String get terminologyUnlinked;

  /// No description provided for @terminologySelected.
  ///
  /// In en, this message translates to:
  /// **'Your selection will be saved with this result. Values and reference ranges are kept as entered.'**
  String get terminologySelected;

  /// No description provided for @originalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Original documents'**
  String get originalsTitle;

  /// No description provided for @originalsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect storage'**
  String get originalsConnect;

  /// No description provided for @originalsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect storage'**
  String get originalsDisconnect;

  /// No description provided for @originalsConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the Documents server address and access token. The token is kept only for this app session. Uploads start only when you choose them.'**
  String get originalsConnectionHint;

  /// No description provided for @originalsEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get originalsEndpoint;

  /// No description provided for @originalsToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get originalsToken;

  /// No description provided for @originalsConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Check the address and token. HTTPS is required except for a local development server.'**
  String get originalsConnectionError;

  /// No description provided for @originalsHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the original PDF, PNG or JPEG on this device (up to 20 MiB). Importing does not create medical results or send files to AI. Cloud upload is a separate action.'**
  String get originalsHint;

  /// No description provided for @originalsImport.
  ///
  /// In en, this message translates to:
  /// **'Import file'**
  String get originalsImport;

  /// No description provided for @originalsTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose a non-empty file up to 20 MiB.'**
  String get originalsTooLarge;

  /// No description provided for @originalsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Supported originals: PDF, PNG and JPEG. The file type is checked from its bytes.'**
  String get originalsUnsupported;

  /// No description provided for @originalsIntegrityError.
  ///
  /// In en, this message translates to:
  /// **'Integrity check failed. The original has not been accepted.'**
  String get originalsIntegrityError;

  /// No description provided for @originalsQuota.
  ///
  /// In en, this message translates to:
  /// **'The cloud storage quota is full. The local original is kept.'**
  String get originalsQuota;

  /// No description provided for @originalsAccess.
  ///
  /// In en, this message translates to:
  /// **'Cloud access is unavailable for this profile.'**
  String get originalsAccess;

  /// No description provided for @originalsProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Create a local medical profile before importing.'**
  String get originalsProfileRequired;

  /// No description provided for @originalsFailed.
  ///
  /// In en, this message translates to:
  /// **'The operation failed. Your saved local originals are kept; try again.'**
  String get originalsFailed;

  /// No description provided for @originalsLocalSaved.
  ///
  /// In en, this message translates to:
  /// **'Original saved on this device.'**
  String get originalsLocalSaved;

  /// No description provided for @originalsCloudSaved.
  ///
  /// In en, this message translates to:
  /// **'Verified original saved in the cloud.'**
  String get originalsCloudSaved;

  /// No description provided for @originalsVerified.
  ///
  /// In en, this message translates to:
  /// **'Downloaded bytes match the original SHA-256.'**
  String get originalsVerified;

  /// No description provided for @originalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No originals saved yet.'**
  String get originalsEmpty;

  /// No description provided for @originalsLocal.
  ///
  /// In en, this message translates to:
  /// **'On this device only'**
  String get originalsLocal;

  /// No description provided for @originalsPending.
  ///
  /// In en, this message translates to:
  /// **'Cloud transfer pending — retry is safe'**
  String get originalsPending;

  /// No description provided for @originalsIntegrity.
  ///
  /// In en, this message translates to:
  /// **'File integrity'**
  String get originalsIntegrity;

  /// No description provided for @originalsExport.
  ///
  /// In en, this message translates to:
  /// **'Save a local copy'**
  String get originalsExport;

  /// No description provided for @originalsUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload to cloud'**
  String get originalsUpload;

  /// No description provided for @originalsDownloadVerify.
  ///
  /// In en, this message translates to:
  /// **'Download and verify'**
  String get originalsDownloadVerify;

  /// No description provided for @originalsOtherConnection.
  ///
  /// In en, this message translates to:
  /// **'Saved through a different connection. Upload again to confirm this storage destination.'**
  String get originalsOtherConnection;

  /// No description provided for @processingTitle.
  ///
  /// In en, this message translates to:
  /// **'Document draft'**
  String get processingTitle;

  /// No description provided for @processingConsent.
  ///
  /// In en, this message translates to:
  /// **'Choose where to process this original. Local mode sends nothing to the server. Server mode uses your own server; no external AI API is enabled. All fields require review before medical records are created.'**
  String get processingConsent;

  /// No description provided for @processingLocal.
  ///
  /// In en, this message translates to:
  /// **'Process locally'**
  String get processingLocal;

  /// No description provided for @processingServer.
  ///
  /// In en, this message translates to:
  /// **'Process on my server'**
  String get processingServer;

  /// No description provided for @processingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel processing'**
  String get processingCancel;

  /// No description provided for @processingBackground.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen. The job is kept and can be resumed.'**
  String get processingBackground;

  /// No description provided for @processingDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a complete result date before confirming. An unknown date is never replaced with today.'**
  String get processingDateRequired;

  /// No description provided for @processingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Processing in this mode is unavailable on this device. Review the document manually or choose another mode.'**
  String get processingUnavailable;

  /// No description provided for @processingUploadFirst.
  ///
  /// In en, this message translates to:
  /// **'Upload this original to the connected Documents storage before server processing.'**
  String get processingUploadFirst;

  /// No description provided for @processingAlreadyConfirmed.
  ///
  /// In en, this message translates to:
  /// **'This original already has confirmed records. Edit those records instead of importing it again.'**
  String get processingAlreadyConfirmed;

  /// No description provided for @processingConflict.
  ///
  /// In en, this message translates to:
  /// **'The draft changed elsewhere. Reopen the saved draft before continuing.'**
  String get processingConflict;

  /// No description provided for @processingRuntimeChanged.
  ///
  /// In en, this message translates to:
  /// **'The processing runtime changed. Start a new run to use the new version.'**
  String get processingRuntimeChanged;

  /// No description provided for @processingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No result rows were extracted. Review the OCR text or enter results manually.'**
  String get processingEmpty;

  /// No description provided for @processingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Processing cancelled. Saved originals and drafts are kept.'**
  String get processingCancelled;

  /// No description provided for @processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing or saving failed. The original and saved draft are kept. You can retry or review the OCR text.'**
  String get processingFailed;

  /// No description provided for @processingRuns.
  ///
  /// In en, this message translates to:
  /// **'Processing runs'**
  String get processingRuns;

  /// No description provided for @processingQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get processingQueued;

  /// No description provided for @processingOcr.
  ///
  /// In en, this message translates to:
  /// **'Reading document (OCR)'**
  String get processingOcr;

  /// No description provided for @processingLlm.
  ///
  /// In en, this message translates to:
  /// **'Extracting fields (LLM)'**
  String get processingLlm;

  /// No description provided for @processingReview.
  ///
  /// In en, this message translates to:
  /// **'Draft — review and correct'**
  String get processingReview;

  /// No description provided for @processingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Records confirmed'**
  String get processingConfirmed;

  /// No description provided for @processingReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check names, values, comparison signs, units, references and dates against the original. Dictionary matches are suggestions until you select them. Excluded rows are not confirmed.'**
  String get processingReviewHint;

  /// No description provided for @processingOcrText.
  ///
  /// In en, this message translates to:
  /// **'Recognized source text'**
  String get processingOcrText;

  /// No description provided for @processingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown — check the original'**
  String get processingUnknown;

  /// No description provided for @processingUnbacked.
  ///
  /// In en, this message translates to:
  /// **'The AI field differs from the source or combines columns. Check the OCR and fill it in manually.'**
  String get processingUnbacked;

  /// No description provided for @processingSourceValue.
  ///
  /// In en, this message translates to:
  /// **'Extracted source: {value}'**
  String processingSourceValue(String value);

  /// No description provided for @processingSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get processingSaveDraft;

  /// No description provided for @processingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm selected results'**
  String get processingConfirm;

  /// No description provided for @processingOpen.
  ///
  /// In en, this message translates to:
  /// **'Recognize and review'**
  String get processingOpen;

  /// No description provided for @processingImported.
  ///
  /// In en, this message translates to:
  /// **'Confirmed from a document'**
  String get processingImported;

  /// No description provided for @processingManual.
  ///
  /// In en, this message translates to:
  /// **'Review OCR manually'**
  String get processingManual;

  /// No description provided for @processingAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add result'**
  String get processingAddRow;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Period report'**
  String get reportTitle;

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'Period summary'**
  String get reportSummary;

  /// No description provided for @reportFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportFrom;

  /// No description provided for @reportTo.
  ///
  /// In en, this message translates to:
  /// **'Through'**
  String get reportTo;

  /// No description provided for @reportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid period: YYYY-MM-DD'**
  String get reportInvalid;

  /// No description provided for @reportScope.
  ///
  /// In en, this message translates to:
  /// **'Results and measurements use their source dates; courses are included when they overlap the period. The full profile is included. Original files are not included.'**
  String get reportScope;

  /// No description provided for @reportNoInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Original values and references are preserved without conversion.'**
  String get reportNoInterpretation;

  /// No description provided for @reportPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous compatible result in period'**
  String get reportPrevious;

  /// No description provided for @reportExport.
  ///
  /// In en, this message translates to:
  /// **'Save HTML for viewing and printing'**
  String get reportExport;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved'**
  String get reportSaved;

  /// No description provided for @reportExportError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the report. Try again.'**
  String get reportExportError;

  /// No description provided for @reportOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original document fragment'**
  String get reportOriginal;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Record synchronization'**
  String get syncTitle;

  /// No description provided for @syncScope.
  ///
  /// In en, this message translates to:
  /// **'Confirmed records and deletions are synchronized. Local saving works offline. Originals and recognition drafts are separate. Connecting enables exchange and retries while the app is open; the token stays in memory.'**
  String get syncScope;

  /// No description provided for @syncConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect and synchronize'**
  String get syncConnect;

  /// No description provided for @syncConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to record storage'**
  String get syncConnected;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Synchronize / retry'**
  String get syncNow;

  /// No description provided for @syncDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get syncDisconnect;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting server acknowledgement: {count}'**
  String syncPending(int count);

  /// No description provided for @syncConflictCount.
  ///
  /// In en, this message translates to:
  /// **'Edit conflicts: {count}'**
  String syncConflictCount(int count);

  /// No description provided for @syncLast.
  ///
  /// In en, this message translates to:
  /// **'Last completed exchange: {date}'**
  String syncLast(String date);

  /// No description provided for @syncRetryAt.
  ///
  /// In en, this message translates to:
  /// **'Automatic retry after: {date}'**
  String syncRetryAt(String date);

  /// No description provided for @syncUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The token is invalid. Reconnect with a valid token.'**
  String get syncUnauthorized;

  /// No description provided for @syncAccess.
  ///
  /// In en, this message translates to:
  /// **'The server denied exchange. Local records are preserved.'**
  String get syncAccess;

  /// No description provided for @syncAccount.
  ///
  /// In en, this message translates to:
  /// **'This local profile is already bound to another record storage or owner.'**
  String get syncAccount;

  /// No description provided for @syncServerChanged.
  ///
  /// In en, this message translates to:
  /// **'The server history changed or was restored from a different copy. The binding needs review; local data is preserved.'**
  String get syncServerChanged;

  /// No description provided for @syncConflictChanged.
  ///
  /// In en, this message translates to:
  /// **'A version changed during selection. Review the refreshed data and try again.'**
  String get syncConflictChanged;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Exchange did not finish. The queue is preserved; you can retry.'**
  String get syncFailed;

  /// No description provided for @syncLocalVersion.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get syncLocalVersion;

  /// No description provided for @syncRemoteVersion.
  ///
  /// In en, this message translates to:
  /// **'On the server'**
  String get syncRemoteVersion;

  /// No description provided for @syncDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get syncDeleted;

  /// No description provided for @syncResolveHint.
  ///
  /// In en, this message translates to:
  /// **'Both versions remain in history. Choosing the local version after a server deletion restores the record when sent.'**
  String get syncResolveHint;

  /// No description provided for @syncKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Use local version'**
  String get syncKeepLocal;

  /// No description provided for @syncUseServer.
  ///
  /// In en, this message translates to:
  /// **'Use server version'**
  String get syncUseServer;

  /// No description provided for @reportSaveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Saving a file is unavailable on this device. You can copy the report.'**
  String get reportSaveUnavailable;

  /// No description provided for @reportCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get reportCopy;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get reportCopied;

  /// No description provided for @reportCopyError.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the report.'**
  String get reportCopyError;

  /// No description provided for @accountDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to connect to the cloud. Local records are available without signing in.'**
  String get accountDescription;

  /// No description provided for @accountManage.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and devices'**
  String get accountManage;

  /// No description provided for @accountAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get accountAction;

  /// No description provided for @accountLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountLogin;

  /// No description provided for @accountRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountRegister;

  /// No description provided for @accountRecover.
  ///
  /// In en, this message translates to:
  /// **'Recover access'**
  String get accountRecover;

  /// No description provided for @accountSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send email code'**
  String get accountSendCode;

  /// No description provided for @accountCode.
  ///
  /// In en, this message translates to:
  /// **'Email code'**
  String get accountCode;

  /// No description provided for @accountCodeSent.
  ///
  /// In en, this message translates to:
  /// **'If this request applies to this address, an email has been sent. The 8-digit code expires in 15 minutes. Check your spam folder.'**
  String get accountCodeSent;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountNewPassword;

  /// No description provided for @accountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'15–128 characters. Spaces are allowed.'**
  String get accountPasswordHint;

  /// No description provided for @accountShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get accountShowPassword;

  /// No description provided for @accountHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get accountHidePassword;

  /// No description provided for @accountDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get accountDeviceName;

  /// No description provided for @accountThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get accountThisDevice;

  /// No description provided for @accountResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get accountResetPassword;

  /// No description provided for @accountChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change address or request a new code'**
  String get accountChangeEmail;

  /// No description provided for @accountRecovered.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Previous sessions have ended. Sign in with your new password.'**
  String get accountRecovered;

  /// No description provided for @accountSecondDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'On your second device, sign in with the same email and password, then connect synchronization.'**
  String get accountSecondDeviceHint;

  /// No description provided for @accountConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Connecting sends confirmed local records to this account and downloads cloud records. Conflicts require your choice.'**
  String get accountConnectHint;

  /// No description provided for @accountConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect records on this device'**
  String get accountConnect;

  /// No description provided for @accountReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect synchronization'**
  String get accountReconnect;

  /// No description provided for @accountDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices and sessions'**
  String get accountDevices;

  /// No description provided for @accountRefreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get accountRefreshDevices;

  /// No description provided for @accountThisSession.
  ///
  /// In en, this message translates to:
  /// **'current session'**
  String get accountThisSession;

  /// No description provided for @accountRevoke.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get accountRevoke;

  /// No description provided for @accountLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out on this device'**
  String get accountLogout;

  /// No description provided for @accountLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'End all sessions'**
  String get accountLogoutAll;

  /// No description provided for @accountEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get accountEmailError;

  /// No description provided for @accountCodeError.
  ///
  /// In en, this message translates to:
  /// **'The code is invalid, expired or already used. Check all 8 digits or request a new code.'**
  String get accountCodeError;

  /// No description provided for @accountCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get accountCredentialsError;

  /// No description provided for @accountExists.
  ///
  /// In en, this message translates to:
  /// **'This account already exists. Sign in or recover access.'**
  String get accountExists;

  /// No description provided for @accountRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in 15 minutes.'**
  String get accountRateLimited;

  /// No description provided for @accountBindingError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect synchronization. Check its status. If local records are already bound to another account or server, connection is blocked to prevent mixing data.'**
  String get accountBindingError;

  /// No description provided for @accountStorageError.
  ///
  /// In en, this message translates to:
  /// **'Signed in, but the session could not be saved to secure storage. You may need to sign in after restarting.'**
  String get accountStorageError;

  /// No description provided for @accountSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended or expired. Sign in again. Local records are preserved.'**
  String get accountSessionExpired;

  /// No description provided for @accountNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Request failed. Check your connection and retry. If the operation already completed, try signing in.'**
  String get accountNetworkError;

  /// No description provided for @cloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud access and quotas'**
  String get cloudTitle;

  /// No description provided for @cloudRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh access and usage'**
  String get cloudRefresh;

  /// No description provided for @cloudEnabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get cloudEnabled;

  /// No description provided for @cloudDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get cloudDisabled;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get cloudSync;

  /// No description provided for @cloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Cloud originals'**
  String get cloudStorage;

  /// No description provided for @cloudProcessing.
  ///
  /// In en, this message translates to:
  /// **'Server recognition'**
  String get cloudProcessing;

  /// No description provided for @cloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not check cloud access and quotas. Try again later. Local data remains available.'**
  String get cloudUnavailable;

  /// No description provided for @cloudLastKnown.
  ///
  /// In en, this message translates to:
  /// **'The last received values below may be out of date.'**
  String get cloudLastKnown;

  /// No description provided for @cloudLocalKept.
  ///
  /// In en, this message translates to:
  /// **'Disabled cloud access or a full quota preserves local records, originals and pending uploads.'**
  String get cloudLocalKept;

  /// No description provided for @cloudSyncDenied.
  ///
  /// In en, this message translates to:
  /// **'Cloud record writes are disabled. Pending changes are kept; existing cloud records can still be downloaded.'**
  String get cloudSyncDenied;

  /// No description provided for @cloudSyncQuota.
  ///
  /// In en, this message translates to:
  /// **'Cloud record limit reached. The local record and pending change are kept.'**
  String get cloudSyncQuota;

  /// No description provided for @cloudProcessingDenied.
  ///
  /// In en, this message translates to:
  /// **'Server recognition is disabled for this account. Available local processing and manual entry remain accessible.'**
  String get cloudProcessingDenied;

  /// No description provided for @cloudProcessingQuota.
  ///
  /// In en, this message translates to:
  /// **'The monthly recognition quota is full. Wait for pending jobs or the next month. The original is kept.'**
  String get cloudProcessingQuota;

  /// No description provided for @cloudRecordUsage.
  ///
  /// In en, this message translates to:
  /// **'Records: {used} of {limit}'**
  String cloudRecordUsage(int used, int limit);

  /// No description provided for @cloudByteUsage.
  ///
  /// In en, this message translates to:
  /// **'Bytes: {used}; reserved: {reserved}; limit: {limit}'**
  String cloudByteUsage(String used, String reserved, String limit);

  /// No description provided for @cloudJobUsage.
  ///
  /// In en, this message translates to:
  /// **'For {period}: {used} of {limit}; queued or running: {reserved}'**
  String cloudJobUsage(int used, int reserved, int limit, String period);

  /// No description provided for @cloudUntil.
  ///
  /// In en, this message translates to:
  /// **'Access valid until {date}'**
  String cloudUntil(String date);

  /// No description provided for @confirmCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Are you here?'**
  String get confirmCurrentLocation;

  /// No description provided for @confirmLocationYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I am here'**
  String get confirmLocationYes;

  /// No description provided for @enterAnotherLocation.
  ///
  /// In en, this message translates to:
  /// **'No, enter another address'**
  String get enterAnotherLocation;

  /// No description provided for @locationAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not find an address for your GPS location. Check the last address or enter a new one manually.'**
  String get locationAddressUnavailable;

  /// No description provided for @locationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'This address is available for this session, but could not be saved on this device. Try selecting it again.'**
  String get locationSaveFailed;

  /// No description provided for @searchingAddresses.
  ///
  /// In en, this message translates to:
  /// **'Searching for addresses…'**
  String get searchingAddresses;

  /// No description provided for @addressSuggestionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address suggestions are unavailable. You can enter an address manually.'**
  String get addressSuggestionsUnavailable;

  /// No description provided for @addressSuggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No addresses found. Refine your search or use the address you entered.'**
  String get addressSuggestionsEmpty;

  /// No description provided for @addressSearchProvider.
  ///
  /// In en, this message translates to:
  /// **'Address lookup: Photon · © OpenStreetMap contributors. Your query or coordinates are sent to the address search service.'**
  String get addressSearchProvider;

  /// No description provided for @lastLocationAddress.
  ///
  /// In en, this message translates to:
  /// **'Last address: {address}'**
  String lastLocationAddress(String address);

  /// No description provided for @directoryCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get directoryCity;

  /// No description provided for @directorySpb.
  ///
  /// In en, this message translates to:
  /// **'Saint Petersburg'**
  String get directorySpb;

  /// No description provided for @directoryVoronezh.
  ///
  /// In en, this message translates to:
  /// **'Voronezh'**
  String get directoryVoronezh;

  /// No description provided for @directoryNeedPoint.
  ///
  /// In en, this message translates to:
  /// **'Could not determine coordinates for this address. Select an address suggestion with a house number or confirm your device location to calculate distances.'**
  String get directoryNeedPoint;

  /// No description provided for @directorySorted.
  ///
  /// In en, this message translates to:
  /// **'Nearest first · straight-line distance'**
  String get directorySorted;

  /// No description provided for @directoryDoctorSearch.
  ///
  /// In en, this message translates to:
  /// **'Doctor, specialty or clinic'**
  String get directoryDoctorSearch;

  /// No description provided for @directoryLabSearch.
  ///
  /// In en, this message translates to:
  /// **'Test, provider or address'**
  String get directoryLabSearch;

  /// No description provided for @directorySpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get directorySpecialty;

  /// No description provided for @directoryAllSpecialties.
  ///
  /// In en, this message translates to:
  /// **'All specialties'**
  String get directoryAllSpecialties;

  /// No description provided for @directoryTestDetails.
  ///
  /// In en, this message translates to:
  /// **'Panel, specimen and method'**
  String get directoryTestDetails;

  /// No description provided for @directorySpecimen.
  ///
  /// In en, this message translates to:
  /// **'Specimen'**
  String get directorySpecimen;

  /// No description provided for @directoryMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get directoryMethod;

  /// No description provided for @directoryComponents.
  ///
  /// In en, this message translates to:
  /// **'Panel components'**
  String get directoryComponents;

  /// No description provided for @directoryNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Not specified by the source'**
  String get directoryNotPublished;

  /// No description provided for @directoryChooseTests.
  ///
  /// In en, this message translates to:
  /// **'Choose tests'**
  String get directoryChooseTests;

  /// No description provided for @directoryTestSearchNotice.
  ///
  /// In en, this message translates to:
  /// **'Choose a test type. The dictionary groups provider name variants; cards show the original formulations.'**
  String get directoryTestSearchNotice;

  /// No description provided for @directoryLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. Copy the website address from the card or use its phone number.'**
  String get directoryLinkFailed;

  /// No description provided for @directoryResults.
  ///
  /// In en, this message translates to:
  /// **'Results: {count}'**
  String directoryResults(int count);

  /// No description provided for @directorySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Directory verified on {date} · doctors and services may change.'**
  String directorySnapshot(String date);

  /// No description provided for @directoryOutsideCoverage.
  ///
  /// In en, this message translates to:
  /// **'This location is outside the pilot search area. Choose an address in Saint Petersburg or Voronezh.'**
  String get directoryOutsideCoverage;

  /// No description provided for @directoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matches in this directory snapshot. Change your search, city or selected tests.'**
  String get directoryEmpty;

  /// No description provided for @directoryCoverage.
  ///
  /// In en, this message translates to:
  /// **'A selection of providers in Saint Petersburg and Voronezh. The provider confirms your booking.'**
  String get directoryCoverage;

  /// No description provided for @directoryMapAttribution.
  ///
  /// In en, this message translates to:
  /// **'Geodata © OpenStreetMap contributors'**
  String get directoryMapAttribution;

  /// No description provided for @directoryUnknownDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable'**
  String get directoryUnknownDistance;

  /// No description provided for @directoryMeters.
  ///
  /// In en, this message translates to:
  /// **'{value} m straight-line distance'**
  String directoryMeters(String value);

  /// No description provided for @directoryKilometers.
  ///
  /// In en, this message translates to:
  /// **'{value} km straight-line distance'**
  String directoryKilometers(String value);

  /// No description provided for @directoryAvailabilityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Tests appear in the network catalogue. Confirm availability at this branch.'**
  String get directoryAvailabilityUnknown;

  /// No description provided for @directoryAllTests.
  ///
  /// In en, this message translates to:
  /// **'Test catalogue'**
  String get directoryAllTests;

  /// No description provided for @directorySource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get directorySource;

  /// No description provided for @directoryContactNotice.
  ///
  /// In en, this message translates to:
  /// **'Published provider or network contact.'**
  String get directoryContactNotice;

  /// No description provided for @addressEntrySequence.
  ///
  /// In en, this message translates to:
  /// **'Start with a city, then choose a street and building.'**
  String get addressEntrySequence;

  /// No description provided for @addressEnterStreet.
  ///
  /// In en, this message translates to:
  /// **'City selected. Now enter a street.'**
  String get addressEnterStreet;

  /// No description provided for @addressEnterBuilding.
  ///
  /// In en, this message translates to:
  /// **'Street selected. Now enter a building number.'**
  String get addressEnterBuilding;

  /// No description provided for @addressReady.
  ///
  /// In en, this message translates to:
  /// **'Address selected. Confirm it using the button below.'**
  String get addressReady;

  /// No description provided for @directoryRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh directory'**
  String get directoryRefresh;

  /// No description provided for @directoryRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to refresh. Showing the last saved version.'**
  String get directoryRefreshFailed;

  /// No description provided for @directorySourceChecked.
  ///
  /// In en, this message translates to:
  /// **'Address checked: {date}'**
  String directorySourceChecked(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
