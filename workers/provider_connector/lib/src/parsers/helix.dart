import 'dart:convert';

import '../parser.dart';
import '../pagination.dart';

final class HelixParser extends NetworkParser {
  @override
  String get source => 'helix';
  @override
  List<Json> branches(SourcePage p) {
    final state = p.document.querySelector('#ng-state');
    if (state == null) throw const FormatException('helix_state_missing');
    final json = jsonDecode(state.text) as Json;
    final lists = json.values.whereType<Json>().where(
      (j) => RegExp(r'/api/centers/all/\d+$').hasMatch(j['u'] as String? ?? ''),
    );
    if (lists.length != 1 ||
        !(lists.single['u'] as String).endsWith(
          '/${p.city == 'spb' ? 2 : 84}',
        )) {
      throw const FormatException('helix_region_mismatch');
    }
    return [
      for (final e in lists.single['b'] as List)
        if (e['isActive'] == true &&
            !RegExp(
              r'мурино|бугры|кудрово|янино|всеволожск|ленинградская область',
              caseSensitive: false,
            ).hasMatch(e['address'] as String))
          p.branch(
            identity: e['code'] as String,
            name: 'Хеликс · ${e['name']}',
            address:
                '${p.city == 'spb' ? 'Санкт-Петербург' : 'Воронеж'}, ${e['address']}',
            website: '/center/${e['code']}',
            phone: p.city == 'spb'
                ? '+7 (812) 309-12-21'
                : '+7 (473) 200-63-15',
            lat: (e['geoLocationInfo']?['latitude'] as num?)?.toDouble(),
            lon: (e['geoLocationInfo']?['longitude'] as num?)?.toDouble(),
            phoneScope: 'city',
          ),
    ];
  }

  @override
  List<Json> catalogue(SourcePage p) {
    final entries = <Json>[];
    final state = p.document.querySelector('#ng-state');
    if (state != null || p.uri.path == '/api/catalog/items/list/v2') {
      void visit(Object? v) {
        if (v is Map<String, dynamic>) {
          if (v['hxid'] is String &&
              (v['hxid'] as String).isNotEmpty &&
              (v['name'] is String || v['title'] is String)) {
            final code = v['hxid'] as String;
            entries.add({
              'id': stableId(source, '${p.city}:test:$code'),
              'network': source,
              'city': p.city,
              'kind': p.uri.queryParameters['filter.categoryId'] == '191'
                  ? 'service'
                  : 'test',
              'name': clean((v['name'] ?? v['title']) as String),
              'sourceCode': code,
              'availabilityStatus': 'city_network_offer',
              ...priceFields(v['price']?.toString()),
              'currency': 'RUB',
              'source': p
                  .url(
                    '${p.city == 'voronezh' ? '/voronezh' : ''}/catalog/item/${Uri.encodeComponent(code)}',
                  )
                  .toString(),
              'listingSource': p.uri.toString(),
              'checkedAt': p.date,
            });
          }
          for (final value in v.values) {
            visit(value);
          }
        } else if (v is List) {
          for (final e in v) {
            visit(e);
          }
        }
      }

      if (state == null) {
        _apiData(p);
        visit(jsonDecode(p.body));
      } else {
        final json = jsonDecode(state.text) as Json;
        final response = json.values.whereType<Json>().where(
          (v) => (v['u'] as String? ?? '').contains('/api/catalog/items/list/'),
        );
        for (final data in response) {
          final uri = Uri.parse(data['u'] as String);
          if (uri.queryParameters['cityId'] != '${p.city == 'spb' ? 2 : 84}') {
            throw const FormatException('helix_region_mismatch');
          }
          visit(data['b']);
        }
      }
    }
    return entries;
  }

  Json _apiData(SourcePage p) {
    if (p.uri.queryParameters['cityId'] != '${p.city == 'spb' ? 2 : 84}') {
      throw const FormatException('helix_region_mismatch');
    }
    final data = jsonDecode(p.body) as Json;
    sourceTotal(data);
    if ((data['catalogItems'] as List).isEmpty && sourceTotal(data) > 0) {
      throw const FormatException('empty_inventory_page');
    }
    return data;
  }

  @override
  int? expectedItems(SourcePage page) =>
      page.uri.path == '/api/catalog/items/list/v2'
      ? sourceTotal(_apiData(page))
      : null;
  @override
  List<Uri> nextPages(SourcePage page) =>
      page.uri.path == '/api/catalog/items/list/v2'
      ? offsetPages(page, _apiData(page), 'pagination.skip', 'pagination.take')
      : [
          for (final a in page.document.querySelectorAll('a[href]'))
            if (text(a) == 'Далее') page.url(a.attributes['href']!),
        ];
  @override
  bool acceptsNext(Uri first, Uri next) =>
      first.path == next.path &&
      first.queryParameters['cityId'] == next.queryParameters['cityId'] &&
      first.queryParameters['filter.categoryId'] ==
          next.queryParameters['filter.categoryId'];
  @override
  bool publicCatalogueRequest(Uri uri) =>
      uri.origin == 'https://helix.ru' &&
      uri.path == '/api/catalog/items/list/v2' &&
      onlyParameters(uri, {
        'cityId',
        'filter.categoryId',
        'pagination.take',
        'pagination.skip',
      }) &&
      {'2', '84'}.contains(uri.queryParameters['cityId']) &&
      {'190', '191'}.contains(uri.queryParameters['filter.categoryId']) &&
      uri.queryParameters['pagination.take'] == '100' &&
      (int.tryParse(uri.queryParameters['pagination.skip'] ?? '') ?? -1) >= 0;
}
