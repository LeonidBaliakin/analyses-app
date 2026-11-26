import 'medical_specialties.dart';
import 'terminology.dart';

final bundledMedicalSpecialties = MedicalSpecialtyRelease(
  id: 'medical-specialties-2026-11-27.1',
  concepts: [
    _concept('specialty.hematology', 'Гематолог', 'Hematologist', [
      'Гематология',
    ]),
    _concept(
      'specialty.infectious-diseases',
      'Инфекционист',
      'Infectious disease specialist',
      ['Инфекционные болезни'],
    ),
    _concept('specialty.pulmonology', 'Пульмонолог', 'Pulmonologist', [
      'Пульмонология',
    ]),
    _concept('specialty.surgery', 'Хирург', 'Surgeon', ['Общая хирургия']),
    _concept(
      'specialty.traumatology-orthopedics',
      'Травматолог-ортопед',
      'Orthopedic trauma surgeon',
      ['Травматология и ортопедия', 'Ортопед', 'Травматолог'],
    ),
    _concept(
      'specialty.plastic-surgery',
      'Пластический хирург',
      'Plastic surgeon',
      ['Пластическая хирургия'],
    ),
    _concept('specialty.arthrology', 'Артролог', 'Arthrologist', [
      'Артрология',
    ]),
    _concept('specialty.urology', 'Уролог', 'Urologist', ['Урология']),
    _concept('specialty.neurology', 'Невролог', 'Neurologist', ['Неврология']),
    _concept('specialty.psychiatry', 'Психиатр', 'Psychiatrist', [
      'Психиатрия',
    ]),
    _concept(
      'specialty.obstetrics-gynecology',
      'Акушер-гинеколог',
      'Obstetrician-gynecologist',
      ['Гинекология', 'Акушерство', 'Гинеколог'],
    ),
  ],
  mappings: [
    _mapping(
      'scandinavia.hematology',
      'scandinavia',
      'Гематолог',
      'specialty.hematology',
      'https://www.avaclinic.ru/doctors/zhernyakova-anastasiya-andreevna/',
    ),
    _mapping(
      'scandinavia.infectious',
      'scandinavia',
      'Инфекционист',
      'specialty.infectious-diseases',
      'https://www.avaclinic.ru/doctors/zaykina-anna-aleksandrovna/',
    ),
    _mapping(
      'sm.pulmonology',
      'smclinic',
      'Пульмонолог',
      'specialty.pulmonology',
      'https://www.smclinic-spb.ru/doctor/asatiani-nana-zauryevna',
    ),
    for (final (slug, text, type) in [
      ('surgery', 'Хирург', 'specialty.surgery'),
      (
        'orthopedics',
        'Травматолог-ортопед',
        'specialty.traumatology-orthopedics',
      ),
      ('plastic', 'Пластический хирург', 'specialty.plastic-surgery'),
      ('arthrology', 'Артролог', 'specialty.arthrology'),
    ])
      _mapping(
        'sm.$slug',
        'smclinic',
        text,
        type,
        'https://www.smclinic-spb.ru/doctor/mitin-andrej-viktorovich',
      ),
    _mapping(
      'sova.surgery',
      'sova',
      'Врач-хирург',
      'specialty.surgery',
      'https://voronezh.sovamed.ru/vrachi/vzroslyj-vrach/samotin-aleksandr-nikolaevich/',
    ),
    _mapping(
      'sova.urology',
      'sova',
      'Врач-уролог',
      'specialty.urology',
      'https://voronezh.sovamed.ru/vrachi/vzroslyj-vrach/kocherov-aleksandr-aleksandrovich/',
    ),
    _mapping(
      'sova.neurology',
      'sova',
      'Врач-невролог',
      'specialty.neurology',
      'https://voronezh.sovamed.ru/vrachi/vzroslyj-vrach/lovyagina-sofya-ilinichna/',
    ),
    _mapping(
      'sova.psychiatry',
      'sova',
      'Врач-психиатр',
      'specialty.psychiatry',
      'https://voronezh.sovamed.ru/vrachi/vzroslyj-vrach/sakharov-igor-evgenevich/',
    ),
    _mapping(
      'sova.gynecology',
      'sova',
      'Врач — акушер-гинеколог',
      'specialty.obstetrics-gynecology',
      'https://voronezh.sovamed.ru/vrachi/vzroslyj-vrach/deynekina-yuliya-mikhaylovna/',
    ),
  ],
);

MedicalSpecialtyConcept _concept(
  String id,
  String ru,
  String en,
  List<String> names,
) => MedicalSpecialtyConcept(
  id: id,
  label: TerminologyLabel(ru: ru, en: en),
  searchNames: names,
);
MedicalSpecialtyMapping _mapping(
  String id,
  String network,
  String text,
  String concept,
  String source,
) => MedicalSpecialtyMapping(
  id: id,
  sourceSystem: network,
  sourceText: text,
  conceptId: concept,
  source: Uri.parse(source),
  checkedAt: DateTime(2026, 11, 27),
);
