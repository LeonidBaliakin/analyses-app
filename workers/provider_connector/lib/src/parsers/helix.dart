import 'dart:convert';

import '../parser.dart';

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
    if (state != null) {
      void visit(Object? v) {
        if (v is Map<String, dynamic>) {
          if (v['hxid'] is String &&
              RegExp(r'^\d\d-\d{3}$').hasMatch(v['hxid'] as String) &&
              (v['name'] is String || v['title'] is String)) {
            final code = v['hxid'] as String;
            entries.add({
              'id': stableId(source, '${p.city}:test:$code'),
              'network': source,
              'city': p.city,
              'kind': 'test',
              'name': clean((v['name'] ?? v['title']) as String),
              'sourceCode': code,
              'availabilityStatus': 'city_network_offer',
              if (v['price'] != null) 'sourcePrice': v['price'].toString(),
              'currency': 'RUB',
              'source': p
                  .url(
                    '${p.city == 'voronezh' ? '/voronezh' : ''}/catalog/item/$code',
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
    return entries;
  }

  @override
  List<Uri> nextPages(SourcePage page) => [
    for (final a in page.document.querySelectorAll('a[href]'))
      if (text(a) == 'Далее') page.url(a.attributes['href']!),
  ];
}
