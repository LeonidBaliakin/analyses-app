import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:provider_directory/provider_directory.dart';

typedef Json = Map<String, dynamic>;

String canonical(Object? value) {
  Object? sort(Object? v) => v is Map
      ? {
          for (final k in (v.keys.cast<String>().toList()..sort()))
            k: sort(v[k]),
        }
      : v is List
      ? v.map(sort).toList()
      : v;
  return jsonEncode(sort(value));
}

String fingerprint(Object? value) =>
    sha256.convert(utf8.encode(canonical(value))).toString();

bool allowedUrl(String value, Json config) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      (config['allowedOrigins'] as List).contains(uri.origin);
}

bool invitroAddressMatchesCity(Json branch) => (branch['address'] as String)
    .toLowerCase()
    .contains(branch['city'] == 'spb' ? 'санкт-петербург' : 'воронеж');

/// Regional office pages also list neighbouring cities. Preserve their raw
/// facts for review, but do not publish them under a different city's filter.
Json constrainInvitroCoverage(Json previous) {
  final branches = (previous['branches'] as List).cast<Json>();
  final excluded = branches
      .where((b) => b['network'] == 'invitro' && !invitroAddressMatchesCity(b))
      .toList();
  if (excluded.isEmpty) return previous;
  final excludedIds = excluded.map((b) => b['id']).toSet();
  final review = <String, Json>{
    for (final b
        in (previous['coverageReviewBranches'] as List? ?? []).cast<Json>())
      b['id'] as String: b,
    for (final b in excluded) b['id'] as String: b,
  };
  final result = <String, dynamic>{
    ...previous,
    'branches': branches.where((b) => !excludedIds.contains(b['id'])).toList(),
    'coverageReviewBranches': review.values.toList(),
    'version':
        'coverage-${fingerprint([previous['version'], excludedIds.toList()..sort()])}',
  };
  ProviderCatalog.fromJson(result);
  return result;
}

/// Additive import: missing rows never imply a closure or a deletion. Fields
/// from an earlier observation retain their original verification date.
Json mergeImport(Json previous, Json config, Json input, String job) {
  final source = config['id'] as String;
  final incoming = (input['branches'] as List).cast<Json>();
  if (input['schemaVersion'] != 1 ||
      input['sourceId'] != source ||
      input['parserVersion'] != config['parserVersion'] ||
      incoming.isEmpty ||
      incoming.length > 5000 ||
      (input['items'] as List).length > 30000) {
    throw const FormatException('invalid_import');
  }
  final seen = <String>{};
  for (final b in incoming) {
    if (b['network'] != source ||
        (source == 'invitro' && !invitroAddressMatchesCity(b)) ||
        !(b['id'] as String).startsWith('$source-') ||
        !(config['cities'] as List).contains(b['city']) ||
        !seen.add(b['id'] as String) ||
        !allowedUrl(b['source'] as String, config) ||
        !allowedUrl(b['website'] as String, config) ||
        (b['name'] as String).trim().isEmpty ||
        (b['address'] as String).trim().isEmpty ||
        DateTime.parse(b['checkedAt'] as String)
            .isAfter(DateTime.parse(input['fetchedAt'] as String))) {
      throw const FormatException('invalid_branch');
    }
  }
  for (final city in config['cities'] as List) {
    if (!incoming.any((b) => b['city'] == city)) {
      throw const FormatException('missing_city');
    }
    final count = (previous['branches'] as List)
        .cast<Json>()
        .where((b) => b['network'] == source && b['city'] == city)
        .length;
    if (incoming.where((b) => b['city'] == city).length < count * 0.7) {
      throw const FormatException('suspicious_shrinkage');
    }
  }
  final items = (input['items'] as List).cast<Json>();
  final itemIds = <String>{};
  for (final i in items) {
    if (i['network'] != source ||
        !(i['id'] as String).startsWith('$source-') ||
        !itemIds.add(i['id'] as String) ||
        !(config['cities'] as List).contains(i['city']) ||
        !allowedUrl(i['source'] as String, config) ||
        ![
          'doctor',
          'test',
          'service',
          'specialty',
          'category',
        ].contains(i['kind']) ||
        (i['name'] as String).isEmpty ||
        (i['name'] as String).length > 1000 ||
        DateTime.parse(i['checkedAt'] as String)
            .isAfter(DateTime.parse(input['fetchedAt'] as String))) {
      throw const FormatException('invalid_item');
    }
  }
  for (final status in (input['catalogueStatus'] as List).cast<Json>()) {
    if (!allowedUrl(status['url'] as String, config) ||
        !(config['cities'] as List).contains(status['city']) ||
        !['observed', 'failed'].contains(status['status']) ||
        (status['pages'] as int) < 0 ||
        (status['items'] as int) < 0) {
      throw const FormatException('invalid_catalogue_status');
    }
  }
  final branches = (previous['branches'] as List)
      .cast<Json>()
      .map((b) => Json.from(b))
      .toList();
  for (final b in incoming) {
    final matches = branches
        .where(
          (old) =>
              old['network'] == source &&
              (old['id'] == b['id'] || old['website'] == b['website']),
        )
        .toList();
    if (matches.length > 1) throw const FormatException('ambiguous_branch');
    if (matches.isEmpty) {
      branches.add(b);
    } else {
      final old = matches.single;
      final index = branches.indexOf(old);
      final updated = <String, dynamic>{...old, ...b, 'id': old['id']};
      // Coordinates from an earlier address must never locate a moved office.
      if (old['address'] != b['address'] &&
          (b['lat'] == null || b['lon'] == null)) {
        updated.remove('lat');
        updated.remove('lon');
        updated.remove('coordinateSource');
      }
      if ((b['phone'] as String).isEmpty &&
          (old['phone'] as String).isNotEmpty) {
        for (final field in ['phone', 'phoneScope', 'phoneCheckedAt']) {
          if (old.containsKey(field)) updated[field] = old[field];
        }
      }
      branches[index] = updated;
    }
  }
  final sourceStates = Json.from(previous['sourceStates'] as Map? ?? {});
  sourceStates[source] = {
    'importedAt': input['fetchedAt'],
    'jobId': job,
    'parserVersion': input['parserVersion'],
    'catalogueStatus': input['catalogueStatus'],
  };
  // The package validates referential integrity and pinned terminology. Raw
  // catalogue items remain separate from verified doctor practices/test mappings.
  final result = <String, dynamic>{
    ...previous,
    'version': job,
    'branches': branches,
    'sourceStates': sourceStates,
    'publishedAt': input['fetchedAt'],
  };
  ProviderCatalog.fromJson(result);
  return result;
}
