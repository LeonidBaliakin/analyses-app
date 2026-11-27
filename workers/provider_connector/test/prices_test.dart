import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider_connector/provider_connector.dart';
import 'package:provider_connector/src/fetcher.dart';
import 'package:provider_connector/src/worker.dart';
import 'package:test/test.dart';

SourcePage page(NetworkParser parser, String body, String path) => SourcePage(
  parser.source,
  parser is SmclinicParser ? 'spb' : 'voronezh',
  Uri.parse('https://example.org$path'),
  body,
  DateTime.utc(2026, 11, 27),
);

const smPrices = '''
<div class="pricelist">
  <table><tr class="folder"><td data-code="ПИК.">Приёмы</td></tr></table>
  <table class="just_show_price"><tr>
    <td class="name" data-code="SYN.01">Первичный приём специалиста</td>
    <td class="price">от 3&nbsp;200</td>
    <td class="price js-price-part">от 320</td>
  </tr></table>
  <table><tr>
    <td class="name" data-code="SYN.02">Консультация перед операцией</td>
    <td class="price">0</td><td class="price js-price-part">-</td>
  </tr></table>
  <table><tr>
    <td class="name" data-code="SYN.03">Услуга без опубликованной цены</td>
    <td class="price">-</td><td class="price js-price-part">от 500</td>
  </tr></table>
</div>''';

