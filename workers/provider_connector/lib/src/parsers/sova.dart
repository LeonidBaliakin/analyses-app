import '../parser.dart';

final class SovaParser extends NetworkParser {
  @override
  String get source => 'sova';
  @override
  List<Json> branches(SourcePage p) => [
    for (final e in p.document.querySelectorAll('a[href*="/contact-us/"]'))
      if (text(e).isNotEmpty && RegExp(r'\d').hasMatch(text(e)))
        p.branch(
          identity: e.attributes['href']!,
          name: 'СОВА · ${text(e)}',
          address: 'Воронеж, ${text(e)}',
          website: e.attributes['href']!,
          phone: '+7 (473) 373-03-03',
          phoneScope: 'city',
        ),
  ];
  @override
  List<Json> catalogue(SourcePage p) => [
    for (final e in p.document.querySelectorAll('.staff-card'))
      if (e.querySelector('a.staff-card__title[href]') case final a?)
        {
          'id': stableId(
            source,
            '${p.city}:doctor:${p.url(a.attributes['href']!)}',
          ),
          'network': source,
          'city': p.city,
          'kind': 'doctor',
          'name': text(a),
          'sourceSpecialty': text(
            e.querySelector('.staff-card__column-2 > .staff-card__text'),
          ),
          'sourceLocation': text(e.querySelector('.staff-card__clinic-change')),
          ...priceFields(text(e.querySelector('.staff-cart_price-wrap'))),
          'availabilityStatus': 'unverified',
          'source': p.url(a.attributes['href']!).toString(),
          'listingSource': p.uri.toString(),
          'checkedAt': p.date,
        },
    ...rows(
      p,
      'tr',
      'td:first-child',
      kind: 'service',
      priceSelector: 'td:last-child',
    ),
  ];
  @override
  List<Uri> nextPages(SourcePage page) => [
    for (final a in page.document.querySelectorAll('a[href*="PAGEN_1="]'))
      if (page.url(a.attributes['href']!).path == page.uri.path)
        page.url(a.attributes['href']!),
  ];
}
