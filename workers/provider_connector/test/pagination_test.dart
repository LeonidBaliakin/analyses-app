import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider_connector/provider_connector.dart';
import 'package:provider_connector/src/fetcher.dart';
import 'package:provider_connector/src/worker.dart';
import 'package:test/test.dart';

SourcePage page(
  NetworkParser parser,
  String url,
  Object data, {
  String city = 'voronezh',
}) => SourcePage(
  parser.source,
  city,
  Uri.parse(url),
  data is String ? data : jsonEncode(data),
  DateTime.utc(2026, 11, 27),
);
const helixUrl =
    'https://helix.ru/api/catalog/items/list/v2?cityId=84&filter.categoryId=190&pagination.take=100&pagination.skip=0';
String invitroUrl({
  String city = '3e0a9101-41d0-468b-bf3f-e323a2a1cf4d',
  int offset = 0,
}) =>
    'https://www.invitro.ru/golk/tests/api/v1/tests?cityID=$city&limit=100&offset=$offset';

class PagedParser extends NetworkParser {
  @override
  String get source => 'synthetic';
  @override
  List<Json> branches(SourcePage p) => [
    p.branch(
      identity: 'one',
      name: 'One',
      address: 'Synthetic 1',
      website: '/branch',
      phone: '',
    ),
  ];
  @override
  List<Json> catalogue(SourcePage p) => [
    {
      'id': 'synthetic-${p.body}',
      'network': source,
      'city': p.city,
      'kind': 'service',
      'name': p.body,
      'source': p.uri.toString(),
      'checkedAt': p.date,
    },
  ];
  @override
  int? expectedItems(SourcePage p) => 3;
  @override
  List<Uri> nextPages(SourcePage p) =>
      p.uri.query.isEmpty ? [p.url('?page=2'), p.url('?page=3')] : [];
}

class ListingParser extends PagedParser {
  @override
  int? expectedItems(SourcePage p) => 4;
  @override
  List<Json> catalogue(SourcePage p) => [
    for (final id in p.body.split(','))
      {
        'id': 'synthetic-$id',
        'network': source,
        'city': p.city,
        'kind': 'doctor',
        'name': id,
        'source': 'https://example.org/$id',
        'listingSource': p.uri.toString(),
        'checkedAt': p.date,
      },
  ];
  @override
  List<Uri> nextPages(SourcePage p) =>
      p.uri.query.isEmpty ? [p.url('?page=2')] : [];
}

