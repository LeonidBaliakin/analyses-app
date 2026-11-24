// Flutter 3.50 gen_l10n still emits deprecated compatibility delegates.
// Keep this exception limited to SDK-generated localization code.
// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Orange of Health';

  @override
  String get summary => 'Summary';

  @override
  String get results => 'Results';

  @override
  String get documents => 'Documents';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get summaryIntro => 'Your results and health history in one place.';

  @override
  String get summaryEmptyTitle => 'Your health history starts here';

  @override
  String get summaryEmptyMessage =>
      'No results have been saved yet. Changes in your results and the context of each test will appear here.';

  @override
  String get openResults => 'View results';

  @override
  String get resultsEmptyTitle => 'No results yet';

  @override
  String get resultsEmptyMessage =>
      'Your results and trends will appear here. Adding and saving results will be available in a future update.';

  @override
  String get documentsEmptyTitle => 'No documents yet';

  @override
  String get documentsEmptyMessage =>
      'Original lab reports and discharge summaries will appear here. Document import is not available yet.';

  @override
  String get profileEmptyTitle => 'Your profile is empty';

  @override
  String get profileEmptyMessage =>
      'A health profile will bring together one person’s results, events, medications and home measurements. Editing will be available in a future update.';

  @override
  String get appearance => 'Language and appearance';

  @override
  String get preferencesDescription =>
      'These preferences are saved on this device and work offline.';

  @override
  String get language => 'Interface language';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get savingPreferences => 'Saving preferences';

  @override
  String get preferencesLoadError =>
      'Could not load preferences. Device defaults are in use. Please try again.';

  @override
  String get preferencesSaveError =>
      'Could not save your choice. Please select the value again.';

  @override
  String get retry => 'Retry';

  @override
  String get returnToSummary => 'Go to summary';

  @override
  String get demoTitle => 'You are viewing demo data.';

  @override
  String get demoIntro => 'Sign in to upload your results and save changes.';

  @override
  String get signIn => 'Sign in';

  @override
  String get previewOnly =>
      'This is an interface preview. Sign-in, medical record storage and external services are not connected yet.';

  @override
  String get close => 'Close';

  @override
  String get patientOffice => 'Patient account';

  @override
  String get addAnalysis => 'Add results';

  @override
  String get labsNav => 'Find a lab';

  @override
  String get doctorsNav => 'Doctors';

  @override
  String get showDoctor => 'Show a doctor';

  @override
  String get latestVisit => 'Latest tests';

  @override
  String visitCompare(String date) {
    return 'Compare with $date';
  }

  @override
  String get inRange => 'In range';

  @override
  String get outOfRange => 'Out of range';

  @override
  String get notRecently => 'Not tested recently';

  @override
  String get allResults => 'All results';

  @override
  String get visitEvents => 'Events around testing';

  @override
  String eventCount(int count) {
    return '$count events';
  }

  @override
  String get moreEvents => 'More';

  @override
  String get addEvent => 'Add an event';

  @override
  String get measurementDiary => 'Measurement diary';

  @override
  String get systemsHeading => 'Results by body system';

  @override
  String get systemSearch => 'Find a result or body system';

  @override
  String shownSystems(int count, int total) {
    return 'Showing $count of $total systems';
  }

  @override
  String get chooseSystems => 'Choose systems';

  @override
  String get showHints => 'View tips';

  @override
  String get noMatches =>
      'No results found. Check the spelling or search by body system.';

  @override
  String get sectionBlood => 'Blood';

  @override
  String get sectionMetabolism => 'Metabolism';

  @override
  String get sectionOrgans => 'Organs';

  @override
  String get sectionImmunity => 'Immunity and infections';

  @override
  String get systemCarbs => 'Carbohydrate metabolism';

  @override
  String get systemBlood => 'Complete blood count';

  @override
  String get systemLipids => 'Lipid profile';

  @override
  String get systemVitamins => 'Vitamins';

  @override
  String get systemIron => 'Iron metabolism';

  @override
  String get systemElectro => 'Electrolytes and minerals';

  @override
  String get systemAllergy => 'Allergy profile';

  @override
  String get systemHormones => 'Hormones';

  @override
  String get systemLiver => 'Liver and protein metabolism';

  @override
  String get systemKidney => 'Kidneys and purine metabolism';

  @override
  String get systemGut => 'Digestive system and infections';

  @override
  String get systemTumor => 'Tumor markers';

  @override
  String get systemCoag => 'Coagulation tests';

  @override
  String get systemInflammation => 'Inflammation';

  @override
  String get systemInfections => 'Infections';

  @override
  String get systemUrine => 'Urinalysis';

  @override
  String get subCarbs => 'Glucose, HbA1c, insulin';

  @override
  String get subBlood => 'Red cells, white cells, platelets';

  @override
  String get subLipids => 'Cholesterol fractions, triglycerides';

  @override
  String get subVitamins => 'D, B12, folic acid';

  @override
  String get subIron => 'Serum iron, ferritin';

  @override
  String get subElectro => 'Potassium, sodium, chloride, magnesium';

  @override
  String get subAllergy => 'Total and specific IgE, IgG';

  @override
  String get subHormones => 'Thyroid hormones, testosterone';

  @override
  String get subLiver => 'Liver enzymes, bilirubin, protein';

  @override
  String get subKidney => 'Creatinine, urea, uric acid';

  @override
  String get subGut => 'Helicobacter pylori';

  @override
  String get subTumor => 'PSA, CEA, CA 19-9 and others';

  @override
  String get subCoag => 'INR, aPTT, fibrinogen, D-dimer';

  @override
  String get subInflammation => 'CRP, ESR, rheumatology tests';

  @override
  String get subInfections => 'HIV, syphilis, hepatitis B and C';

  @override
  String get subUrine => 'Specific gravity, protein, white cells';

  @override
  String withData(int count, int total) {
    return '$count of $total with data';
  }

  @override
  String resultCount(int count) {
    return '$count results';
  }

  @override
  String abnormalCount(int count) {
    return '$count out of range';
  }

  @override
  String get allNormal => 'all in range';

  @override
  String get noData => 'no data';

  @override
  String get notUploaded => 'not uploaded yet';

  @override
  String get noSystemData =>
      'The uploaded reports contain no results for this system.';

  @override
  String get fullHistory => 'Complete result history';

  @override
  String get historySub => '9 visits · 59 results';

  @override
  String get openTable => 'Open table';

  @override
  String get sourceDisclaimer =>
      'The service displays values, units and laboratory reference ranges from reports. It does not diagnose or recommend treatment. Your doctor interprets the results.';

  @override
  String get indicator => 'Test';

  @override
  String get latestValue => 'Latest';

  @override
  String get labReference => 'Lab reference';

  @override
  String get previousValue => 'Previous';

  @override
  String get aboveRange => 'above range';

  @override
  String get belowRange => 'below range';

  @override
  String get resultHistory => 'Result history';

  @override
  String get dateLabel => 'Date';

  @override
  String get valueLabel => 'Value';

  @override
  String get originalName => 'Original report name';

  @override
  String get uploadTitle => 'Upload test reports';

  @override
  String get uploadIntro =>
      'Add a report from any laboratory. Review extracted results before saving. The original document stays with the results.';

  @override
  String get uploadDrop =>
      'A photo, a screenshot from your lab app, or a PDF from email.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get filePdf => 'File or PDF';

  @override
  String get uploadPermission =>
      'The app will ask for access to your camera, gallery or files when import is available.';

  @override
  String get photoScreenshot => 'Photo or screenshot';

  @override
  String get photoAdvice =>
      'Capture the full report, including its date and reference ranges.';

  @override
  String get pdfAdvice => 'A file from your laboratory app or account.';

  @override
  String get forwardMail => 'Forward an email';

  @override
  String get mailAdvice => 'Forward a laboratory email to';

  @override
  String get demoEmail => 'Example address';

  @override
  String get labLabel => 'Laboratory';

  @override
  String get statusLabel => 'Status';

  @override
  String get fileLabel => 'File';

  @override
  String get verified => 'Reviewed';

  @override
  String get openReport => 'Open report';

  @override
  String get testReason => 'Reason for testing';

  @override
  String get profileIntro =>
      'Information that helps your doctor interpret tests. Medications, weight and illnesses appear alongside results by date. The service does not assess your profile.';

  @override
  String get profileComplete => 'Profile 100% complete';

  @override
  String get profileCompleteHint =>
      'All filled in. Update your weight and medications when something changes.';

  @override
  String get profileComplaints => 'Symptoms';

  @override
  String get profileBase => 'Basics';

  @override
  String get profileMedicines => 'Medications and supplements';

  @override
  String get profileWeight => 'Weight';

  @override
  String get profileIllness => 'Illnesses';

  @override
  String get profileHospital => 'Hospital stays';

  @override
  String get profileAllergies => 'Allergies';

  @override
  String get profileHistory => 'Medical history';

  @override
  String get profileLifestyle => 'Lifestyle';

  @override
  String get profileDocuments => 'Documents and imaging';

  @override
  String get profileComplaintsSub => 'What bothers you and since when';

  @override
  String get profileBaseSub => 'Sex, age, height';

  @override
  String get profileMedicinesSub => 'Courses and ongoing use';

  @override
  String get profileWeightSub => 'Weight history';

  @override
  String get profileIllnessSub => 'Recent illnesses, fever, antibiotics';

  @override
  String get profileHospitalSub => 'When and where you stayed in hospital';

  @override
  String get profileAllergiesSub => 'Triggers and reactions';

  @override
  String get profileHistorySub =>
      'Conditions, operations, injuries, family history';

  @override
  String get profileLifestyleSub => 'Activity, sleep, diet, alcohol';

  @override
  String get profileDocumentsSub => 'ECG, ultrasound, X-rays, CT, MRI';

  @override
  String get filled => 'filled in';

  @override
  String get comingSoon => 'coming soon';

  @override
  String get addPhotoTitle => 'Photograph a report';

  @override
  String get addGalleryTitle => 'Photo or screenshot from gallery';

  @override
  String get addFilesHint => 'From email or your laboratory account';

  @override
  String get addGalleryHint => 'For example, a screenshot from your lab app';

  @override
  String get addMailTitle => 'Forward a laboratory email';

  @override
  String get labsTitle => 'Find a laboratory';

  @override
  String get locationExample => 'Saint Petersburg, Nevsky Prospekt 28';

  @override
  String get change => 'Change';

  @override
  String get labSearch => 'Find a test: ferritin, complete blood count…';

  @override
  String get basicSet => '+ Basic set';

  @override
  String get basicSetHint =>
      'Blood count, chemistry, urinalysis, glucose, vitamin D';

  @override
  String get testList => 'My test list';

  @override
  String get nearbyLabs => 'Nearby laboratories';

  @override
  String get nearbyDoctors => 'Nearby doctors';

  @override
  String get selectedSpecialists => 'Selected specialties';

  @override
  String get specialistSearch =>
      'Find a specialty: primary care, endocrinology…';

  @override
  String get demoDirectory =>
      'Demo: laboratories, doctors and prices are illustrative. Booking is not connected.';

  @override
  String get bookWebsite => 'Book on website';

  @override
  String get bestChoice => 'Best option';

  @override
  String get lowestPrice => 'Lowest price';

  @override
  String get nearest => 'Nearest';

  @override
  String get whatTests => 'Which results to bring →';

  @override
  String get sharingTitle => 'Share results with a doctor';

  @override
  String get doctorView => 'Open doctor view';

  @override
  String get sharingIntro =>
      'For one-time access a doctor scans a QR code or opens a link. Permanent access uses a registered account. You can revoke access at any time.';

  @override
  String get sharingDemo =>
      'The link and QR code are illustrative. They do not grant access to health records.';

  @override
  String get accessDuration => 'Access duration';

  @override
  String get durationHour => '1 hour';

  @override
  String get durationDay => '24 hours';

  @override
  String get durationWeek => '7 days';

  @override
  String get analysisPeriod => 'Result period';

  @override
  String get allHistory => 'All history';

  @override
  String get whatToShow => 'What to show';

  @override
  String get allSystems => 'All systems';

  @override
  String get selectedSystems => 'Selected systems';

  @override
  String get includeEvents =>
      'Include events and measurements for the selected period';

  @override
  String get copyLink => 'Copy link';

  @override
  String get printPdf => 'Printable PDF';

  @override
  String get shareExample => 'Example QR code';

  @override
  String get account => 'Account';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get accessToMine => 'Who can access my results';

  @override
  String get sharedWithMe => 'Shared with me';

  @override
  String get notifications => 'Notifications';

  @override
  String get appPermissions => 'App permissions';

  @override
  String get support => 'Support';

  @override
  String get supportHint =>
      'Something not working, or have an idea? Let us know.';

  @override
  String get supportSubject => 'Subject';

  @override
  String get supportMessage => 'Message';

  @override
  String get send => 'Send';

  @override
  String get appIntroduction => 'Getting started';

  @override
  String get restartTour => 'Start the introduction again';

  @override
  String get signOut => 'Sign out';

  @override
  String get demoAccount => 'Example profile. No account is connected.';

  @override
  String get noSharedAccess =>
      'Shared access will appear here when accounts are available.';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get heightLabel => 'Height';

  @override
  String get localTitle => 'My records';

  @override
  String get localOnly =>
      'Saved on this device. Cloud sync is not connected yet.';

  @override
  String get localExample => 'View example';

  @override
  String get localBack => 'Back to my records';

  @override
  String get localEmpty => 'No records yet';

  @override
  String get localStart =>
      'Create a profile, then add a lab result, medication course or home measurement.';

  @override
  String get localCreateProfile => 'Create profile';

  @override
  String get localEditProfile => 'Edit profile';

  @override
  String get localAddResult => 'Add manually';

  @override
  String get localAddMedication => 'Add course';

  @override
  String get localAddMeasurement => 'Add measurement';

  @override
  String get localResults => 'Lab results';

  @override
  String get localMedications => 'Medication courses';

  @override
  String get localMeasurements => 'Home measurements';

  @override
  String get localSave => 'Save on device';

  @override
  String get localSaved => 'Saved on device';

  @override
  String get localCancel => 'Cancel';

  @override
  String get localClose => 'Close';

  @override
  String get localEdit => 'Edit';

  @override
  String get localDelete => 'Delete';

  @override
  String get localDeleteQuestion =>
      'Delete this record? Previous revisions will remain in history.';

  @override
  String get localDiscard => 'Close without saving?';

  @override
  String get localDiscardText => 'Your entered changes will not be saved.';

  @override
  String get localKeepEditing => 'Keep editing';

  @override
  String get localLoadError =>
      'Could not open local records. Retry loading. The browser needs persistent storage that safely supports multiple tabs.';

  @override
  String get localSaveError =>
      'Could not save. Your input is still in the form; you can retry.';

  @override
  String get localConflict =>
      'The saved record has changed. Your input remains in this form. Review the saved version, then close this form and refresh the list before editing again.';

  @override
  String get localInvalid => 'Check the entered fields.';

  @override
  String get localRequired => 'This field is required';

  @override
  String get localDateInvalid => 'Enter a valid date as YYYY-MM-DD';

  @override
  String get localDateHint => 'YYYY-MM-DD';

  @override
  String get localOptional => 'Optional';

  @override
  String get localOriginalName => 'Original test name';

  @override
  String get localValue => 'Value as recorded';

  @override
  String get localValueKind => 'Value type';

  @override
  String get localNumeric => 'Numeric';

  @override
  String get localComparison => 'Comparison: <, ≤, >, ≥';

  @override
  String get localQualitative => 'Qualitative answer';

  @override
  String get localMissing => 'No value';

  @override
  String get localValueHint =>
      'Decimal separator, precision and comparison operator are preserved.';

  @override
  String get localValueInvalid => 'Check the value and selected value type';

  @override
  String get localUnit => 'Original unit';

  @override
  String get localReference => 'Original reference';

  @override
  String get localCategory => 'Display group';

  @override
  String get localMethod => 'Method';

  @override
  String get localSpecimen => 'Specimen';

  @override
  String get localNotes => 'Notes';

  @override
  String get localDosage => 'Dosage';

  @override
  String get localSchedule => 'Schedule';

  @override
  String get localPrescribedBy => 'Prescribed by';

  @override
  String get localStartDate => 'Start date';

  @override
  String get localEndDate => 'End date';

  @override
  String get localEndInvalid => 'End date is before start date';

  @override
  String get localMeasurementName => 'Measurement name';

  @override
  String get localSource => 'Device or source';

  @override
  String get localTime => 'Local time (HH:MM)';

  @override
  String get localOffset => 'UTC offset (±HH:MM)';

  @override
  String get localTimeHint =>
      'Leave blank if time is unknown. If entering a time, specify its UTC offset.';

  @override
  String get localTimeInvalid => 'Check time and UTC offset';

  @override
  String get localManual => 'Manually entered and confirmed';

  @override
  String get localNoInterpretation =>
      'References are stored as text. Results are not automatically assessed or merged yet.';

  @override
  String get localHistory => 'Revision history';

  @override
  String get localRevision => 'Revision';

  @override
  String get localDeleted => 'Deleted';

  @override
  String get localActive => 'Active on the selected date';

  @override
  String get localOnDate => 'On date';

  @override
  String get localSearch => 'Search by name, value or laboratory';

  @override
  String get localRefresh => 'Refresh records';

  @override
  String get localHistoryError => 'Could not read history. Try again.';

  @override
  String get deviceAccessWelcome => 'Device access';

  @override
  String get deviceAccessIntro =>
      'Choose what to allow. You can continue without permissions and return when adding a document or choosing a clinic. Camera access is requested when taking a photo.';

  @override
  String get fileAccessExplanation =>
      'Files and photos are accessed through the system picker when you choose a document or photo. The app receives only the selected file.';

  @override
  String get chooseAttachment => 'Choose a file';

  @override
  String get continueToApp => 'Continue';

  @override
  String get accessIntroSaveError =>
      'Could not save your choice. Try continuing again.';

  @override
  String get locationAccessExplanation =>
      'Location is used to choose nearby clinics. Use your device location or enter a city and address manually.';

  @override
  String get locationNotSelected => 'Location not selected';

  @override
  String locationCoordinates(String latitude, String longitude) {
    return 'Coordinates: $latitude, $longitude';
  }

  @override
  String get useCurrentLocation => 'Use my current location';

  @override
  String get deviceAccessBusy => 'Waiting for your device';

  @override
  String get manualLocation => 'Enter location manually';

  @override
  String get manualLocationHint => 'City, street and building';

  @override
  String get locationRequired => 'Enter a city or address';

  @override
  String get useThisLocation => 'Use this address';

  @override
  String get chooseLocation => 'Choose location';

  @override
  String get deviceAccessDenied =>
      'Access was denied. Try again, change the permission in your device settings or choose another method.';

  @override
  String get deviceAccessPermanentlyDenied =>
      'Permission requests are blocked. Change the permission in your device or browser settings. You can enter an address manually.';

  @override
  String get deviceAccessRestricted =>
      'Access is restricted by your device settings. Choose another method.';

  @override
  String get locationServicesDisabled =>
      'Location services are off or unavailable. Enable them in device settings; use HTTPS in a browser. You can also enter an address manually.';

  @override
  String get deviceAccessUnsupported =>
      'This feature is unavailable on this device. Choose another method; you can enter a location manually.';

  @override
  String get attachmentCancelled => 'Selection cancelled. No file was added.';

  @override
  String get locationTimedOut =>
      'Finding your location timed out. Try again or enter an address manually.';

  @override
  String get deviceAccessFailed =>
      'Could not complete the action. Try again or choose another method.';

  @override
  String get openDeviceSettings => 'Open device settings';

  @override
  String get selectedAttachments => 'Selected files';

  @override
  String get removeAttachment => 'Remove selected file';

  @override
  String get attachmentSessionOnly =>
      'Files are selected for this app session. Saving to medical history and processing are not connected yet; select the files again after restarting.';

  @override
  String get cameraUnavailable =>
      'Taking photos is unavailable on this device. Choose a photo from your library or files.';

  @override
  String get directoryLocationPreview =>
      'Your selected location does not yet change the demo addresses and distances.';

  @override
  String introductionStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get introductionProfileTitle => 'Complete your profile';

  @override
  String get introductionProfileBody =>
      'Start with age, sex and height in Profile. Add medications, symptoms and other events as needed to keep your health history together.';

  @override
  String get introductionReportsTitle => 'Add your first test report';

  @override
  String get introductionReportsBody =>
      'The Tests section contains your results. The plus button opens the available ways to add data. Review recognised values against the original report before confirming them.';

  @override
  String get introductionSummaryTitle => 'Explore your results';

  @override
  String get introductionSummaryBody =>
      'Summary brings results together. In the example you can open a body system, select a marker and view its history. Show your doctor opens the section for sharing reports.';

  @override
  String get introductionLabsTitle => 'Compare laboratories';

  @override
  String get introductionLabsBody =>
      'In Laboratories, search for tests and add them to your list. The example compares laboratory prices and locations for that list.';

  @override
  String get introductionDoctorsTitle => 'Find a specialist';

  @override
  String get introductionDoctorsBody =>
      'In Doctors, search for a specialty or a doctor and open a card. It shows the clinic and information about the appointment.';

  @override
  String get introductionAppointmentTitle => 'Plan an appointment';

  @override
  String get introductionAppointmentBody =>
      'The doctor card contains the clinic booking action. In the example it shows a preview; the app does not book an appointment. You can repeat these steps from Settings at any time.';

  @override
  String get introductionNotice =>
      'This introduction shows sections without changing your records. Actions unavailable in this version are labelled in the interface.';

  @override
  String get introductionSkip => 'Skip';

  @override
  String get introductionBack => 'Back';

  @override
  String get introductionNext => 'Next';

  @override
  String get introductionDone => 'Done';

  @override
  String get introductionSaveError =>
      'Could not save completion. Tap Skip or Done again to retry.';

  @override
  String get addManually => 'Add manually';

  @override
  String get terminologyTitle => 'Indicator dictionary';

  @override
  String get terminologyHint =>
      'Link this result to an indicator and unit. Your original text is kept. Linking is optional.';

  @override
  String get terminologyUnknown =>
      'No exact match. Choose a concept or save without linking.';

  @override
  String get terminologyAmbiguous =>
      'Several concepts match. Check the specimen and choose, or leave unlinked.';

  @override
  String terminologySuggestion(String name) {
    return 'Suggested: $name. Select explicitly to link.';
  }

  @override
  String get terminologyChanged =>
      'Source details changed. Choose the concept again if needed.';

  @override
  String get terminologyIndicator => 'Dictionary indicator';

  @override
  String get terminologyUnit => 'Dictionary unit';

  @override
  String get terminologyUnlinked => 'Leave unlinked';

  @override
  String get terminologySelected =>
      'Your selection will be saved with this result. Values and reference ranges are kept as entered.';
}
