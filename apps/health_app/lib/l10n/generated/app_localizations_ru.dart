// Flutter 3.50 gen_l10n still emits deprecated compatibility delegates.
// Keep this exception limited to SDK-generated localization code.
// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Orange of Health';

  @override
  String get summary => 'Сводка';

  @override
  String get results => 'Анализы';

  @override
  String get documents => 'Документы';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Настройки';

  @override
  String get summaryIntro => 'Результаты и медицинская история в одном месте.';

  @override
  String get summaryEmptyTitle => 'Ваша история начинается здесь';

  @override
  String get summaryEmptyMessage =>
      'Пока нет сохранённых результатов. Здесь появятся изменения показателей и контекст к сдаче анализов.';

  @override
  String get openResults => 'Открыть анализы';

  @override
  String get resultsEmptyTitle => 'Анализов пока нет';

  @override
  String get resultsEmptyMessage =>
      'Здесь будет история результатов и динамика показателей. Добавление и сохранение анализов появятся на следующем этапе.';

  @override
  String get documentsEmptyTitle => 'Документов пока нет';

  @override
  String get documentsEmptyMessage =>
      'Здесь будут оригиналы бланков и выписок. Импорт документов пока недоступен.';

  @override
  String get profileEmptyTitle => 'Профиль ещё не заполнен';

  @override
  String get profileEmptyMessage =>
      'Медицинский профиль объединит анализы, события, препараты и домашние измерения одного человека. Редактирование появится на следующем этапе.';

  @override
  String get appearance => 'Язык и оформление';

  @override
  String get preferencesDescription =>
      'Эти настройки сохраняются на устройстве и работают без сети.';

  @override
  String get language => 'Язык интерфейса';

  @override
  String get systemLanguage => 'Как в системе';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get theme => 'Тема';

  @override
  String get systemTheme => 'Системная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get savingPreferences => 'Сохранение настроек';

  @override
  String get preferencesLoadError =>
      'Не удалось загрузить настройки. Используются системные значения. Попробуйте ещё раз.';

  @override
  String get preferencesSaveError =>
      'Не удалось сохранить выбор. Выберите значение ещё раз.';

  @override
  String get retry => 'Повторить';

  @override
  String get returnToSummary => 'Перейти к сводке';

  @override
  String get demoTitle => 'Вы смотрите демо-данные.';

  @override
  String get demoIntro =>
      'Войдите, чтобы загрузить свои анализы и сохранять изменения.';

  @override
  String get signIn => 'Войти';

  @override
  String get previewOnly =>
      'Это демонстрация интерфейса. Вход, сохранение медицинских данных и внешние сервисы пока не подключены.';

  @override
  String get close => 'Закрыть';

  @override
  String get patientOffice => 'Кабинет пациента';

  @override
  String get addAnalysis => 'Добавить анализ';

  @override
  String get labsNav => 'Где сдать';

  @override
  String get doctorsNav => 'Врачи';

  @override
  String get showDoctor => 'Показать врачу';

  @override
  String get latestVisit => 'Последняя сдача';

  @override
  String visitCompare(String date) {
    return 'Сравнить со сдачей $date';
  }

  @override
  String get inRange => 'В норме';

  @override
  String get outOfRange => 'Не в норме';

  @override
  String get notRecently => 'Давно не сдавали';

  @override
  String get allResults => 'Все показатели';

  @override
  String get visitEvents => 'События к сдаче';

  @override
  String eventCount(int count) {
    return '$count событий';
  }

  @override
  String get moreEvents => 'Ещё';

  @override
  String get addEvent => 'Добавить событие';

  @override
  String get measurementDiary => 'Дневник измерений';

  @override
  String get systemsHeading => 'Показатели по системам';

  @override
  String get systemSearch => 'Найти показатель или систему';

  @override
  String shownSystems(int count, int total) {
    return 'Показаны $count из $total систем';
  }

  @override
  String get chooseSystems => 'Выбрать системы';

  @override
  String get showHints => 'Посмотреть подсказки';

  @override
  String get noMatches =>
      'Ничего не найдено. Проверьте написание или поищите по системе.';

  @override
  String get sectionBlood => 'Кровь';

  @override
  String get sectionMetabolism => 'Обмен веществ';

  @override
  String get sectionOrgans => 'Органы';

  @override
  String get sectionImmunity => 'Иммунитет и инфекции';

  @override
  String get systemCarbs => 'Углеводный обмен';

  @override
  String get systemBlood => 'Клинический анализ крови';

  @override
  String get systemLipids => 'Липидный профиль';

  @override
  String get systemVitamins => 'Витамины';

  @override
  String get systemIron => 'Обмен железа';

  @override
  String get systemElectro => 'Электролиты и минералы';

  @override
  String get systemAllergy => 'Аллергологический профиль';

  @override
  String get systemHormones => 'Гормоны';

  @override
  String get systemLiver => 'Печень и белковый обмен';

  @override
  String get systemKidney => 'Почки и пуриновый обмен';

  @override
  String get systemGut => 'ЖКТ и инфекции';

  @override
  String get systemTumor => 'Онкомаркеры';

  @override
  String get systemCoag => 'Коагулограмма';

  @override
  String get systemInflammation => 'Воспаление';

  @override
  String get systemInfections => 'Инфекции';

  @override
  String get systemUrine => 'Общий анализ мочи';

  @override
  String get subCarbs => 'Глюкоза, гликированный гемоглобин, инсулин';

  @override
  String get subBlood => 'Эритроциты, лейкоциты, тромбоциты';

  @override
  String get subLipids => 'Холестерин и его фракции, триглицериды';

  @override
  String get subVitamins => 'D, B12, фолиевая кислота';

  @override
  String get subIron => 'Сывороточное железо, ферритин';

  @override
  String get subElectro => 'Калий, натрий, хлор, магний';

  @override
  String get subAllergy => 'Общий и специфические IgE, IgG';

  @override
  String get subHormones => 'Щитовидная железа, тестостерон';

  @override
  String get subLiver => 'Ферменты печени, билирубин, белок';

  @override
  String get subKidney => 'Креатинин, мочевина, мочевая кислота';

  @override
  String get subGut => 'Helicobacter pylori';

  @override
  String get subTumor => 'ПСА, РЭА, CA 19-9 и другие';

  @override
  String get subCoag => 'МНО, АЧТВ, фибриноген, D-димер';

  @override
  String get subInflammation => 'С-реактивный белок, СОЭ, ревмопробы';

  @override
  String get subInfections => 'ВИЧ, сифилис, гепатиты B и C';

  @override
  String get subUrine => 'Плотность, белок, лейкоциты';

  @override
  String withData(int count, int total) {
    return '$count из $total с данными';
  }

  @override
  String resultCount(int count) {
    return '$count показ.';
  }

  @override
  String abnormalCount(int count) {
    return '$count не в норме';
  }

  @override
  String get allNormal => 'всё в норме';

  @override
  String get noData => 'нет данных';

  @override
  String get notUploaded => 'ещё не загружено';

  @override
  String get noSystemData => 'В загруженных файлах таких анализов нет.';

  @override
  String get fullHistory => 'Полная история всех показателей';

  @override
  String get historySub => '9 сдач · 59 показателей';

  @override
  String get openTable => 'Открыть таблицу';

  @override
  String get sourceDisclaimer =>
      'Сервис показывает только то, что написано в загруженных бланках: значения, единицы и референсные интервалы лабораторий. Он не ставит диагнозов и не даёт рекомендаций. Выводы делает врач.';

  @override
  String get indicator => 'Показатель';

  @override
  String get latestValue => 'Последнее';

  @override
  String get labReference => 'Норма лаборатории';

  @override
  String get previousValue => 'Предыдущее';

  @override
  String get aboveRange => 'выше нормы';

  @override
  String get belowRange => 'ниже нормы';

  @override
  String get resultHistory => 'История значений';

  @override
  String get dateLabel => 'Дата';

  @override
  String get valueLabel => 'Значение';

  @override
  String get originalName => 'Исходное название из бланка';

  @override
  String get uploadTitle => 'Загрузка анализов';

  @override
  String get uploadIntro =>
      'Добавьте бланк из любой лаборатории. Сервис распознает показатели, а вы проверите их перед сохранением. Оригинал файла хранится вместе с результатами.';

  @override
  String get uploadDrop =>
      'Фото бланка, скриншот из приложения лаборатории или PDF из почты.';

  @override
  String get takePhoto => 'Сфотографировать';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get filePdf => 'Файл или PDF';

  @override
  String get uploadPermission =>
      'При первой загрузке приложение попросит доступ к камере, галерее или файлам.';

  @override
  String get photoScreenshot => 'Фото или скриншот';

  @override
  String get photoAdvice =>
      'Сфотографируйте бланк целиком, чтобы были видны дата и нормы.';

  @override
  String get pdfAdvice =>
      'Файл из приложения или личного кабинета лаборатории.';

  @override
  String get forwardMail => 'Переслать письмо';

  @override
  String get mailAdvice => 'Перешлите письмо лаборатории на адрес';

  @override
  String get demoEmail => 'Демонстрационный адрес';

  @override
  String get labLabel => 'Лаборатория';

  @override
  String get statusLabel => 'Статус';

  @override
  String get fileLabel => 'Файл';

  @override
  String get verified => 'Проверено';

  @override
  String get openReport => 'Открыть бланк';

  @override
  String get testReason => 'Повод сдачи';

  @override
  String get profileIntro =>
      'Данные о вас, которые помогают врачу читать анализы. Препараты, вес и болезни показываются на графиках анализов по тем же датам. Сервис сам ничего по профилю не оценивает.';

  @override
  String get profileComplete => 'Профиль заполнен на 100%';

  @override
  String get profileCompleteHint =>
      'Всё заполнено. Обновляйте вес и препараты, когда что-то меняется.';

  @override
  String get profileComplaints => 'Жалобы';

  @override
  String get profileBase => 'Основное';

  @override
  String get profileMedicines => 'Препараты и БАДы';

  @override
  String get profileWeight => 'Вес';

  @override
  String get profileIllness => 'Болезни';

  @override
  String get profileHospital => 'Госпитализации';

  @override
  String get profileAllergies => 'Аллергии';

  @override
  String get profileHistory => 'Анамнез';

  @override
  String get profileLifestyle => 'Образ жизни';

  @override
  String get profileDocuments => 'Документы и исследования';

  @override
  String get profileComplaintsSub => 'Что беспокоит и с какого времени';

  @override
  String get profileBaseSub => 'Пол, возраст, рост';

  @override
  String get profileMedicinesSub => 'Курсы и постоянный приём';

  @override
  String get profileWeightSub => 'Динамика веса';

  @override
  String get profileIllnessSub => 'За последний год: температура, антибиотики';

  @override
  String get profileHospitalSub => 'Когда и где лежали в больнице';

  @override
  String get profileAllergiesSub => 'На что и как проявляется';

  @override
  String get profileHistorySub =>
      'Хронические болезни, операции, травмы, наследственность';

  @override
  String get profileLifestyleSub => 'Спорт, сон, питание, алкоголь';

  @override
  String get profileDocumentsSub => 'ЭКГ, УЗИ, флюорография, КТ, МРТ';

  @override
  String get filled => 'заполнено';

  @override
  String get comingSoon => 'скоро';

  @override
  String get addPhotoTitle => 'Сфотографировать бланк';

  @override
  String get addGalleryTitle => 'Фото или скриншот из галереи';

  @override
  String get addFilesHint => 'Из почты или личного кабинета лаборатории';

  @override
  String get addGalleryHint => 'Например, скриншот из приложения лаборатории';

  @override
  String get addMailTitle => 'Переслать письмо лаборатории';

  @override
  String get labsTitle => 'Где сдать анализы';

  @override
  String get locationExample => 'Санкт-Петербург, Невский пр., 28';

  @override
  String get change => 'Изменить';

  @override
  String get labSearch => 'Найти анализ: ферритин, общий анализ крови…';

  @override
  String get basicSet => '+ Базовый набор';

  @override
  String get basicSetHint =>
      'ОАК, биохимия, общий анализ мочи, глюкоза, витамин D: их смотрят почти все врачи';

  @override
  String get testList => 'Мой список на сдачу';

  @override
  String get nearbyLabs => 'Лаборатории рядом';

  @override
  String get nearbyDoctors => 'Врачи рядом';

  @override
  String get selectedSpecialists => 'Выбранные специалисты';

  @override
  String get specialistSearch => 'Найти специалиста: терапевт, эндокринолог…';

  @override
  String get demoDirectory =>
      'Демо: лаборатории, специалисты и цены условные. Реальная запись пока не подключена.';

  @override
  String get bookWebsite => 'Записаться на сайте';

  @override
  String get bestChoice => 'Оптимально';

  @override
  String get lowestPrice => 'Дешевле всего';

  @override
  String get nearest => 'Ближе всего';

  @override
  String get whatTests => 'Какие анализы взять →';

  @override
  String get sharingTitle => 'Показать анализы специалисту';

  @override
  String get doctorView => 'Открыть вид для врача';

  @override
  String get sharingIntro =>
      'Разовый доступ: специалист сканирует QR-код или открывает ссылку. Регистрация ему не нужна. Если специалисту нужен постоянный доступ, он регистрируется, и вы открываете доступ его аккаунту. Закрыть доступ можно в любой момент.';

  @override
  String get sharingDemo =>
      'Ссылка и QR-код демонстрационные. Доступ к медицинским данным не предоставляется.';

  @override
  String get accessDuration => 'Срок доступа';

  @override
  String get durationHour => '1 час';

  @override
  String get durationDay => '24 часа';

  @override
  String get durationWeek => '7 дней';

  @override
  String get analysisPeriod => 'Период анализов';

  @override
  String get allHistory => 'Вся история';

  @override
  String get whatToShow => 'Что показать';

  @override
  String get allSystems => 'Все системы';

  @override
  String get selectedSystems => 'Выбранные системы';

  @override
  String get includeEvents =>
      'Включить события рядом со сдачами и дневники за выбранный период';

  @override
  String get copyLink => 'Скопировать ссылку';

  @override
  String get printPdf => 'PDF для печати';

  @override
  String get shareExample => 'Пример QR-кода';

  @override
  String get account => 'Аккаунт';

  @override
  String get nameLabel => 'Имя';

  @override
  String get phoneLabel => 'Телефон';

  @override
  String get emailLabel => 'Почта';

  @override
  String get accessToMine => 'У кого есть доступ к моим анализам';

  @override
  String get sharedWithMe => 'Мне открыли доступ';

  @override
  String get notifications => 'Уведомления';

  @override
  String get appPermissions => 'Разрешения приложения';

  @override
  String get support => 'Поддержка';

  @override
  String get supportHint =>
      'Что-то не работает или есть идея? Напишите нам, ответим на почту.';

  @override
  String get supportSubject => 'Тема';

  @override
  String get supportMessage => 'Сообщение';

  @override
  String get send => 'Отправить';

  @override
  String get appIntroduction => 'Знакомство с приложением';

  @override
  String get restartTour => 'Пройти первые шаги заново';

  @override
  String get signOut => 'Выйти из аккаунта';

  @override
  String get demoAccount =>
      'Демонстрационный профиль. Учётная запись не подключена.';

  @override
  String get noSharedAccess =>
      'В рабочей версии здесь появятся предоставленные доступы.';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get heightLabel => 'Рост';

  @override
  String get localTitle => 'Мои записи';

  @override
  String get localOnly =>
      'Сохраняется на этом устройстве. Облачная синхронизация ещё не подключена.';

  @override
  String get localExample => 'Посмотреть пример';

  @override
  String get localBack => 'Вернуться к моим записям';

  @override
  String get localEmpty => 'Пока нет записей';

  @override
  String get localStart =>
      'Создайте профиль, затем добавьте анализ, курс препарата или домашнее измерение.';

  @override
  String get localCreateProfile => 'Создать профиль';

  @override
  String get localEditProfile => 'Редактировать профиль';

  @override
  String get localAddResult => 'Добавить вручную';

  @override
  String get localAddMedication => 'Добавить курс';

  @override
  String get localAddMeasurement => 'Добавить измерение';

  @override
  String get localResults => 'Результаты анализов';

  @override
  String get localMedications => 'Курсы препаратов';

  @override
  String get localMeasurements => 'Домашние измерения';

  @override
  String get localSave => 'Сохранить на устройстве';

  @override
  String get localSaved => 'Сохранено на устройстве';

  @override
  String get localCancel => 'Отмена';

  @override
  String get localClose => 'Закрыть';

  @override
  String get localEdit => 'Изменить';

  @override
  String get localDelete => 'Удалить';

  @override
  String get localDeleteQuestion =>
      'Удалить запись? Предыдущие редакции останутся в истории.';

  @override
  String get localDiscard => 'Закрыть без сохранения?';

  @override
  String get localDiscardText => 'Введённые изменения не будут сохранены.';

  @override
  String get localKeepEditing => 'Продолжить ввод';

  @override
  String get localLoadError =>
      'Не удалось открыть локальные записи. Повторите загрузку. В браузере требуется постоянное хранилище с безопасной работой нескольких вкладок.';

  @override
  String get localSaveError =>
      'Не удалось сохранить. Введённые данные остались в форме; можно повторить.';

  @override
  String get localConflict =>
      'Сохранённая запись уже изменилась. Ваш ввод сохранён в этой форме. Сверьте сохранённую версию, затем закройте форму и обновите список перед новой правкой.';

  @override
  String get localInvalid => 'Проверьте заполненные поля.';

  @override
  String get localRequired => 'Заполните поле';

  @override
  String get localDateInvalid =>
      'Укажите существующую дату в формате ГГГГ-ММ-ДД';

  @override
  String get localDateHint => 'ГГГГ-ММ-ДД';

  @override
  String get localOptional => 'Необязательно';

  @override
  String get localOriginalName => 'Исходное название показателя';

  @override
  String get localValue => 'Значение как в источнике';

  @override
  String get localValueKind => 'Вид значения';

  @override
  String get localNumeric => 'Число';

  @override
  String get localComparison => 'Условие: <, ≤, >, ≥';

  @override
  String get localQualitative => 'Текстовый ответ';

  @override
  String get localMissing => 'Нет значения';

  @override
  String get localValueHint =>
      'Сохраняются запятая, точность и знак сравнения.';

  @override
  String get localValueInvalid => 'Проверьте значение и выбранный вид ответа';

  @override
  String get localUnit => 'Единица как в источнике';

  @override
  String get localReference => 'Референс как в источнике';

  @override
  String get localCategory => 'Группа для отображения';

  @override
  String get localMethod => 'Метод';

  @override
  String get localSpecimen => 'Материал';

  @override
  String get localNotes => 'Примечания';

  @override
  String get localDosage => 'Дозировка';

  @override
  String get localSchedule => 'Режим приёма';

  @override
  String get localPrescribedBy => 'Кем назначено';

  @override
  String get localStartDate => 'Дата начала';

  @override
  String get localEndDate => 'Дата окончания';

  @override
  String get localEndInvalid => 'Дата окончания раньше начала';

  @override
  String get localMeasurementName => 'Что измерено';

  @override
  String get localSource => 'Прибор или источник';

  @override
  String get localTime => 'Местное время (ЧЧ:ММ)';

  @override
  String get localOffset => 'Смещение UTC (±ЧЧ:ММ)';

  @override
  String get localTimeHint =>
      'Если время неизвестно, оставьте пустым. Для времени укажите смещение UTC.';

  @override
  String get localTimeInvalid => 'Проверьте время и смещение UTC';

  @override
  String get localManual => 'Введено и подтверждено вручную';

  @override
  String get localNoInterpretation =>
      'Референсы сохранены как текст. Автоматическая оценка и объединение результатов ещё не выполняются.';

  @override
  String get localHistory => 'История изменений';

  @override
  String get localRevision => 'Редакция';

  @override
  String get localDeleted => 'Удалено';

  @override
  String get localActive => 'Принимается на выбранную дату';

  @override
  String get localOnDate => 'На дату';

  @override
  String get localSearch => 'Поиск по названию, значению или лаборатории';

  @override
  String get localRefresh => 'Обновить записи';

  @override
  String get localHistoryError =>
      'Не удалось прочитать историю. Повторите попытку.';

  @override
  String get deviceAccessWelcome => 'Доступ к возможностям устройства';

  @override
  String get deviceAccessIntro =>
      'Выберите, к чему предоставить доступ. Можно продолжить без разрешений и вернуться к ним при добавлении документа или выборе клиники. Камера запрашивается только при съёмке.';

  @override
  String get fileAccessExplanation =>
      'Доступ к файлам и медиатеке предоставляется при выборе документа или фотографии в системном окне. Приложение получает только выбранный файл.';

  @override
  String get chooseAttachment => 'Выбрать файл';

  @override
  String get continueToApp => 'Продолжить';

  @override
  String get accessIntroSaveError =>
      'Не удалось сохранить выбор. Попробуйте продолжить ещё раз.';

  @override
  String get locationAccessExplanation =>
      'Геолокация нужна для выбора ближайших клиник. Можно определить позицию устройства или указать город и адрес вручную.';

  @override
  String get locationNotSelected => 'Местоположение не выбрано';

  @override
  String locationCoordinates(String latitude, String longitude) {
    return 'Координаты: $latitude, $longitude';
  }

  @override
  String get useCurrentLocation => 'Определить моё местоположение';

  @override
  String get deviceAccessBusy => 'Ожидание ответа устройства';

  @override
  String get manualLocation => 'Местоположение вручную';

  @override
  String get manualLocationHint => 'Город, улица и дом';

  @override
  String get locationRequired => 'Введите город или адрес';

  @override
  String get useThisLocation => 'Использовать этот адрес';

  @override
  String get chooseLocation => 'Выбор местоположения';

  @override
  String get deviceAccessDenied =>
      'Доступ не разрешён. Можно повторить запрос, изменить разрешение в настройках устройства или выбрать другой способ.';

  @override
  String get deviceAccessPermanentlyDenied =>
      'Запрос заблокирован. Измените разрешение в настройках устройства или браузера. Адрес можно ввести вручную.';

  @override
  String get deviceAccessRestricted =>
      'Доступ ограничен настройками устройства. Выберите другой способ.';

  @override
  String get locationServicesDisabled =>
      'Геолокация выключена или недоступна. Включите её в настройках устройства; в браузере используйте HTTPS. Можно ввести адрес вручную.';

  @override
  String get deviceAccessUnsupported =>
      'Эта возможность недоступна на устройстве. Выберите другой способ; местоположение можно указать вручную.';

  @override
  String get attachmentCancelled => 'Выбор отменён. Файл не добавлен.';

  @override
  String get locationTimedOut =>
      'Не удалось определить позицию за отведённое время. Повторите запрос или введите адрес вручную.';

  @override
  String get deviceAccessFailed =>
      'Не удалось выполнить действие. Попробуйте ещё раз или выберите другой способ.';

  @override
  String get openDeviceSettings => 'Открыть настройки устройства';

  @override
  String get selectedAttachments => 'Выбранные файлы';

  @override
  String get removeAttachment => 'Убрать файл из выбора';

  @override
  String get attachmentSessionOnly =>
      'Файлы выбраны на время текущего запуска. Сохранение в медицинскую историю и обработка пока не подключены; после перезапуска потребуется выбрать их заново.';

  @override
  String get cameraUnavailable =>
      'Съёмка недоступна на этом устройстве. Прикрепите фотографию из медиатеки или файлов.';

  @override
  String get directoryLocationPreview =>
      'Выбранное местоположение пока не изменяет демонстрационные адреса и расстояния.';

  @override
  String introductionStep(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get introductionProfileTitle => 'Заполните профиль';

  @override
  String get introductionProfileBody =>
      'Начните с возраста, пола и роста в разделе «Профиль». По мере необходимости добавляйте препараты, жалобы и другие события, чтобы собрать медицинскую историю в одном месте.';

  @override
  String get introductionReportsTitle => 'Добавьте первый анализ';

  @override
  String get introductionReportsBody =>
      'В разделе «Анализы» находятся ваши результаты. Кнопка с плюсом открывает доступные способы добавления данных. Распознанные значения нужно сверить с исходным бланком перед подтверждением.';

  @override
  String get introductionSummaryTitle => 'Посмотрите результаты';

  @override
  String get introductionSummaryBody =>
      'Сводка объединяет результаты. В примере можно открыть систему организма, выбрать показатель и посмотреть историю. Кнопка «Показать врачу» открывает раздел передачи отчётов.';

  @override
  String get introductionLabsTitle => 'Сравните лаборатории';

  @override
  String get introductionLabsBody =>
      'В разделе «Лаборатории» найдите анализы и добавьте их в список. В примере для этого списка можно сравнить цены и расположение лабораторий.';

  @override
  String get introductionDoctorsTitle => 'Найдите специалиста';

  @override
  String get introductionDoctorsBody =>
      'В разделе «Врачи» найдите специальность или врача и откройте карточку. В ней показаны клиника и сведения о приёме.';

  @override
  String get introductionAppointmentTitle => 'Запланируйте приём';

  @override
  String get introductionAppointmentBody =>
      'В карточке врача есть действие для записи в клинику. В примере оно показывает предварительный просмотр, приложение не записывает на приём. Эти шаги можно в любой момент повторить из настроек.';

  @override
  String get introductionNotice =>
      'Знакомство показывает разделы и не изменяет ваши записи. Действия, недоступные в этой версии, отмечены в интерфейсе.';

  @override
  String get introductionSkip => 'Пропустить';

  @override
  String get introductionBack => 'Назад';

  @override
  String get introductionNext => 'Дальше';

  @override
  String get introductionDone => 'Готово';

  @override
  String get introductionSaveError =>
      'Не удалось сохранить завершение. Нажмите «Пропустить» или «Готово» ещё раз, чтобы повторить.';

  @override
  String get addManually => 'Ввести вручную';
}
