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
  String get supportSubject => 'Тема обращения';

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
      'Укажите дату рождения и рост. Остальные данные можно внести позже.';

  @override
  String get introductionReportsTitle => 'Добавьте первый анализ';

  @override
  String get introductionReportsBody =>
      'В разделе «Анализы» находятся ваши результаты. Кнопка с плюсом открывает доступные способы добавления данных. Распознанные значения нужно сверить с исходным бланком перед подтверждением.';

  @override
  String get introductionSummaryTitle => 'Посмотрите результаты';

  @override
  String get introductionSummaryBody =>
      'На сводке видна последняя сдача. В истории можно сравнить анализы по датам, выбрать показатели и посмотреть события.';

  @override
  String get introductionLabsTitle => 'Сравните лаборатории';

  @override
  String get introductionLabsBody =>
      'В разделе «Где сдать» найдите анализы или учреждение в Санкт-Петербурге и Воронеже. Выберите адрес или геолокацию, чтобы увидеть ближайшие филиалы. Доступность анализов из каталога сети уточняйте в филиале.';

  @override
  String get introductionDoctorsTitle => 'Найдите специалиста';

  @override
  String get introductionDoctorsBody =>
      'В разделе «Врачи» найдите специальность или врача и откройте карточку. В ней показаны клиника и сведения о приёме.';

  @override
  String get introductionAppointmentTitle => 'Запланируйте приём';

  @override
  String get introductionAppointmentBody =>
      'Карточка содержит сайт записи и телефон учреждения. Запись подтверждается клиникой. Повторить знакомство можно в настройках.';

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

  @override
  String get terminologyTitle => 'Словарь показателей';

  @override
  String get terminologyHint =>
      'Выберите показатель и единицу для этого результата. Исходный текст сохранится. Привязка необязательна.';

  @override
  String get terminologyUnknown =>
      'Точного совпадения нет. Выберите понятие или сохраните без привязки.';

  @override
  String get terminologyAmbiguous =>
      'Найдено несколько понятий. Уточните материал и выберите показатель или оставьте без привязки.';

  @override
  String terminologySuggestion(String name) {
    return 'Возможное соответствие: $name. Для привязки выберите его явно.';
  }

  @override
  String get terminologyChanged =>
      'Исходные сведения изменены. При необходимости выберите понятие заново.';

  @override
  String get terminologyIndicator => 'Показатель из словаря';

  @override
  String get terminologyUnit => 'Единица из словаря';

  @override
  String get terminologyUnlinked => 'Без привязки';

  @override
  String get terminologySelected =>
      'Выбор сохранится вместе с результатом. Значение и референсы останутся в исходном виде.';

  @override
  String get originalsTitle => 'Оригиналы документов';

  @override
  String get originalsConnect => 'Подключить хранилище';

  @override
  String get originalsDisconnect => 'Отключить хранилище';

  @override
  String get originalsConnectionHint =>
      'Введите адрес сервера Documents и токен доступа. Токен хранится только на время работы приложения. Передача начнётся только по вашему действию.';

  @override
  String get originalsEndpoint => 'Адрес сервера';

  @override
  String get originalsToken => 'Токен доступа';

  @override
  String get originalsConnectionError =>
      'Проверьте адрес и токен. Нужен HTTPS, кроме локального сервера разработки.';

  @override
  String get originalsHint =>
      'Сохраните исходный PDF, PNG или JPEG на устройстве (до 20 МиБ). Импорт не создаёт результаты анализов и не отправляет файлы в AI. Загрузка в облако выполняется отдельно.';

  @override
  String get originalsImport => 'Импортировать файл';

  @override
  String get originalsTooLarge => 'Выберите непустой файл размером до 20 МиБ.';

  @override
  String get originalsUnsupported =>
      'Поддерживаются PDF, PNG и JPEG. Тип проверяется по исходным байтам.';

  @override
  String get originalsIntegrityError =>
      'Проверка целостности не пройдена. Оригинал не принят.';

  @override
  String get originalsQuota =>
      'Облачная квота исчерпана. Локальный оригинал сохранён.';

  @override
  String get originalsAccess => 'Облачный доступ для этого профиля недоступен.';

  @override
  String get originalsProfileRequired =>
      'Перед импортом создайте локальный медицинский профиль.';

  @override
  String get originalsFailed =>
      'Операция не выполнена. Сохранённые локальные оригиналы не потеряны; повторите попытку.';

  @override
  String get originalsLocalSaved => 'Оригинал сохранён на устройстве.';

  @override
  String get originalsCloudSaved => 'Проверенный оригинал сохранён в облаке.';

  @override
  String get originalsVerified =>
      'Скачанные байты совпадают с SHA-256 оригинала.';

  @override
  String get originalsEmpty => 'Сохранённых оригиналов пока нет.';

  @override
  String get originalsLocal => 'Только на устройстве';

  @override
  String get originalsPending =>
      'Передача в облако ожидает повтора — повтор безопасен';

  @override
  String get originalsIntegrity => 'Целостность файла';

  @override
  String get originalsExport => 'Сохранить локальную копию';

  @override
  String get originalsUpload => 'Загрузить в облако';

  @override
  String get originalsDownloadVerify => 'Скачать и проверить';

  @override
  String get originalsOtherConnection =>
      'Сохранён через другое подключение. Для текущего хранилища загрузите оригинал заново.';

  @override
  String get processingTitle => 'Черновик документа';

  @override
  String get processingConsent =>
      'Выберите место обработки оригинала. Локальный режим не отправляет документ на сервер. Серверный режим использует ваш сервер; внешний AI API не включён. Медицинские записи создаются только после вашей проверки.';

  @override
  String get processingLocal => 'Обработать локально';

  @override
  String get processingServer => 'Обработать на своём сервере';

  @override
  String get processingCancel => 'Отменить обработку';

  @override
  String get processingBackground =>
      'Экран можно закрыть. Задание сохранено, к нему можно вернуться.';

  @override
  String get processingDateRequired =>
      'Перед подтверждением укажите полную дату результата. Неизвестная дата не заменяется сегодняшней.';

  @override
  String get processingUnavailable =>
      'Обработка в выбранном режиме недоступна на этом устройстве. Можно проверить документ вручную или выбрать другой режим.';

  @override
  String get processingUploadFirst =>
      'Перед серверной обработкой загрузите оригинал в подключённое хранилище Documents.';

  @override
  String get processingAlreadyConfirmed =>
      'Для этого оригинала уже созданы подтверждённые записи. Исправьте их вместо повторного импорта.';

  @override
  String get processingConflict =>
      'Черновик изменён в другом месте. Откройте сохранённую редакцию перед продолжением.';

  @override
  String get processingRuntimeChanged =>
      'Версия обработки изменилась. Для новой версии запустите новый разбор.';

  @override
  String get processingEmpty =>
      'Строки результатов не найдены. Проверьте OCR-текст или добавьте результаты вручную.';

  @override
  String get processingCancelled =>
      'Обработка отменена. Оригинал и сохранённые черновики не удалены.';

  @override
  String get processingFailed =>
      'Обработка или сохранение не выполнены. Оригинал и сохранённый черновик остаются доступны. Повторите действие или проверьте OCR-текст.';

  @override
  String get processingRuns => 'Запуски обработки';

  @override
  String get processingQueued => 'В очереди';

  @override
  String get processingOcr => 'Чтение документа (OCR)';

  @override
  String get processingLlm => 'Извлечение полей (LLM)';

  @override
  String get processingReview => 'Черновик — проверьте и исправьте';

  @override
  String get processingConfirmed => 'Записи подтверждены';

  @override
  String get processingReviewHint =>
      'Сверьте названия, значения, знаки сравнения, единицы, референсы и даты с оригиналом. Соответствия словаря остаются предложениями до вашего выбора. Исключённые строки не подтверждаются.';

  @override
  String get processingOcrText => 'Распознанный исходный текст';

  @override
  String get processingUnknown => 'Неизвестно — проверьте оригинал';

  @override
  String get processingUnbacked =>
      'Поле AI не совпало с исходным текстом или смешивает столбцы. Проверьте OCR и заполните поле вручную.';

  @override
  String processingSourceValue(String value) {
    return 'Исходное извлечение: $value';
  }

  @override
  String get processingSaveDraft => 'Сохранить черновик';

  @override
  String get processingConfirm => 'Подтвердить выбранные результаты';

  @override
  String get processingOpen => 'Распознать и проверить';

  @override
  String get processingImported => 'Подтверждено из документа';

  @override
  String get processingManual => 'Заполнить по тексту вручную';

  @override
  String get processingAddRow => 'Добавить результат';

  @override
  String get reportTitle => 'Отчёт за период';

  @override
  String get reportSummary => 'Сводка за период';

  @override
  String get reportFrom => 'Начало периода';

  @override
  String get reportTo => 'Конец периода';

  @override
  String get reportInvalid => 'Укажите допустимый период: ГГГГ-ММ-ДД';

  @override
  String get reportScope =>
      'Результаты и измерения включены по исходной дате; курсы — при пересечении периода. Профиль приведён целиком. Файлы оригиналов не включены.';

  @override
  String get reportNoInterpretation =>
      'Исходные значения и референсы приведены без преобразований.';

  @override
  String get reportPrevious => 'Предыдущее сопоставимое в периоде';

  @override
  String get reportExport => 'Сохранить HTML для просмотра и печати';

  @override
  String get reportSaved =>
      'Печатная версия сохранена. Откройте её в браузере и выберите «Печать → Сохранить как PDF».';

  @override
  String get reportExportError =>
      'Не удалось сохранить отчёт. Повторите попытку.';

  @override
  String get reportOriginal => 'Исходный фрагмент документа';

  @override
  String get syncTitle => 'Синхронизация записей';

  @override
  String get syncScope =>
      'Синхронизируются подтверждённые записи и удаления. Локальное сохранение работает без сети. Оригиналы и черновики распознавания передаются отдельно. Подключение включает обмен и повторы, пока приложение открыто; токен хранится только в памяти.';

  @override
  String get syncConnect => 'Подключить и синхронизировать';

  @override
  String get syncConnected => 'Подключено к облаку записей';

  @override
  String get syncNow => 'Синхронизировать / повторить';

  @override
  String get syncDisconnect => 'Отключить';

  @override
  String syncPending(int count) {
    return 'Ожидают подтверждения сервера: $count';
  }

  @override
  String syncConflictCount(int count) {
    return 'Конфликтов правок: $count';
  }

  @override
  String syncLast(String date) {
    return 'Последний завершённый обмен: $date';
  }

  @override
  String syncRetryAt(String date) {
    return 'Автоматический повтор после: $date';
  }

  @override
  String get syncUnauthorized =>
      'Токен недействителен. Подключитесь с действующим токеном.';

  @override
  String get syncAccess =>
      'Сервер не разрешил обмен. Локальные записи сохранены.';

  @override
  String get syncAccount =>
      'Этот локальный профиль уже связан с другим облачным хранилищем или владельцем.';

  @override
  String get syncServerChanged =>
      'История сервера изменилась или восстановлена из другой копии. Нужна проверка привязки; локальные данные сохранены.';

  @override
  String get syncConflictChanged =>
      'Версия изменилась во время выбора. Проверьте обновлённые данные и повторите.';

  @override
  String get syncFailed =>
      'Обмен не завершён. Очередь сохранена; можно повторить отправку.';

  @override
  String get syncLocalVersion => 'На этом устройстве';

  @override
  String get syncRemoteVersion => 'На сервере';

  @override
  String get syncDeleted => 'Удалено';

  @override
  String get syncResolveHint =>
      'Обе версии сохранены в истории. Выбор локальной версии после удаления на сервере восстановит запись при отправке.';

  @override
  String get syncKeepLocal => 'Использовать локальную версию';

  @override
  String get syncUseServer => 'Использовать версию сервера';

  @override
  String get reportSaveUnavailable =>
      'Выбор файла для сохранения на этом устройстве недоступен. Можно скопировать отчёт.';

  @override
  String get reportCopy => 'Скопировать отчёт';

  @override
  String get reportCopied => 'Отчёт скопирован';

  @override
  String get reportCopyError => 'Не удалось скопировать отчёт.';

  @override
  String get accountDescription =>
      'Войдите или создайте аккаунт для подключения облака. Локальные записи доступны без входа.';

  @override
  String get accountManage => 'Вход и устройства';

  @override
  String get accountAction => 'Действие';

  @override
  String get accountLogin => 'Войти';

  @override
  String get accountRegister => 'Создать аккаунт';

  @override
  String get accountRecover => 'Восстановить доступ';

  @override
  String get accountSendCode => 'Отправить код на email';

  @override
  String get accountCode => 'Код из письма';

  @override
  String get accountCodeSent =>
      'Если запрос применим к этому адресу, письмо отправлено. Код из 8 цифр действует 15 минут. Проверьте папку «Спам».';

  @override
  String get accountPassword => 'Пароль';

  @override
  String get accountNewPassword => 'Новый пароль';

  @override
  String get accountPasswordHint =>
      'От 15 до 128 символов. Можно использовать пробелы.';

  @override
  String get accountShowPassword => 'Показать пароль';

  @override
  String get accountHidePassword => 'Скрыть пароль';

  @override
  String get accountDeviceName => 'Название устройства';

  @override
  String get accountThisDevice => 'Это устройство';

  @override
  String get accountResetPassword => 'Изменить пароль';

  @override
  String get accountChangeEmail => 'Изменить адрес или запросить новый код';

  @override
  String get accountRecovered =>
      'Пароль изменён, прежние сессии завершены. Войдите с новым паролем.';

  @override
  String get accountSecondDeviceHint =>
      'На втором устройстве войдите с тем же email и паролем, затем подключите синхронизацию.';

  @override
  String get accountConnectHint =>
      'Подключение отправит подтверждённые локальные записи в этот аккаунт и получит облачные. Конфликты потребуют вашего выбора.';

  @override
  String get accountConnect => 'Подключить записи этого устройства';

  @override
  String get accountReconnect => 'Подключить синхронизацию повторно';

  @override
  String get accountDevices => 'Устройства и сессии';

  @override
  String get accountRefreshDevices => 'Обновить список';

  @override
  String get accountThisSession => 'текущая сессия';

  @override
  String get accountRevoke => 'Завершить сессию';

  @override
  String get accountLogout => 'Выйти на этом устройстве';

  @override
  String get accountLogoutAll => 'Завершить все сессии';

  @override
  String get accountEmailError => 'Укажите корректный email.';

  @override
  String get accountCodeError =>
      'Код неверен, истёк или уже использован. Проверьте 8 цифр или запросите новый.';

  @override
  String get accountCredentialsError => 'Email или пароль неверен.';

  @override
  String get accountExists =>
      'Аккаунт уже существует. Войдите или восстановите доступ.';

  @override
  String get accountRateLimited =>
      'Слишком много попыток. Повторите через 15 минут.';

  @override
  String get accountBindingError =>
      'Не удалось подключить синхронизацию. Проверьте её состояние. Если локальные записи уже связаны с другим аккаунтом или сервером, подключение блокируется, чтобы не смешать данные.';

  @override
  String get accountStorageError =>
      'Вход выполнен, но не удалось сохранить сессию в защищённом хранилище. После перезапуска может потребоваться повторный вход.';

  @override
  String get accountSessionExpired =>
      'Сессия завершена или истекла. Войдите снова. Локальные записи сохранены.';

  @override
  String get accountNetworkError =>
      'Не удалось выполнить запрос. Проверьте соединение и повторите. Если операция уже завершилась, попробуйте войти.';

  @override
  String get cloudTitle => 'Облачные возможности и квоты';

  @override
  String get cloudRefresh => 'Обновить права и расход';

  @override
  String get cloudEnabled => 'доступно';

  @override
  String get cloudDisabled => 'недоступно';

  @override
  String get cloudSync => 'Синхронизация';

  @override
  String get cloudStorage => 'Оригиналы в облаке';

  @override
  String get cloudProcessing => 'Серверное распознавание';

  @override
  String get cloudUnavailable =>
      'Не удалось проверить облачные права и квоты. Повторите позже. Локальные данные доступны.';

  @override
  String get cloudLastKnown =>
      'Ниже — последние полученные данные; они могут быть устаревшими.';

  @override
  String get cloudLocalKept =>
      'Отказ облачного доступа или исчерпание квоты сохраняет локальные записи, оригиналы и очередь отправки.';

  @override
  String get cloudSyncDenied =>
      'Отправка записей в облако недоступна. Очередь сохранена; уже загруженные записи можно получать.';

  @override
  String get cloudSyncQuota =>
      'Достигнут лимит облачных записей. Локальная запись и очередь сохранены.';

  @override
  String get cloudProcessingDenied =>
      'Серверное распознавание недоступно для аккаунта. Локальная обработка и ручной ввод остаются доступны.';

  @override
  String get cloudProcessingQuota =>
      'Месячная квота распознавания занята. Дождитесь завершения заданий или следующего месяца. Оригинал сохранён.';

  @override
  String cloudRecordUsage(int used, int limit) {
    return 'Записей: $used из $limit';
  }

  @override
  String cloudByteUsage(String used, String reserved, String limit) {
    return 'Байтов: $used, зарезервировано: $reserved, лимит: $limit';
  }

  @override
  String cloudJobUsage(int used, int reserved, int limit, String period) {
    return 'За $period: $used из $limit, в очереди или работе: $reserved';
  }

  @override
  String cloudUntil(String date) {
    return 'Права действуют до $date';
  }

  @override
  String get confirmCurrentLocation => 'Вы находитесь здесь?';

  @override
  String get confirmLocationYes => 'Да, я здесь';

  @override
  String get enterAnotherLocation => 'Нет, указать другой адрес';

  @override
  String get locationAddressUnavailable =>
      'Не удалось определить адрес по GPS. Проверьте последний адрес или введите новый вручную.';

  @override
  String get locationSaveFailed =>
      'Адрес действует в этом сеансе, но сохранить его на устройстве не удалось. Повторите выбор адреса.';

  @override
  String get searchingAddresses => 'Ищем адреса…';

  @override
  String get addressSuggestionsUnavailable =>
      'Подсказки адресов недоступны. Можно ввести адрес вручную.';

  @override
  String get addressSuggestionsEmpty =>
      'Адреса не найдены. Уточните запрос или используйте введённый адрес.';

  @override
  String get addressSearchProvider =>
      'Подсказки и адрес по GPS: Photon · © OpenStreetMap contributors. Запрос или координаты передаются сервису поиска адресов.';

  @override
  String lastLocationAddress(String address) {
    return 'Последний адрес: $address';
  }

  @override
  String get directoryCity => 'Город';

  @override
  String get directorySpb => 'Санкт-Петербург';

  @override
  String get directoryVoronezh => 'Воронеж';

  @override
  String get directoryNeedPoint =>
      'Координаты этого адреса не определены. Для расчёта расстояния выберите подсказку с номером дома или подтвердите геолокацию.';

  @override
  String get directorySorted => 'Сначала ближайшие · расстояние по прямой';

  @override
  String get directoryDoctorSearch => 'Врач, специальность или клиника';

  @override
  String get directoryLabSearch => 'Анализ, учреждение или адрес';

  @override
  String get directorySpecialty => 'Специальность';

  @override
  String get directoryAllSpecialties => 'Все специальности';

  @override
  String get directoryTestDetails => 'Состав, материал и метод';

  @override
  String get directorySpecimen => 'Материал';

  @override
  String get directoryMethod => 'Метод';

  @override
  String get directoryComponents => 'Состав';

  @override
  String get directoryNotPublished => 'Не уточнён источником';

  @override
  String get directoryChooseTests => 'Выбрать анализы';

  @override
  String get directoryTestSearchNotice =>
      'Выберите тип анализа. Варианты названий лабораторий объединены по словарю; в карточках показаны исходные формулировки.';

  @override
  String get directoryLinkFailed =>
      'Не удалось открыть ссылку. Скопируйте адрес сайта из карточки или позвоните по указанному номеру.';

  @override
  String directoryResults(int count) {
    return 'Найдено: $count';
  }

  @override
  String directorySnapshot(String date) {
    return 'Врачи и исследования: проверенная подборка от $date.';
  }

  @override
  String get directoryOutsideCoverage =>
      'Точка находится за пределами пилотного поиска. Выберите адрес в Санкт-Петербурге или Воронеже.';

  @override
  String get directoryEmpty =>
      'Совпадений в текущей подборке нет. Измените поиск, город, сеть или список анализов.';

  @override
  String get directoryCoverage =>
      'Подборка учреждений Санкт-Петербурга и Воронежа. Запись подтверждается на стороне учреждения.';

  @override
  String get directoryMapAttribution =>
      'Геоданные © OpenStreetMap contributors';

  @override
  String get directoryUnknownDistance => 'Расстояние не определено';

  @override
  String directoryMeters(String value) {
    return '$value м по прямой';
  }

  @override
  String directoryKilometers(String value) {
    return '$value км по прямой';
  }

  @override
  String get directoryAvailabilityUnknown =>
      'Анализы найдены в каталоге сети. Доступность в этом филиале нужно уточнить.';

  @override
  String get directoryAllTests => 'Каталог анализов';

  @override
  String get directorySource => 'Источник';

  @override
  String get directoryContactNotice =>
      'Указан опубликованный контакт учреждения или сети.';

  @override
  String get addressEntrySequence =>
      'Начните с города, затем выберите улицу и дом.';

  @override
  String get addressEnterStreet => 'Город выбран. Теперь введите улицу.';

  @override
  String get addressEnterBuilding =>
      'Улица выбрана. Теперь введите номер дома.';

  @override
  String get addressReady => 'Адрес выбран. Подтвердите его кнопкой ниже.';

  @override
  String get directoryRefresh => 'Обновить каталог';

  @override
  String get directoryRefreshFailed =>
      'Обновление недоступно. Показана последняя сохранённая версия.';

  @override
  String directorySourceChecked(String date) {
    return 'Адрес проверен: $date';
  }

  @override
  String get directoryNetwork => 'Сеть клиник или лабораторий';

  @override
  String get directoryAllNetworks => 'Все сети';

  @override
  String directoryPublished(String date) {
    return 'Каталог обновлён: $date';
  }

  @override
  String get directoryPublicationNotice =>
      'Обновление добавляет адреса филиалов. Новые врачи, услуги и цены появляются после проверки. Наличие и стоимость уточняйте на сайте учреждения.';

  @override
  String directoryDoctorChecked(String date) {
    return 'Данные врача проверены: $date';
  }

  @override
  String get directoryNetworkPhone =>
      'Общий номер сети. Уточните нужный филиал при звонке.';

  @override
  String get directoryPhoneUnavailable =>
      'Телефон не указан. Для связи откройте сайт учреждения.';

  @override
  String get analysisHistory => 'История анализов';

  @override
  String get historyRecent => 'Две последние';

  @override
  String get historyAll => 'Вся история';

  @override
  String get historyCustom => 'Выбрать даты';

  @override
  String get historyPeriod => 'Период сдач';

  @override
  String get historyRotate => 'Повернуть просмотр';

  @override
  String get historyEvents => 'График событий';

  @override
  String get historyIllnesses => 'Болезни';

  @override
  String get historyComplaints => 'Жалобы';

  @override
  String get historyNoEvents => 'За выбранный период событий нет.';

  @override
  String get historyEmpty =>
      'За выбранный период результатов нет. Измените даты или выбор показателей.';

  @override
  String get historySearch => 'Найти и выбрать показатели';

  @override
  String get historyReset => 'Сбросить выбор';

  @override
  String get historyScrollBack => 'Прокрутить к ранним датам';

  @override
  String get historyScrollForward => 'Прокрутить к поздним датам';

  @override
  String get historyTableHint =>
      'Нажмите название показателя для подробностей. Даты прокручиваются по горизонтали.';

  @override
  String get historyPrint => 'Печать / PDF';

  @override
  String get sharingAccess => 'Доступ по ссылке и QR';

  @override
  String get sharingOptions => 'Какие данные открыть';

  @override
  String get profileHelp => 'Как это связано с анализами';

  @override
  String get profileHelpBody =>
      'Препараты, вес и болезни видны на графиках рядом с датами сдач.';

  @override
  String get profileOverview => 'Данные о вас для разговора с врачом.';

  @override
  String get copyAddress => 'Скопировать адрес';

  @override
  String get addressCopied => 'Адрес скопирован';

  @override
  String get copyFailed =>
      'Не удалось скопировать. Выделите и скопируйте адрес вручную.';

  @override
  String get historyExportHint =>
      'Сохраните печатную версию HTML. Откройте её в браузере и выберите «Печать → Сохранить как PDF».';

  @override
  String get tourShareTitle => 'Поделитесь анализами';

  @override
  String get tourShareBody =>
      'Покажите QR-код или отправьте ссылку специалисту. Срок и состав доступа настраиваются отдельно.';

  @override
  String get tourAddAnalysis => 'Добавить анализ';

  @override
  String get historyOpen => 'Открыть историю';

  @override
  String get visitHistory => 'История сдач';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get manageSharing => 'Управление доступом в настройках';

  @override
  String get history30Days => 'Последние 30 дней';

  @override
  String get history180Days => 'Последние 180 дней';

  @override
  String get uploadReviewHint =>
      'Перед сохранением сверьте значения с исходным бланком.';

  @override
  String get supportRecognition => 'Не распознался анализ';

  @override
  String get supportBug => 'Ошибка в приложении';

  @override
  String get supportAccess => 'Вопрос по доступу врачу';

  @override
  String get supportIdea => 'Идея или пожелание';

  @override
  String get supportOther => 'Другое';
}
