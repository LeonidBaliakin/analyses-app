import 'dart:convert';

import '../parser.dart';
import '../pagination.dart';

final class InvitroParser extends NetworkParser {
  @override
  String get source => 'invitro';
  @override
  List<Json> branches(SourcePage p) => [
    for (final e in p.document.querySelectorAll(
      '.offices_card[data-office-id]',
    ))
      if (e.querySelector('.offices_card__link') != null &&
          text(e.querySelector('.offices_card__address'))
              .toLowerCase()
              .contains(p.city == 'spb' ? 'санкт-петербург' : 'воронеж'))
        p.branch(
          identity: e.attributes['data-office-id']!,
          name: 'ИНВИТРО · ${text(e.querySelector('.offices_card__link'))}',
          address: text(e.querySelector('.offices_card__address')),
          website: e.querySelector('.offices_card__link')!.attributes['href']!,
          phone: p.city == 'spb' ? '+7 (812) 363-36-30' : '+7 (473) 206-66-30',
          lat: double.tryParse(
            (e.attributes['data-office-dis'] ?? '').split(',').first,
          ),
          lon: double.tryParse(
            (e.attributes['data-office-dis'] ?? '').split(',').last,
          ),
          phoneScope: 'city',
        ),
  ];
  static const cityIds = {
    'spb': '992d4482-b30b-4b71-b4eb-df0a9387b9de',
    'voronezh': '3e0a9101-41d0-468b-bf3f-e323a2a1cf4d',
  };
  static const categoryPath = '/golk/tests/api/v1/complexes/categories';
  bool _categoryIndex(Uri uri) => uri.path == categoryPath;
  bool _category(Uri uri) => uri.path.startsWith('$categoryPath/');
  void _city(SourcePage p) {
    if (p.uri.queryParameters['cityID'] != cityIds[p.city]) {
      throw const FormatException('invitro_region_mismatch');
    }
  }

  bool _api(Uri uri) =>
      _categoryIndex(uri) ||
      _category(uri) ||
      RegExp(r'^/golk/tests/api/v1/(tests|complexes|checkups-examinations)/?$')
          .hasMatch(uri.path);
  Json _data(SourcePage p) {
    _city(p);
    final data = jsonDecode(p.body) as Json;
    sourceTotal(data);
    if (data['offset'].toString() != p.uri.queryParameters['offset'] ||
        data['limit'].toString() != p.uri.queryParameters['limit']) {
      throw const FormatException('pagination_mismatch');
    }
    return data;
  }

  @override
  List<Json> catalogue(SourcePage p) {
    if (_categoryIndex(p.uri)) {
      _city(p);
      return [
        for (final c in (jsonDecode(p.body) as List).cast<Json>())
          {
            'id': stableId(source, '${p.city}:category:${c['id']}'),
            'sourceId': c['id'],
            'network': source,
            'city': p.city,
            'kind': 'category',
            'name': clean(c['title'] as String),
            'availabilityStatus': 'unverified',
            'source': p.uri.toString(),
            'checkedAt': p.date,
          },
      ];
    }
    if (!_api(p.uri)) {
      return links(
        p,
        '.analyzes-item a[href], .catalog-item a[href], .catalog-item__title[href]',
        'test',
      );
    }
    final data = _data(p);
    final checkups = p.uri.path.contains('checkups-examinations');
    final products = <Json>[
      for (final group in (data['data'] as List).cast<Json>())
        if (checkups || !group.containsKey('products'))
          group
        else
          for (final product in (group['products'] as List).cast<Json>())
            {...product, 'sourceCategory': group['category_name']},
    ];
    if (_category(p.uri)) {
      final remaining =
          sourceTotal(data) - int.parse(p.uri.queryParameters['offset']!);
      final limit = int.parse(p.uri.queryParameters['limit']!);
      if (products.length != remaining.clamp(0, limit)) {
        throw const FormatException('category_count_mismatch');
      }
    }
    if (products.isEmpty && sourceTotal(data) > 0) {
      throw const FormatException('empty_inventory_page');
    }
    return [
      for (final v in products)
        {
          'id': stableId(source, '${p.city}:test:${v['id']}'),
          'sourceId': v['id'],
          'network': source,
          'city': p.city,
          'kind': 'test',
          'name': clean(v['title'] as String),
          'sourceCode': v['code'] ?? v['article'],
          'sourceCategory': v['sourceCategory'],
          'sourceCollection': p.uri.path,
          ...priceFields(v['price']?.toString()),
          'currency': 'RUB',
          'sourceAdditionalServices': v['additional_services'],
          'sourceDeadline': v['deadline'],
          'availabilityStatus': 'city_network_offer',
          'source': p.uri.toString(),
          'listingSource': p.uri.toString(),
          'checkedAt': p.date,
        },
    ];
  }

  @override
  int? expectedItems(SourcePage page) =>
      _api(page.uri) && !_categoryIndex(page.uri) && !_category(page.uri)
      ? sourceTotal(_data(page))
      : null;
  @override
  List<Uri> nextPages(SourcePage page) {
    if (_categoryIndex(page.uri)) {
      _city(page);
      return [
        for (final c in (jsonDecode(page.body) as List).cast<Json>()) ...[
          page.uri.replace(
            path: '$categoryPath/${c['id']}',
            queryParameters: {
              'cityID': cityIds[page.city]!,
              'limit': '100',
              'offset': '0',
            },
          ),
          for (final sub in (c['subcategories'] as List? ?? []).cast<Json>())
            page.uri.replace(
              path: '$categoryPath/${c['id']}/subcategories/${sub['id']}',
              queryParameters: {
                'cityID': cityIds[page.city]!,
                'limit': '100',
                'offset': '0',
              },
            ),
        ],
      ];
    }
    return _api(page.uri)
        ? offsetPages(page, _data(page), 'offset', 'limit')
        : [];
  }

  @override
  bool emptyAllowed(SourcePage page) => _categoryIndex(page.uri)
      ? (jsonDecode(page.body) as List).isEmpty
      : _category(page.uri)
      ? sourceTotal(_data(page)) == 0
      : super.emptyAllowed(page);
  @override
  bool acceptsNext(Uri first, Uri next) =>
      (first.path == next.path ||
          (_categoryIndex(first) && next.path.startsWith('$categoryPath/'))) &&
      first.queryParameters['cityID'] == next.queryParameters['cityID'];
}