void main() {
  test('source totals may count repeated listings while unique facts stay deduplicated', () async {
    final client = MockClient(
      (r) async => http.Response(
        r.url.path == '/robots.txt'
            ? ''
            : r.url.hasQuery
            ? 'two,three'
            : 'one,two',
        200,
      ),
    );
    addTearDown(client.close);
    final result = await collect(
      ListingParser(),
      {
        'parserVersion': '2',
        'maxPages': 10,
        'branchPages': [],
        'cataloguePages': [
          {'city': 'spb', 'url': 'https://example.org/catalogue'},
        ],
      },
      PublicFetcher(client, 'https://example.org', delay: Duration.zero),
      () async {},
    );
    final status = (result['catalogueStatus'] as List).single;
    expect(status['coverage'], 'complete');
    expect(status['items'], 3);
    expect(status['observedRows'], 4);
    expect(status['duplicateRows'], 1);
  });

  test('Invitro flattens grouped products, preserves source facts and follows total', () {
    final parser = InvitroParser();
    final p = page(parser, invitroUrl(), {
      'total': 201,
      'limit': 100,
      'offset': 0,
      'data': [
        {
          'category_name': 'Исходная группа',
          'products': [
            {
              'id': '1',
              'title': 'Панель с особым составом',
              'code': 'ОБС1',
              'price': 123.5,
              'additional_services': [
                {'title': 'Забор', 'price': 200},
              ],
            },
          ],
        },
      ],
    });
    final item = parser.catalogue(p).single;
    expect(item['sourceCode'], 'ОБС1');
    expect(item['sourcePrice'], '123.5');
    expect(item['sourceAdditionalServices'], hasLength(1));
    expect(item['sourceCategory'], 'Исходная группа');
    expect(item.containsKey('typeId'), isFalse);
    expect(item.containsKey('branchIds'), isFalse);
    expect(parser.expectedItems(p), 201);
    expect(parser.nextPages(p).map((u) => u.queryParameters['offset']), [
      '100',
      '200',
    ]);
    expect(
      parser.acceptsNext(p.uri, Uri.parse(invitroUrl(city: 'other'))),
      isFalse,
    );
    expect(
      () => parser.catalogue(page(parser, invitroUrl(city: 'other'), {})),
      throwsFormatException,
    );
    expect(
      () => parser.catalogue(page(parser, invitroUrl(), {'data': []})),
      throwsFormatException,
    );
  });
  test('Helix uses explicit city and source total for all remaining pages', () {
    final parser = HelixParser(),
        p = page(HelixParser(), helixUrl, {
          'total': 201,
          'catalogItems': [
            {'hxid': '02-006', 'title': 'Исходный анализ', 'price': 235},
          ],
        });
    expect(parser.catalogue(p).single['sourceCode'], '02-006');
    expect(
      parser.nextPages(p).map((u) => u.queryParameters['pagination.skip']),
      ['100', '200'],
    );
    expect(
      () => parser.catalogue(
        page(parser, helixUrl, {'total': 1, 'catalogItems': []}, city: 'spb'),
      ),
      throwsFormatException,
    );
    expect(
      () => parser.expectedItems(page(parser, helixUrl, {'catalogItems': []})),
      throwsFormatException,
    );
  });
  test('Invitro enumerates published complex categories and validates each category count', () {
    final parser = InvitroParser();
    const id = '7ecc5698-856e-4f5e-8046-a94c87fbc367';
    const root =
        'https://www.invitro.ru/golk/tests/api/v1/complexes/categories?cityID=3e0a9101-41d0-468b-bf3f-e323a2a1cf4d';
    final index = page(parser, root, [
      {'id': id, 'title': 'Исходная группа', 'subcategories': []},
    ]);
    expect(parser.catalogue(index).single['kind'], 'category');
    final next = parser.nextPages(index).single;
    expect(next.path, endsWith(id));
    expect(parser.acceptsNext(index.uri, next), isTrue);
    final leaf = page(parser, next.toString(), {
      'total': 1,
      'offset': 0,
      'limit': 100,
      'data': [
        {'id': 'test', 'title': 'Комплекс', 'code': 'ОБС1', 'price': 500},
      ],
    });
    expect(parser.catalogue(leaf).single['name'], 'Комплекс');
    expect(
      parser.expectedItems(leaf),
      isNull,
      reason: 'Different category totals must not be added as one global unique-product total',
    );
    expect(
      () => parser.catalogue(
        page(parser, next.toString(), {
          'total': 2,
          'offset': 0,
          'limit': 100,
          'data': [
            {'id': 'test', 'title': 'Комплекс'},
          ],
        }),
      ),
      throwsFormatException,
    );
  });
  test('Helix does not discard valid four-digit service codes', () {
    final parser = HelixParser();
    final p = page(
      parser,
      helixUrl.replaceFirst('categoryId=190', 'categoryId=191'),
      {
        'total': 1,
        'catalogItems': [
          {'hxid': '90-1133', 'title': 'Выезд терапевта', 'price': 2000},
        ],
      },
    );
    expect(parser.catalogue(p).single['sourceCode'], '90-1133');
    expect(parser.catalogue(p).single['kind'], 'service');
  });
  test('public catalogue exceptions are exact read-only operations', () {
    final h = HelixParser(), s = ScandinaviaParser();
    expect(h.publicCatalogueRequest(Uri.parse(helixUrl)), isTrue);
    for (final url in [
      '$helixUrl&token=secret',
      helixUrl.replaceFirst('helix.ru', 'other.example'),
      helixUrl.replaceFirst('items/list/v2', 'booking'),
      helixUrl.replaceFirst('cityId=84', 'cityId=99'),
    ]) {
      expect(h.publicCatalogueRequest(Uri.parse(url)), isFalse);
    }
    expect(
      s.publicCatalogueRequest(
        Uri.parse('https://www.avaclinic.ru/doctors/?PAGEN_1=2&ajax=Y'),
      ),
      isTrue,
    );
    expect(
      s.publicCatalogueRequest(
        Uri.parse(
          'https://www.avaclinic.ru/doctors/?PAGEN_1=2&ajax=Y&action=book',
        ),
      ),
      isFalse,
    );
  });
  test(
    'Scandinavia prices retain all raw prices and exact show-more operation',
    () {
      final parser = ScandinaviaParser(),
          p = page(
            ScandinaviaParser(),
            'https://www.avaclinic.ru/prices/',
            '<div data-total-count="25"><div class="pricesSection_item"><div class="pricesSection_name">Исходная услуга</div><div class="pricesSection_values"><div class="pricesSection_value primary">от 500 руб.</div> 465 руб. с подпиской</div></div><button class="js_showMoreAjax" data-href="/prices/?SERVICE_NAV=page-2"></button></div>',
            city: 'spb',
          );
      expect(parser.expectedItems(p), 25);
      expect(parser.catalogue(p).single['sourcePrice'], 'от 500 руб.');
      expect(parser.nextPages(p), hasLength(2));
      expect(
        parser
            .initialPage(
              Uri.parse(
                'https://www.avaclinic.ru/prices/?SERVICE_NAV=page-1&ajax=Y&APPEND=Y',
              ),
            )
            .hasQuery,
        isFalse,
      );
      expect(parser.nextPages(p).first.queryParameters, {
        'SERVICE_NAV': 'page-2',
        'ajax': 'Y',
        'APPEND': 'Y',
      });
    },
  );
  test('a repeated first page cannot be reported as full inventory', () async {
    final client = MockClient(
      (r) async =>
          http.Response(r.url.path == '/robots.txt' ? '' : 'same', 200),
    );
    addTearDown(client.close);
    final result = await collect(
      PagedParser(),
      {
        'parserVersion': '2',
        'maxPages': 10,
        'branchPages': [
          {'city': 'spb', 'url': 'https://example.org/branch'},
        ],
        'cataloguePages': [
          {'city': 'spb', 'url': 'https://example.org/catalogue'},
        ],
      },
      PublicFetcher(client, 'https://example.org', delay: Duration.zero),
      () async {},
    );
    final status = (result['catalogueStatus'] as List).single;
    expect(status['coverage'], 'partial');
    expect(status['items'], 1);
    expect(status['expectedItems'], 3);
    expect(
      (status['failures'] as List).any(
        (e) => e['error'] == 'inventory_count_mismatch',
      ),
      isTrue,
    );
    expect(status['pages'], 3);
  });
  test('deduplication preserves specialty and listing provenance', () {
    final original = {
      'id': 'one',
      'listingSource': 'https://example.org/a',
      'sourceSpecialty': 'Терапевт',
      'sourcePrice': 'от 500 руб.',
    };
    final merged = mergeObservation(original, {
      'id': 'one',
      'listingSource': 'https://example.org/b',
      'sourceSpecialty': 'Кардиолог',
      'sourcePrice': '700 руб.',
    });
    expect(merged['listingSources'], [
      'https://example.org/a',
      'https://example.org/b',
    ]);
    expect(merged['sourceSpecialties'], ['Кардиолог', 'Терапевт']);
    expect((merged['sourceListings'] as List).map((l) => l['sourcePrice']), [
      'от 500 руб.',
      '700 руб.',
    ]);
  });
}
