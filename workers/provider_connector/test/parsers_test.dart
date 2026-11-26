import 'dart:convert';

import 'package:provider_connector/provider_connector.dart';
import 'package:test/test.dart';

SourcePage page(
  NetworkParser parser,
  String html, {
  String city = 'voronezh',
  String path = '/list',
}) => SourcePage(
  parser.source,
  city,
  Uri.parse('https://example.org$path'),
  html,
  DateTime.utc(2026, 11, 27),
);

void main() {
  test('Invitro regional list never assigns a neighbouring town to Saint Petersburg', () {
    final parser = InvitroParser();
    final html =
        '<div class="offices_card" data-office-id="1"><a class="offices_card__link" href="/1">Первый</a><div class="offices_card__address">Санкт-Петербург, Синтетическая, 1</div></div><div class="offices_card" data-office-id="2"><a class="offices_card__link" href="/2">Другой</a><div class="offices_card__address">г. Кировск, Синтетическая, 2</div></div>';
    final rows = parser.branches(page(parser, html, city: 'spb'));
    expect(rows, hasLength(1));
    expect(rows.single['address'], startsWith('Санкт-Петербург'));
  });
  test('all seven network parsers extract source identities without inventing coordinates', () {
    final fixtures = <NetworkParser, String>{
      InvitroParser(): '''<div class="offices_card" data-office-id="1" data-office-dis="51.7,39.2"><a class="offices_card__link" href="/clinic/1">Первый</a><div class="offices_card__address">Воронеж, Синтетическая, 1</div></div>''',
      HelixParser():
          '''<script id="ng-state" type="application/json">${jsonEncode({
            'a': {
              'u': 'https://api.example.org/api/centers/all/84',
              'b': [
                {
                  'code': '1',
                  'name': 'Первый',
                  'address': 'Синтетическая, 1',
                  'isActive': true,
                  'geoLocationInfo': {'latitude': 51.7, 'longitude': 39.2},
                },
              ],
            },
          })}</script>''',
      SmclinicParser(): '''<div class="b-clinics_map--info-clinic_info-item"><div class="b-clinics_map--info-clinic_info-item--clinics_info-title-top"><a href="/clinic/1">Синтетическая, 1</a></div></div>''',
      ScandinaviaParser(): '''<div class="offices_card" data-id="1"><a class="offices_cardTitle" href="/clinic/1">Первый</a><div class="offices_cardAddress">Санкт-Петербург, Синтетическая, 1</div><a class="offices_cardPhone">+7 000</a></div>''',
      SovaParser():
          '''<a href="/contact-us/synthetic-1/">Синтетическая, 1</a>''',
      MedexpertParser(): '''<a class="service_1" href="/med_points?center=1"><span class="med_point_status">Центр</span><span class="med_points_hover">г. Воронеж, Синтетическая, 1</span></a><a class="service_1" href="/med_points?center=2"><span class="med_point_status">Центр</span><span class="med_points_hover">г. Липецк, Синтетическая, 1</span></a>''',
      CspParser(): '''<div class="div100 contmap" id="one"><h3>Синтетическая, 1</h3><a href="tel:+7000">+7 000</a></div>''',
    };
    for (final f in fixtures.entries) {
      final first = f.key.branches(page(f.key, f.value)).single;
      final repeat = f.key.branches(page(f.key, f.value)).single;
      expect(first['id'], repeat['id']);
      expect(first['network'], f.key.source);
      expect(first['sourceId'], isNotEmpty);
      expect(first['checkedAt'], '2026-11-27');
      if (f.key is! InvitroParser && f.key is! HelixParser) {
        expect(first.containsKey('lat'), isFalse);
      }
    }
  });
  test('Helix fails closed on the wrong regional payload', () {
    final parser = HelixParser();
    final data =
        '<script id="ng-state" type="application/json">${jsonEncode({
          'a': {'u': 'https://api.example.org/api/centers/all/2', 'b': []},
        })}</script>';
    expect(() => parser.branches(page(parser, data)), throwsFormatException);
  });
  test(
    'modal doctors keep separate source ids even when all links use hash',
    () {
      final parser = MedexpertParser();
      final records = parser.catalogue(
        page(
          parser,
          '''<a class="speci_a" href="#" data-target="doc_1"><div class="doc_meta">Иванов Иван</div></a><a class="speci_a" href="#" data-target="doc_2"><div class="doc_meta">Иванов Иван</div></a>''',
        ),
      );
      expect(records.map((r) => r['id']).toSet(), hasLength(2));
      expect(
        records.every((r) => r['availabilityStatus'] == 'unverified'),
        isTrue,
      );
    },
  );
  test('CSP categories and doctors are distinct; category crawl never follows profiles', () {
    final parser = CspParser();
    final p = page(
      parser,
      '''<a class="link_cardspec" href="/catuzspecialist/pediatr/"><h2>Педиатр</h2></a><a class="link_cardspec" href="/team/one/"><h2>Иванов Иван</h2></a>''',
      path: '/uzspecialist/',
    );
    final records = parser.catalogue(p);
    expect(records.map((r) => r['kind']), ['specialty', 'doctor']);
    expect(parser.nextPages(p).map((u) => u.path), [
      '/catuzspecialist/pediatr/',
    ]);
  });
  test('Helix test code, price and regional provenance survive extraction', () {
    final parser = HelixParser();
    final data =
        '<script id="ng-state" type="application/json">${jsonEncode({
          'a': {
            'u': 'https://api.example.org/api/catalog/items/list/v2?cityId=84',
            'b': {
              'catalogItems': [
                {'hxid': '02-006', 'title': 'Исходное название', 'price': 235},
              ],
            },
          },
        })}</script>';
    final item = parser.catalogue(page(parser, data)).single;
    expect(item['name'], 'Исходное название');
    expect(item['sourcePrice'], '235');
    expect(item['sourceCode'], '02-006');
    expect(item['source'], contains('/voronezh/catalog/item/02-006'));
    expect(item.containsKey('branchIds'), isFalse);
  });
}
