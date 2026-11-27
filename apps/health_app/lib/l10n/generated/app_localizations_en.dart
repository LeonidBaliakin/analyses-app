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
  String get previewOnly => 'This feature is not available yet.';

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
  String get profileComplete => '100% complete';

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
  String get profileComplaintsSub => 'Symptoms';

  @override
  String get profileBaseSub => 'Sex, age, height';

  @override
  String get profileMedicinesSub => 'What you take';

  @override
  String get profileWeightSub => 'Weight history';

  @override
  String get profileIllnessSub => 'Illnesses and dates';

  @override
  String get profileHospitalSub => 'Hospital and dates';

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
  String get sharingTitle => 'Share results';

  @override
  String get doctorView => 'Open doctor view';

  @override
  String get sharingIntro =>
      'Send a link or show the QR code to your clinician.';

  @override
  String get sharingDemo => 'Demo · example link and QR code.';

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
  String get accessToMine => 'People I shared with';

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
  String get introductionProfileTitle => 'Start with your profile';

  @override
  String get introductionProfileBody =>
      'Enter your date of birth and height. You can add other details later.';

  @override
  String get introductionReportsTitle => 'Add a test';

  @override
  String get introductionReportsBody =>
      'Upload a photo, screenshot or PDF. Check the values against the report before saving.';

  @override
  String get introductionSummaryTitle => 'Compare results';

  @override
  String get introductionSummaryBody =>
      'The summary shows your latest visit. Open history to compare tests by date.';

  @override
  String get introductionLabsTitle => 'Choose a laboratory';

  @override
  String get introductionLabsBody =>
      'Build a test list and compare laboratories by price and distance.';

  @override
  String get introductionDoctorsTitle => 'Find a specialist';

  @override
  String get introductionDoctorsBody =>
      'See which tests to bring to your appointment. Open the clinic website from the card to book.';

  @override
  String get introductionAppointmentTitle => 'Share your results';

  @override
  String get introductionAppointmentBody =>
      'Show the QR code or send a link at your appointment. Set the access duration here.';

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

  @override
  String get originalsTitle => 'Original documents';

  @override
  String get originalsConnect => 'Connect storage';

  @override
  String get originalsDisconnect => 'Disconnect storage';

  @override
  String get originalsConnectionHint =>
      'Enter the Documents server address and access token. The token is kept only for this app session. Uploads start only when you choose them.';

  @override
  String get originalsEndpoint => 'Server address';

  @override
  String get originalsToken => 'Access token';

  @override
  String get originalsConnectionError =>
      'Check the address and token. HTTPS is required except for a local development server.';

  @override
  String get originalsHint =>
      'Keep the original PDF, PNG or JPEG on this device (up to 20 MiB). Importing does not create medical results or send files to AI. Cloud upload is a separate action.';

  @override
  String get originalsImport => 'Import file';

  @override
  String get originalsTooLarge => 'Choose a non-empty file up to 20 MiB.';

  @override
  String get originalsUnsupported =>
      'Supported originals: PDF, PNG and JPEG. The file type is checked from its bytes.';

  @override
  String get originalsIntegrityError =>
      'Integrity check failed. The original has not been accepted.';

  @override
  String get originalsQuota =>
      'The cloud storage quota is full. The local original is kept.';

  @override
  String get originalsAccess => 'Cloud access is unavailable for this profile.';

  @override
  String get originalsProfileRequired =>
      'Create a local medical profile before importing.';

  @override
  String get originalsFailed =>
      'The operation failed. Your saved local originals are kept; try again.';

  @override
  String get originalsLocalSaved => 'Original saved on this device.';

  @override
  String get originalsCloudSaved => 'Verified original saved in the cloud.';

  @override
  String get originalsVerified =>
      'Downloaded bytes match the original SHA-256.';

  @override
  String get originalsEmpty => 'No originals saved yet.';

  @override
  String get originalsLocal => 'On this device only';

  @override
  String get originalsPending => 'Cloud transfer pending — retry is safe';

  @override
  String get originalsIntegrity => 'File integrity';

  @override
  String get originalsExport => 'Save a local copy';

  @override
  String get originalsUpload => 'Upload to cloud';

  @override
  String get originalsDownloadVerify => 'Download and verify';

  @override
  String get originalsOtherConnection =>
      'Saved through a different connection. Upload again to confirm this storage destination.';

  @override
  String get processingTitle => 'Document draft';

  @override
  String get processingConsent =>
      'Choose where to process this original. Local mode sends nothing to the server. Server mode uses your own server; no external AI API is enabled. All fields require review before medical records are created.';

  @override
  String get processingLocal => 'Process locally';

  @override
  String get processingServer => 'Process on my server';

  @override
  String get processingCancel => 'Cancel processing';

  @override
  String get processingBackground =>
      'You can leave this screen. The job is kept and can be resumed.';

  @override
  String get processingDateRequired =>
      'Enter a complete result date before confirming. An unknown date is never replaced with today.';

  @override
  String get processingUnavailable =>
      'Processing in this mode is unavailable on this device. Review the document manually or choose another mode.';

  @override
  String get processingUploadFirst =>
      'Upload this original to the connected Documents storage before server processing.';

  @override
  String get processingAlreadyConfirmed =>
      'This original already has confirmed records. Edit those records instead of importing it again.';

  @override
  String get processingConflict =>
      'The draft changed elsewhere. Reopen the saved draft before continuing.';

  @override
  String get processingRuntimeChanged =>
      'The processing runtime changed. Start a new run to use the new version.';

  @override
  String get processingEmpty =>
      'No result rows were extracted. Review the OCR text or enter results manually.';

  @override
  String get processingCancelled =>
      'Processing cancelled. Saved originals and drafts are kept.';

  @override
  String get processingFailed =>
      'Processing or saving failed. The original and saved draft are kept. You can retry or review the OCR text.';

  @override
  String get processingRuns => 'Processing runs';

  @override
  String get processingQueued => 'Queued';

  @override
  String get processingOcr => 'Reading document (OCR)';

  @override
  String get processingLlm => 'Extracting fields (LLM)';

  @override
  String get processingReview => 'Draft — review and correct';

  @override
  String get processingConfirmed => 'Records confirmed';

  @override
  String get processingReviewHint =>
      'Check names, values, comparison signs, units, references and dates against the original. Dictionary matches are suggestions until you select them. Excluded rows are not confirmed.';

  @override
  String get processingOcrText => 'Recognized source text';

  @override
  String get processingUnknown => 'Unknown — check the original';

  @override
  String get processingUnbacked =>
      'The AI field differs from the source or combines columns. Check the OCR and fill it in manually.';

  @override
  String processingSourceValue(String value) {
    return 'Extracted source: $value';
  }

  @override
  String get processingSaveDraft => 'Save draft';

  @override
  String get processingConfirm => 'Confirm selected results';

  @override
  String get processingOpen => 'Recognize and review';

  @override
  String get processingImported => 'Confirmed from a document';

  @override
  String get processingManual => 'Review OCR manually';

  @override
  String get processingAddRow => 'Add result';

  @override
  String get reportTitle => 'Period report';

  @override
  String get reportSummary => 'Period summary';

  @override
  String get reportFrom => 'From';

  @override
  String get reportTo => 'Through';

  @override
  String get reportInvalid => 'Enter a valid period: YYYY-MM-DD';

  @override
  String get reportScope =>
      'Results and measurements use their source dates; courses are included when they overlap the period. The full profile is included. Original files are not included.';

  @override
  String get reportNoInterpretation =>
      'Original values and references are preserved without conversion.';

  @override
  String get reportPrevious => 'Previous compatible result in period';

  @override
  String get reportExport => 'Save HTML for viewing and printing';

  @override
  String get reportSaved =>
      'Printable version saved. Open it in a browser and choose Print → Save as PDF.';

  @override
  String get reportExportError => 'Could not save the report. Try again.';

  @override
  String get reportOriginal => 'Original document fragment';

  @override
  String get syncTitle => 'Record synchronization';

  @override
  String get syncScope =>
      'Confirmed records and deletions are synchronized. Local saving works offline. Originals and recognition drafts are separate. Connecting enables exchange and retries while the app is open; the token stays in memory.';

  @override
  String get syncConnect => 'Connect and synchronize';

  @override
  String get syncConnected => 'Connected to record storage';

  @override
  String get syncNow => 'Synchronize / retry';

  @override
  String get syncDisconnect => 'Disconnect';

  @override
  String syncPending(int count) {
    return 'Awaiting server acknowledgement: $count';
  }

  @override
  String syncConflictCount(int count) {
    return 'Edit conflicts: $count';
  }

  @override
  String syncLast(String date) {
    return 'Last completed exchange: $date';
  }

  @override
  String syncRetryAt(String date) {
    return 'Automatic retry after: $date';
  }

  @override
  String get syncUnauthorized =>
      'The token is invalid. Reconnect with a valid token.';

  @override
  String get syncAccess =>
      'The server denied exchange. Local records are preserved.';

  @override
  String get syncAccount =>
      'This local profile is already bound to another record storage or owner.';

  @override
  String get syncServerChanged =>
      'The server history changed or was restored from a different copy. The binding needs review; local data is preserved.';

  @override
  String get syncConflictChanged =>
      'A version changed during selection. Review the refreshed data and try again.';

  @override
  String get syncFailed =>
      'Exchange did not finish. The queue is preserved; you can retry.';

  @override
  String get syncLocalVersion => 'On this device';

  @override
  String get syncRemoteVersion => 'On the server';

  @override
  String get syncDeleted => 'Deleted';

  @override
  String get syncResolveHint =>
      'Both versions remain in history. Choosing the local version after a server deletion restores the record when sent.';

  @override
  String get syncKeepLocal => 'Use local version';

  @override
  String get syncUseServer => 'Use server version';

  @override
  String get reportSaveUnavailable =>
      'Saving a file is unavailable on this device. You can copy the report.';

  @override
  String get reportCopy => 'Copy report';

  @override
  String get reportCopied => 'Report copied';

  @override
  String get reportCopyError => 'Could not copy the report.';

  @override
  String get accountDescription =>
      'Sign in or create an account to connect to the cloud. Local records are available without signing in.';

  @override
  String get accountManage => 'Sign-in and devices';

  @override
  String get accountAction => 'Action';

  @override
  String get accountLogin => 'Sign in';

  @override
  String get accountRegister => 'Create account';

  @override
  String get accountRecover => 'Recover access';

  @override
  String get accountSendCode => 'Send email code';

  @override
  String get accountCode => 'Email code';

  @override
  String get accountCodeSent =>
      'If this request applies to this address, an email has been sent. The 8-digit code expires in 15 minutes. Check your spam folder.';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountPasswordHint => '15–128 characters. Spaces are allowed.';

  @override
  String get accountShowPassword => 'Show password';

  @override
  String get accountHidePassword => 'Hide password';

  @override
  String get accountDeviceName => 'Device name';

  @override
  String get accountThisDevice => 'This device';

  @override
  String get accountResetPassword => 'Reset password';

  @override
  String get accountChangeEmail => 'Change address or request a new code';

  @override
  String get accountRecovered =>
      'Password reset. Previous sessions have ended. Sign in with your new password.';

  @override
  String get accountSecondDeviceHint =>
      'On your second device, sign in with the same email and password, then connect synchronization.';

  @override
  String get accountConnectHint =>
      'Connecting sends confirmed local records to this account and downloads cloud records. Conflicts require your choice.';

  @override
  String get accountConnect => 'Connect records on this device';

  @override
  String get accountReconnect => 'Reconnect synchronization';

  @override
  String get accountDevices => 'Devices and sessions';

  @override
  String get accountRefreshDevices => 'Refresh list';

  @override
  String get accountThisSession => 'current session';

  @override
  String get accountRevoke => 'End session';

  @override
  String get accountLogout => 'Sign out on this device';

  @override
  String get accountLogoutAll => 'End all sessions';

  @override
  String get accountEmailError => 'Enter a valid email address.';

  @override
  String get accountCodeError =>
      'The code is invalid, expired or already used. Check all 8 digits or request a new code.';

  @override
  String get accountCredentialsError => 'Incorrect email or password.';

  @override
  String get accountExists =>
      'This account already exists. Sign in or recover access.';

  @override
  String get accountRateLimited =>
      'Too many attempts. Try again in 15 minutes.';

  @override
  String get accountBindingError =>
      'Could not connect synchronization. Check its status. If local records are already bound to another account or server, connection is blocked to prevent mixing data.';

  @override
  String get accountStorageError =>
      'Signed in, but the session could not be saved to secure storage. You may need to sign in after restarting.';

  @override
  String get accountSessionExpired =>
      'Your session ended or expired. Sign in again. Local records are preserved.';

  @override
  String get accountNetworkError =>
      'Request failed. Check your connection and retry. If the operation already completed, try signing in.';

  @override
  String get cloudTitle => 'Cloud access and quotas';

  @override
  String get cloudRefresh => 'Refresh access and usage';

  @override
  String get cloudEnabled => 'enabled';

  @override
  String get cloudDisabled => 'disabled';

  @override
  String get cloudSync => 'Synchronization';

  @override
  String get cloudStorage => 'Cloud originals';

  @override
  String get cloudProcessing => 'Server recognition';

  @override
  String get cloudUnavailable =>
      'Could not check cloud access and quotas. Try again later. Local data remains available.';

  @override
  String get cloudLastKnown =>
      'The last received values below may be out of date.';

  @override
  String get cloudLocalKept =>
      'Disabled cloud access or a full quota preserves local records, originals and pending uploads.';

  @override
  String get cloudSyncDenied =>
      'Cloud record writes are disabled. Pending changes are kept; existing cloud records can still be downloaded.';

  @override
  String get cloudSyncQuota =>
      'Cloud record limit reached. The local record and pending change are kept.';

  @override
  String get cloudProcessingDenied =>
      'Server recognition is disabled for this account. Available local processing and manual entry remain accessible.';

  @override
  String get cloudProcessingQuota =>
      'The monthly recognition quota is full. Wait for pending jobs or the next month. The original is kept.';

  @override
  String cloudRecordUsage(int used, int limit) {
    return 'Records: $used of $limit';
  }

  @override
  String cloudByteUsage(String used, String reserved, String limit) {
    return 'Bytes: $used; reserved: $reserved; limit: $limit';
  }

  @override
  String cloudJobUsage(int used, int reserved, int limit, String period) {
    return 'For $period: $used of $limit; queued or running: $reserved';
  }

  @override
  String cloudUntil(String date) {
    return 'Access valid until $date';
  }

  @override
  String get confirmCurrentLocation => 'Are you here?';

  @override
  String get confirmLocationYes => 'Yes, I am here';

  @override
  String get enterAnotherLocation => 'No, enter another address';

  @override
  String get locationAddressUnavailable =>
      'Could not find an address for your GPS location. Check the last address or enter a new one manually.';

  @override
  String get locationSaveFailed =>
      'This address is available for this session, but could not be saved on this device. Try selecting it again.';

  @override
  String get searchingAddresses => 'Searching for addresses…';

  @override
  String get addressSuggestionsUnavailable =>
      'Address suggestions are unavailable. You can enter an address manually.';

  @override
  String get addressSuggestionsEmpty =>
      'No addresses found. Refine your search or use the address you entered.';

  @override
  String get addressSearchProvider =>
      'Address lookup: Photon · © OpenStreetMap contributors. Your query or coordinates are sent to the address search service.';

  @override
  String lastLocationAddress(String address) {
    return 'Last address: $address';
  }

  @override
  String get directoryCity => 'City';

  @override
  String get directorySpb => 'Saint Petersburg';

  @override
  String get directoryVoronezh => 'Voronezh';

  @override
  String get directoryNeedPoint =>
      'Could not determine coordinates for this address. Select an address suggestion with a house number or confirm your device location to calculate distances.';

  @override
  String get directorySorted => 'Nearest first · straight-line distance';

  @override
  String get directoryDoctorSearch => 'Doctor, specialty or clinic';

  @override
  String get directoryLabSearch => 'Test, provider or address';

  @override
  String get directorySpecialty => 'Specialty';

  @override
  String get directoryAllSpecialties => 'All specialties';

  @override
  String get directoryTestDetails => 'Panel, specimen and method';

  @override
  String get directorySpecimen => 'Specimen';

  @override
  String get directoryMethod => 'Method';

  @override
  String get directoryComponents => 'Panel components';

  @override
  String get directoryNotPublished => 'Not specified by the source';

  @override
  String get directoryChooseTests => 'Choose tests';

  @override
  String get directoryTestSearchNotice =>
      'Choose a test type. The dictionary groups provider name variants; cards show the original formulations.';

  @override
  String get directoryLinkFailed =>
      'Could not open the link. Copy the website address from the card or use its phone number.';

  @override
  String directoryResults(int count) {
    return 'Results: $count';
  }

  @override
  String directorySnapshot(String date) {
    return 'Doctors and tests: reviewed selection from $date.';
  }

  @override
  String get directoryOutsideCoverage =>
      'This location is outside the pilot search area. Choose an address in Saint Petersburg or Voronezh.';

  @override
  String get directoryEmpty =>
      'No matches in this directory selection. Change your search, city, network or selected tests.';

  @override
  String get directoryCoverage =>
      'A selection of providers in Saint Petersburg and Voronezh. The provider confirms your booking.';

  @override
  String get directoryMapAttribution => 'Geodata © OpenStreetMap contributors';

  @override
  String get directoryUnknownDistance => 'Distance unavailable';

  @override
  String directoryMeters(String value) {
    return '$value m straight-line distance';
  }

  @override
  String directoryKilometers(String value) {
    return '$value km straight-line distance';
  }

  @override
  String get directoryAvailabilityUnknown =>
      'Tests appear in the network catalogue. Confirm availability at this branch.';

  @override
  String get directoryAllTests => 'Test catalogue';

  @override
  String get directorySource => 'Source';

  @override
  String get directoryContactNotice => 'Published provider or network contact.';

  @override
  String get addressEntrySequence =>
      'Start with a city, then choose a street and building.';

  @override
  String get addressEnterStreet => 'City selected. Now enter a street.';

  @override
  String get addressEnterBuilding =>
      'Street selected. Now enter a building number.';

  @override
  String get addressReady =>
      'Address selected. Confirm it using the button below.';

  @override
  String get directoryRefresh => 'Refresh directory';

  @override
  String get directoryRefreshFailed =>
      'Unable to refresh. Showing the last saved version.';

  @override
  String directorySourceChecked(String date) {
    return 'Address checked: $date';
  }

  @override
  String get directoryNetwork => 'Clinic or laboratory network';

  @override
  String get directoryAllNetworks => 'All networks';

  @override
  String directoryPublished(String date) {
    return 'Directory updated: $date';
  }

  @override
  String get directoryPublicationNotice =>
      'Updates add branch addresses. New doctors, services and prices appear after review. Check availability and prices on the provider’s website.';

  @override
  String directoryDoctorChecked(String date) {
    return 'Doctor details checked: $date';
  }

  @override
  String get directoryNetworkPhone =>
      'Network contact number. Specify the branch when calling.';

  @override
  String get directoryPhoneUnavailable =>
      'No phone number listed. Open the provider’s website to contact them.';

  @override
  String get analysisHistory => 'Analysis history';

  @override
  String get historyRecent => 'Latest two visits';

  @override
  String get historyAll => 'All history';

  @override
  String get historyCustom => 'Choose dates';

  @override
  String get historyPeriod => 'Visit period';

  @override
  String get historyRotate => 'Rotate view';

  @override
  String get historyEvents => 'Event timeline';

  @override
  String get historyIllnesses => 'Illnesses';

  @override
  String get historyComplaints => 'Symptoms';

  @override
  String get historyNoEvents => 'No events in this period.';

  @override
  String get historyEmpty =>
      'No results in this period. Change the dates or selected indicators.';

  @override
  String get historySearch => 'Find and select indicators';

  @override
  String get historyReset => 'Reset selection';

  @override
  String get historyScrollBack => 'Scroll to earlier dates';

  @override
  String get historyScrollForward => 'Scroll to later dates';

  @override
  String get historyTableHint =>
      'Select an indicator for details. Scroll dates horizontally.';

  @override
  String get historyPrint => 'Print / PDF';

  @override
  String get sharingAccess => 'Link and QR access';

  @override
  String get sharingOptions => 'Choose what to share';

  @override
  String get profileHelp => 'How this relates to your tests';

  @override
  String get profileHelpBody =>
      'Medications, weight and illnesses appear on timelines beside test dates.';

  @override
  String get profileOverview =>
      'Information about you for your conversation with a doctor.';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get addressCopied => 'Address copied';

  @override
  String get copyFailed =>
      'Could not copy. Select and copy the address manually.';

  @override
  String get historyExportHint =>
      'Save the printable HTML version. Open it in a browser and choose Print → Save as PDF.';

  @override
  String get tourShareTitle => 'Share your tests';

  @override
  String get tourShareBody =>
      'Show a QR code or send a link to a specialist. Access duration and shared data are set separately.';

  @override
  String get tourAddAnalysis => 'Add a test';

  @override
  String get historyOpen => 'Open history';

  @override
  String get visitHistory => 'Test visits';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get manageSharing => 'Manage access in settings';

  @override
  String get history30Days => 'Last 30 days';

  @override
  String get history180Days => 'Last 180 days';

  @override
  String get uploadReviewHint =>
      'Check values against the original report before saving.';

  @override
  String get supportRecognition => 'Report recognition';

  @override
  String get supportBug => 'Application error';

  @override
  String get supportAccess => 'Doctor access';

  @override
  String get supportIdea => 'Idea or suggestion';

  @override
  String get supportOther => 'Other';

  @override
  String get addShort => '+ Add';

  @override
  String get clearSelection => 'Clear all';

  @override
  String get verifyHospitalValidity => 'confirm validity for admission';

  @override
  String get validityFortnight => 'valid for 14 days';

  @override
  String get validityMonth => 'valid for 1 month';

  @override
  String get historyShort => 'History';

  @override
  String get historyLegend => 'Table legend';

  @override
  String get historyPdfActions => 'PDF actions';

  @override
  String get historySavePdf => 'Save PDF';

  @override
  String get historySharePdf => 'Share PDF';

  @override
  String get diaryTileSubtitle => 'Glucose, blood pressure, sleep';

  @override
  String get visitReason => 'Reason:';

  @override
  String get reasonDoctor => 'Prescribed by doctor';

  @override
  String get reasonCheckup => 'Checkup';

  @override
  String get reasonRoutine => 'Routine screening';

  @override
  String get reasonHospital => 'In hospital';

  @override
  String get reasonSanatorium => 'White Nights sanatorium';

  @override
  String get reasonAdd => '+ reason';

  @override
  String get myAnalyses => 'My tests';

  @override
  String get allOption => 'All';

  @override
  String get historyPeriodEvents => 'Events in period';

  @override
  String get durationMonth => '30 days';

  @override
  String get onlyOutsideRange => 'Outside reference only';

  @override
  String get selectedBlocks => 'Selected sections';

  @override
  String get notificationsAndPermissions => 'Notifications and permissions';

  @override
  String get selectedSpecialties => 'Selected specialties';

  @override
  String get testsToTake => 'Tests to take';

  @override
  String get basicTestSet => '+ Basic set';

  @override
  String get directoryFilters => 'Directory filters';

  @override
  String get directoryPriceUnknown => 'Price not published';

  @override
  String get directoryContactsAndSource => 'Contacts and source';

  @override
  String get profileFieldSex => 'Sex';

  @override
  String get profileFieldHeight => 'Height, cm';

  @override
  String get profileFieldWaist => 'Waist, cm';

  @override
  String get profileFieldHips => 'Hips, cm';

  @override
  String get profileFieldChest => 'Chest, cm';

  @override
  String get profileFieldCycle => 'Cycle day at visit';

  @override
  String get profileFieldCity => 'City';

  @override
  String get profileFieldTravel => 'Travel in the last year: where and when';

  @override
  String get profileFieldActivity => 'Sport and physical activity';

  @override
  String get profileFieldSport => 'Type of sport';

  @override
  String get profileFieldFoodNotes => 'Diet details';

  @override
  String get profileFieldStress => 'Stress in the last month';

  @override
  String get profileFieldSleep => 'Average sleep, hours per night';

  @override
  String get profileFieldDiet => 'Diet';

  @override
  String get profileFieldSmoking => 'Smoking';

  @override
  String get profileFieldPacksPerDay => 'Packs per day';

  @override
  String get profileFieldSmokingQuitPrecision => 'When you stopped smoking';

  @override
  String get profileFieldSmokingQuitDate => 'Date';

  @override
  String get profileFieldSmokingQuitYear => 'Approximate year';

  @override
  String get profileFieldAlcohol => 'Alcohol, how often';

  @override
  String get profileFieldAlcoholAmount => 'Alcohol per occasion';

  @override
  String get profileFieldAlcoholQuitPrecision => 'When you stopped drinking';

  @override
  String get profileFieldAlcoholQuitDate => 'Date';

  @override
  String get profileFieldAlcoholQuitYear => 'Approximate year';

  @override
  String get profileSexMale => 'Male';

  @override
  String get profileSexFemale => 'Female';

  @override
  String get profileOptionalMeasures => 'Circumferences · optional';

  @override
  String get profileAddRecord => '+ Add entry';

  @override
  String get profileDescription => 'Description';

  @override
  String get profileWhen => 'When';

  @override
  String get profileUnknownDate => 'Date unknown';

  @override
  String get profileExactDate => 'Exact date';

  @override
  String get profileApproximateYear => 'Approximate year';

  @override
  String get profileChildhood => 'Since childhood';

  @override
  String get profileRemoveEntry => 'Remove entry';

  @override
  String get profileChronic => 'Chronic conditions';

  @override
  String get profileSurgery => 'Surgery and injuries';

  @override
  String get profileFamily => 'Hereditary and genetic conditions';

  @override
  String get profileOtherHistory => 'Other information for your doctor';

  @override
  String get profileActivity1 => 'Little activity, sedentary work';

  @override
  String get profileActivity2 => '1–2 workouts or walks a week';

  @override
  String get profileActivity3 => '3–4 workouts a week';

  @override
  String get profileActivity4 => '5+ workouts or physical work';

  @override
  String get profileNo => 'No';

  @override
  String get profileSometimes => 'Yes, sometimes';

  @override
  String get profileOften => 'Yes, almost constantly';

  @override
  String get profileDietNormal => 'Regular';

  @override
  String get profileDietVegetarian => 'Vegetarian';

  @override
  String get profileDietVegan => 'Vegan';

  @override
  String get profileDietKeto => 'Low carbohydrate / keto';

  @override
  String get profileDietFasting => 'Intermittent fasting';

  @override
  String get profileNeverSmoked => 'Do not smoke';

  @override
  String get profileSmokes => 'Smoke';

  @override
  String get profileFormerSmoker => 'Stopped smoking';

  @override
  String get profileNoAlcohol => 'Do not drink';

  @override
  String get profileFormerDrinker => 'Previously drank';

  @override
  String get profileAlcoholRare => 'Less than weekly';

  @override
  String get profileAlcoholWeekly => '1–3 times a week';

  @override
  String get profileAlcoholOften => 'More often';

  @override
  String get profilePacksHalf => 'Half a pack';

  @override
  String get profileNotStated => 'Not stated';

  @override
  String get profileEventName => 'What happened';

  @override
  String get profileFrom => 'From';

  @override
  String get profileTo => 'To';

  @override
  String get profileTemperature => 'Maximum temperature, °C (optional)';

  @override
  String get profileInstitution => 'Where';

  @override
  String get profileOutcomes => 'Hospitalization outcome';

  @override
  String get profileReaction => 'Reaction';

  @override
  String get profileAdd => 'Add';

  @override
  String get profileSave => 'Save';

  @override
  String get medicationExperience => 'Course experience';

  @override
  String get medicationFirstCourse => 'First course';

  @override
  String get medicationRepeatCourse => 'Repeat course';

  @override
  String get medicationUnknownCourse => 'Do not remember';

  @override
  String get medicationReason => 'Reason for prescription';

  @override
  String profileFilledPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String profileEntries(int count) {
    return '$count entries';
  }

  @override
  String get tourOpenBasics => 'Open basic details';

  @override
  String get tourOpenUpload => 'Open upload options';

  @override
  String get otherRecords => 'Other records';

  @override
  String get pdfUnit => 'Unit';

  @override
  String get pdfReference => 'Reference';

  @override
  String get captureWhat => 'What happened?';

  @override
  String get captureHint => 'Describe what happened…';

  @override
  String get captureDictate => 'Dictate';

  @override
  String get captureExample => 'View example';

  @override
  String get captureCheck => 'Review entries';

  @override
  String get captureReview => 'Review entries';

  @override
  String get captureSource => 'Original story';

  @override
  String get captureConfirm => 'Confirm and save';

  @override
  String get captureVoiceHint =>
      'Use your device keyboard dictation or type your story.';

  @override
  String get captureLocalHint =>
      'Local draft. Check names, dates and sections before saving.';

  @override
  String get captureMissingDate =>
      'Specify the date: the year is missing or the date was not recognized.';

  @override
  String get captureKind => 'Section';

  @override
  String get captureIllness => 'Illness';

  @override
  String get captureMedication => 'Medication';

  @override
  String get captureHospital => 'Hospitalization';

  @override
  String get captureComplaint => 'Symptom';

  @override
  String get captureWeight => 'Weight';

  @override
  String get captureAllergy => 'Allergy';

  @override
  String get captureTravel => 'Travel';

  @override
  String get captureSample =>
      'I was ill with flu on 10.11.2026; taking vitamin D from 11.11.2026. A trip to a health resort.';

  @override
  String get medicationMode => 'Course mode';

  @override
  String get medicationConstant => 'Ongoing';

  @override
  String get medicationCourse => 'Course';

  @override
  String get diaryWhat => 'What did you measure?';

  @override
  String get diaryGlucose => 'Blood glucose';

  @override
  String get diaryPressure => 'Blood pressure';

  @override
  String get diarySleep => 'Sleep';

  @override
  String get diaryGlucoseValue => 'Glucose, mmol/L';

  @override
  String get diarySystolic => 'Systolic, mmHg';

  @override
  String get diaryDiastolic => 'Diastolic, mmHg';

  @override
  String get diarySleepValue => 'Duration, h';

  @override
  String get diarySave => 'Save measurement';

  @override
  String get diaryEntries => 'Entries';

  @override
  String get diaryEmpty => 'No entries yet.';

  @override
  String get selectPrint => 'Select for printing';

  @override
  String get printSelected => 'Print selected';

  @override
  String get medicationActive => 'taking';

  @override
  String get medicationCompleted => 'completed';

  @override
  String get guestCaption => 'Guest · example data';

  @override
  String get signInRegister => 'Sign in or register';

  @override
  String get labShort => 'Lab';

  @override
  String get reasonDoctorShort => 'Doctor prescribed';

  @override
  String get captureMedicationName => 'Medication and dosage';

  @override
  String get captureIllnessName => 'Illness';

  @override
  String get captureComplaintName => 'What is bothering you';

  @override
  String get captureHospitalName => 'Reason for hospitalization';

  @override
  String get captureAllergyName => 'Allergic to';

  @override
  String get captureStartDate => 'Start date';

  @override
  String get captureEndDate => 'End date';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get chooseTime => 'Choose time';
}
