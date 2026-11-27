import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

typedef Json = Map<String, dynamic>;

String clean(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
String text(Element? e) {
  String content(Node n) => n is Text ? n.data : n.nodes.map(content).join(' ');
  return e == null ? '' : clean(content(e));
}

String stableId(String source, String value) =>
    '$source-${sha256.convert(utf8.encode(value)).toString().substring(0, 24)}';

final class SourcePage {
  SourcePage(this.source, this.city, this.uri, this.body, this.fetchedAt)
    : document = html.parse(body);
  final String source, city, body;
  final Uri uri;
  final DateTime fetchedAt;
  final Document document;
  Uri url(String value) => uri.resolve(value);
  String get date => fetchedAt.toUtc().toIso8601String().substring(0, 10);

  Json branch({
    required String identity,
    required String name,
    required String address,
    required String website,
    required String phone,
    double? lat,
    double? lon,
    String phoneScope = 'network',
    bool phoneObserved = false,
  }) {
    if (name.isEmpty || address.isEmpty || identity.isEmpty) {
      throw const FormatException('branch_markup_changed');
    }
    return {
      'id': stableId(source, identity),
      'sourceId': identity,
      'network': source,
      'city': city,
      'name': name,
      'address': address,
      'phone': phone,
      'phoneScope': phoneScope,
      'phoneCheckedAt': phoneObserved ? date : '2026-11-27',
      'website': url(website).toString(),
      'source': uri.toString(),
      'checkedAt': date,
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      if (lat != null && lon != null) ...{
        'lat': lat,
        'lon': lon,
        'coordinateSource': uri.toString(),
      },
    };
  }
}

abstract class NetworkParser {
  String get source;
  String get version => '3';
  List<Json> branches(SourcePage page);

  /// Raw source facts. A listing/category never becomes a confirmed physician
  /// practice or a medically equivalent test without its own verified mapping.
  List<Json> catalogue(SourcePage page);

  Uri initialPage(Uri configured) => configured;
  List<Uri> nextPages(SourcePage page) => [];
  bool acceptsNext(Uri first, Uri next) => first.path == next.path;

  /// Count supplied by the source for this collection, never an estimate.
  int? expectedItems(SourcePage page) => null;
  bool emptyAllowed(SourcePage page) => expectedItems(page) == 0;
  String get coverageMethod => 'linked_sections';

  /// Only compiled, read-only catalogue operations used by the public site.
  /// This is separate from HTML crawling; it never grants another origin,
  /// authentication, booking, or arbitrary query parameters.
  bool publicCatalogueRequest(Uri uri) => false;
}

Json mergeObservation(Json? previous, Json incoming) {
  if (previous == null) return incoming;
  const listingFields = [
    'listingSource',
    'name',
    'sourcePrice',
    'sourcePriceStatus',
    'sourcePriceDetails',
    'currency',
    'sourceCode',
    'sourceCenters',
    'sourceAdditionalServices',
    'sourceSpecialty',
    'sourceLocation',
    'sourceCategory',
  ];
  List<Json> listings(Json item) =>
      (item['sourceListings'] as List?)?.cast<Json>() ??
      [
        {
          for (final field in listingFields)
            if (item[field] != null) field: item[field],
        },
      ];
  final sourceListings = <String, Json>{
    for (final listing in [...listings(previous), ...listings(incoming)])
      jsonEncode(listing): listing,
  };
  List<String> values(String plural, String singular) => {
    ...((previous[plural] as List?) ?? []).cast<String>(),
    if (previous[singular] case final String v when v.isNotEmpty) v,
    ...((incoming[plural] as List?) ?? []).cast<String>(),
    if (incoming[singular] case final String v when v.isNotEmpty) v,
  }.toList()..sort();
  final merged = {
    ...previous,
    ...incoming,
    'listingSources': values('listingSources', 'listingSource'),
    'sourceSpecialties': values('sourceSpecialties', 'sourceSpecialty'),
    'sourceLocations': values('sourceLocations', 'sourceLocation'),
    'sourceCategories': values('sourceCategories', 'sourceCategory'),
    'sourceListings': sourceListings.values.toList(),
  };
  // An unpriced placement must not give a previous placement's price new
  // provenance. Earlier offers remain intact in sourceListings.
  if (incoming.containsKey('sourcePriceStatus')) {
    for (final field in ['sourcePrice', 'sourcePriceDetails']) {
      if (!incoming.containsKey(field)) merged.remove(field);
    }
  }
  return merged;
}

/// Preserve source wording, never turn a missing tariff into zero. Details may
/// contain labelled instalments/discounts; they are not the primary price.
Json priceFields(String? value, {String? details}) {
  final price = clean(value);
  final observed =
      RegExp(r'\d').hasMatch(price) || price.toLowerCase() == 'бесплатно';
  final description = clean(details ?? (observed ? null : price));
  return {
    'sourcePriceStatus': observed ? 'observed' : 'not_observed',
    if (observed) 'sourcePrice': price,
    if (description.isNotEmpty) 'sourcePriceDetails': description,
  };
}

List<Json> links(
  SourcePage page,
  String selector,
  String kind, {
  String? nameSelector,
}) => [
  for (final e in page.document.querySelectorAll(selector))
    if (text(nameSelector == null ? e : e.querySelector(nameSelector))
            .isNotEmpty &&
        e.attributes['href'] != null)
      {
        'id': stableId(
          page.source,
          '${page.city}:$kind:${page.url(e.attributes['href']!)}',
        ),
        'network': page.source,
        'city': page.city,
        'kind': kind,
        'availabilityStatus': 'unverified',
        'name': text(nameSelector == null ? e : e.querySelector(nameSelector)),
        'source': page.url(e.attributes['href']!).toString(),
        'listingSource': page.uri.toString(),
        'checkedAt': page.date,
      },
];

List<Json> rows(
  SourcePage page,
  String selector,
  String nameSelector, {
  String kind = 'service',
  String? priceSelector,
}) => [
  for (final e in page.document.querySelectorAll(selector))
    if (text(e.querySelector(nameSelector)).isNotEmpty)
      {
        'id': stableId(
          page.source,
          '${page.city}:$kind:${page.uri}:${text(e.querySelector(nameSelector))}',
        ),
        'network': page.source,
        'city': page.city,
        'kind': kind,
        'availabilityStatus': 'unverified',
        'name': text(e.querySelector(nameSelector)),
        if (priceSelector != null)
          ...priceFields(text(e.querySelector(priceSelector))),
        'source': page.uri.toString(),
        'listingSource': page.uri.toString(),
        'checkedAt': page.date,
      },
];
