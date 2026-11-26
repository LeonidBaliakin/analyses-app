import 'laboratory_tests.dart';

const coagulationScreenComponents = {
  'component.pt-inr': 'Протромбиновое время, протромбин по Квику, МНО',
  'component.aptt': 'АЧТВ',
  'component.fibrinogen': 'Фибриноген',
  'component.thrombin-time': 'Тромбиновое время',
};
const coagulationExtendedComponents = {
  ...coagulationScreenComponents,
  'component.antithrombin-iii': 'Антитромбин III',
  'component.d-dimer': 'Д-димер',
};
const coagulationExtendedSevenComponents = {
  ...coagulationExtendedComponents,
  'component.plasminogen': 'Плазминоген, % активности',
};

/// Source facts reviewed on 2026-11-27. Unknown methods remain null.
final reviewedLaboratorySpecifications = <String, LaboratoryTestSpecification>{
  'sova.coagulation': _spec(
    _sovaCoag,
    'Кровь из периферической вены',
    null,
    components: coagulationScreenComponents,
  ),
  'sova.coagulation-expanded': _spec(
    _sovaCoag,
    'Кровь из периферической вены',
    null,
    components: coagulationExtendedComponents,
  ),
  'invitro.coagulation-screen': _spec(
    'https://www.invitro.ru/library/labdiagnostika/23992/',
    null,
    null,
    components: coagulationScreenComponents,
  ),
  'invitro.coagulation-104': _spec(
    'https://www.invitro.ru/analizes/profi/talitsa/3366/73711/',
    'Плазма (цитрат)',
    'См. отдельные тесты',
    components: coagulationExtendedComponents,
  ),
  'invitro.coagulation-109': _spec(
    'https://www.invitro.ru/analizes/profi/nahabino/3366/73582/',
    null,
    null,
    components: coagulationExtendedSevenComponents,
    note: 'ОБС109 содержит плазминоген; состав отличается от ОБС104.',
  ),
  'sova.glucose': _spec(
    'https://voronezh.sovamed.ru/services/analiz-na-glyukozu-v-krovi/',
    'Венозная кровь',
    null,
    note: 'Метод и отделение сыворотки/плазмы не уточнены. Экспресс-тест полоской указан отдельной услугой.',
  ),
  'helix.glucose': _spec(
    'https://helix.ru/catalog/item/06-015',
    'Плазма; взятие венозной крови',
    'Ферментативный УФ метод (гексокиназный)',
  ),
  'invitro.glucose': _spec(
    'https://www.invitro.ru/analizes/for-doctors/ufa/481/69479/',
    'Сыворотка или плазма крови',
    'Гексокиназный',
  ),
  'sova.esr': _spec(
    'https://voronezh.sovamed.ru/services/laboratornaya-diagnostika/',
    null,
    'По Вестергрену',
  ),
  'helix.esr': _spec(
    'https://helix.ru/kb/item/02-007',
    'Венозная кровь',
    'Метод капиллярной фотометрии',
  ),
  'invitro.esr': _spec(
    'https://www.invitro.ru/analizes/for-doctors/nikolskoe/156/2854/',
    'Венозная кровь, цельная кровь с ЭДТА',
    'Метод седиментации, микрометод',
    note: 'Источник допускает разные методы; конкретный метод филиала нужно уточнить.',
  ),
  'scandinavia.cbc': _spec(
    'https://www.avaclinic.ru/service/diagnostika/laboratornye-issledovaniya/',
    null,
    null,
    note: 'Точный состав тарифа и наличие СОЭ не подтверждены. Отдельное соответствие источника сохранено.',
  ),
};

const _sovaCoag = 'https://voronezh.sovamed.ru/services/koagulogramma/';
LaboratoryTestSpecification _spec(
  String source,
  String? specimen,
  String? method, {
  Map<String, String> components = const {},
  String? note,
}) => LaboratoryTestSpecification(
  source: Uri.parse(source),
  checkedAt: DateTime(2026, 11, 27),
  specimenText: specimen,
  methodText: method,
  components: components,
  note: note,
);