void main() {
  test(
    'SM full tariffs never use instalments or folder headings as prices',
    () {
      final parser = SmclinicParser();
      final items = parser.catalogue(page(parser, smPrices, '/prices'));
      expect(items, hasLength(3));
      expect(items.first['sourcePrice'], 'от 3 200');
      expect(
        items.first['sourcePriceDetails'],
        'Цена (руб.): от 3 200; В рассрочку*: от 320',
      );
      expect(items.first['sourceCode'], 'SYN.01');
      expect(items.first['currency'], 'RUB');
      expect(items.first['listingSource'], 'https://example.org/prices');
      expect(items[1]['sourcePrice'], '0');
      expect(items[1]['sourcePriceStatus'], 'observed');
      expect(items.last.containsKey('sourcePrice'), isFalse);
      expect(items.last['sourcePriceStatus'], 'not_observed');
      expect(
        items.last['sourcePriceDetails'],
        contains('В рассрочку*: от 500'),
      );
      final updated = parser.catalogue(
        page(
          parser,
          smPrices.replaceAll('3&nbsp;200', '3&nbsp;400'),
          '/prices',
        ),
      );
      expect(updated.first['id'], items.first['id']);
      expect(updated.first['sourcePrice'], 'от 3 400');
    },
  );

  test('CSP preserves distinct initial/repeat offers and lab tariffs', () {
    final parser = CspParser();
    final items = parser.catalogue(
      page(parser, '''
<a class="link_cardspec" href="/team/synthetic/"><h2>Исходный врач</h2></a>
<a class="link_cardservice" href="/uzspecialist/initial/">
 <h4>Приём исходного врача (первичный)</h4>
 <div class="txt_priceh"><span>от</span><strong>2500</strong><span>руб</span></div>
</a>
<a class="link_cardservice" href="/uzspecialist/repeat/">
 <h4>Приём исходного врача (повторный)</h4><div class="txt_priceh">от 2200 руб</div>
</a>
<a class="link_cardservice" href="/analysis/synthetic/">
 <h4>Исходный анализ</h4><div class="txt_priceh">от 470 руб</div>
</a>
<a class="link_cardservice" href="/vaccine/synthetic/">
 <h4>Исходная вакцина</h4><div class="txt_priceh">Уточняйте</div>
</a>''', '/catuzspecialist/synthetic/'),
    );
    expect(items.map((i) => i['kind']), [
      'doctor',
      'service',
      'service',
      'test',
      'service',
    ]);
    expect(items.map((i) => i['id']).toSet(), hasLength(5));
    expect(items[1]['sourcePrice'], 'от 2500 руб');
    expect(items[2]['sourcePrice'], 'от 2200 руб');
    expect(items[3]['sourcePrice'], 'от 470 руб');
    expect(items[1]['source'], 'https://example.org/uzspecialist/initial/');
    expect(
      items[1]['listingSource'],
      'https://example.org/catuzspecialist/synthetic/',
    );
    expect(items.first.containsKey('sourcePrice'), isFalse);
    expect(items[1].containsKey('doctorId'), isFalse);
    expect(items.last['sourcePriceStatus'], 'not_observed');
    expect(items.last['sourcePriceDetails'], 'Уточняйте');
  });

  test('MedExpert retains price context and source centre restrictions', () {
    final parser = MedexpertParser();
    final item = parser
        .catalogue(
          page(parser, '''
<div class="price_table_boxes">
 <label data-name="Консультации | Первичный приём" id="synthetic-1"
  data-category="Консультации"></label>
 <div class="about_centers" data-centers='[{"vrn_1":1,"vrn_2":0}]'></div>
 <div class="block_2"><span class="block_2_price">от 2500 ₽</span>
  <span>цена зависит от центра</span></div>
</div>''', '/price'),
        )
        .single;
    expect(item['sourcePrice'], 'от 2500 ₽');
    expect(item['sourcePriceDetails'], 'от 2500 ₽ цена зависит от центра');
    expect(item['sourceCenters'], '[{"vrn_1":1,"vrn_2":0}]');
    expect(item.containsKey('branchIds'), isFalse);
  });

  test(
    'Scandinavia keeps subscription price separate from the main tariff',
    () {
      final parser = ScandinaviaParser();
      final item = parser
          .catalogue(
            page(parser, '''
<div class="pricesSection_item">
 <div class="pricesSection_name">Исходная консультация</div>
 <div class="pricesSection_values">
  <div class="pricesSection_value primary">от 5000 руб.</div>
  <div>4650 руб. с подпиской</div>
 </div>
</div>''', '/prices/'),
          )
          .single;
      expect(item['sourcePrice'], 'от 5000 руб.');
      expect(item['sourcePriceDetails'], 'от 5000 руб. 4650 руб. с подпиской');
    },
  );

  test('Sova doctor tariff retains wording and the listing provenance', () {
    final parser = SovaParser();
    final item = parser
        .catalogue(
          page(parser, '''
<div class="staff-card">
 <a class="staff-card__title" href="/vrachi/synthetic/">Исходный врач</a>
 <div class="staff-cart_price-wrap">Приём от 2500 ₽</div>
</div>''', '/vrachi/'),
        )
        .single;
    expect(item['sourcePrice'], 'Приём от 2500 ₽');
    expect(item['listingSource'], 'https://example.org/vrachi/');
  });

  test(
    'unpriced placement cannot relabel a previous price as newly observed',
    () {
      final first = {
        'id': 'same',
        'listingSource': 'https://example.org/one',
        ...priceFields('от 500 руб.', details: '500 руб. при условии'),
      };
      final incoming = {
        'id': 'same',
        'listingSource': 'https://example.org/two',
        ...priceFields(null),
      };
      final merged = mergeObservation(first, incoming);
      expect(merged['sourcePriceStatus'], 'not_observed');
      expect(merged.containsKey('sourcePrice'), isFalse);
      expect(merged.containsKey('sourcePriceDetails'), isFalse);
      final listings = (merged['sourceListings'] as List).cast<Json>();
      expect(listings.first['sourcePrice'], 'от 500 руб.');
      expect(listings.first['listingSource'], 'https://example.org/one');
      expect(listings.last['sourcePriceStatus'], 'not_observed');
      final refreshed = mergeObservation({
        ...incoming,
        ...priceFields('уточняйте'),
      }, {...first, ...priceFields('700 руб.')}..remove('sourcePriceDetails'));
      expect(refreshed['sourcePrice'], '700 руб.');
      expect(refreshed.containsKey('sourcePriceDetails'), isFalse);
    },
  );

  test('configured parsers and registry use the same compiled version', () {
    final config = jsonDecode(
      File('../../services/provider_directory/config/sources.json')
          .readAsStringSync(),
    ) as Json;
    final parsers = [
      InvitroParser(),
      HelixParser(),
      SmclinicParser(),
      ScandinaviaParser(),
      SovaParser(),
      MedexpertParser(),
      CspParser(),
    ];
    for (final parser in parsers) {
      final source = (config['sources'] as List).cast<Json>().singleWhere(
        (s) => s['id'] == parser.source,
      );
      expect(source['parserVersion'], parser.version);
    }
    final sources = (config['sources'] as List).cast<Json>();
    expect(
      sources.singleWhere((s) => s['id'] == 'smclinic')['cataloguePages'],
      contains(
        containsPair(
          'url',
          'https://www.smclinic-spb.ru/uslugi/tseny-i-stoimost-uslug',
        ),
      ),
    );
    expect(
      sources.singleWhere((s) => s['id'] == 'csp')['cataloguePages'],
      contains(containsPair('url', 'https://csp-vrn.ru/vaccine/')),
    );
  });

  test('price collection survives retries without duplicate offers', () async {
    var attempts = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/robots.txt') return http.Response('', 200);
      attempts++;
      if (attempts == 1) return http.Response('', 503);
      return http.Response(
        smPrices,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });
    addTearDown(client.close);
    Future<Json> run() => collect(
      SmclinicParser(),
      {
        'branchPages': [],
        'cataloguePages': [
          {'city': 'spb', 'url': 'https://example.org/prices'},
        ],
        'maxPages': 10,
      },
      PublicFetcher(client, 'https://example.org', delay: Duration.zero),
      () async {},
    );
    final first = await run();
    final repeat = await run();
    expect(attempts, 3);
    final items = (first['items'] as List).cast<Json>();
    expect(items, hasLength(3));
    expect(items.first['sourcePrice'], 'от 3 200');
    expect((first['catalogueStatus'] as List).single['coverage'], 'complete');
    expect(
      (repeat['items'] as List).map((i) => i['id']),
      items.map((i) => i['id']),
    );
  });
}
