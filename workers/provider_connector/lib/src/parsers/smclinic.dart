import '../parser.dart';

final class SmclinicParser extends NetworkParser {
  @override
  String get source => 'smclinic';
  @override
  List<Json> branches(SourcePage p) => [
    for (final e in p.document.querySelectorAll(
      '.b-clinics_map--info-clinic_info-item',
    ))
      if (e.querySelector(
            '.b-clinics_map--info-clinic_info-item--clinics_info-title-top a',
          )
          case final a?)
        p.branch(
          identity: a.attributes['href']!,
          name: 'СМ-Клиника · ${text(a)}',
          address: 'Санкт-Петербург, ${text(a)}',
          website: a.attributes['href']!,
          phone: '+7 (812) 435-55-55',
        ),
  ];
  @override
  List<Json> catalogue(SourcePage p) => [
    ...links(p, '.specialists-list__link[href]', 'specialty'),
    for (final card in p.document.querySelectorAll('.doctor-card'))
      if (card.querySelector(
            '.doctor-card__top[href], a.doctor-card__cell[href]',
          )
          case final a?)
        if (text(a.querySelector('.doctor-card__name')).isNotEmpty)
          {
            'id': stableId(
              source,
              '${p.city}:doctor:${p.url(a.attributes['href']!)}',
            ),
            'network': source,
            'city': p.city,
            'kind': 'doctor',
            'name': text(a.querySelector('.doctor-card__name')),
            'sourceSpecialty': text(card.querySelector('.doctor-card__spec')),
            'sourceLocation': text(
              card.querySelector(
                '.doctor-card__metro, [class^="slider-metro-"]',
              ),
            ),
            'availabilityStatus': 'unverified',
            'source': p.url(a.attributes['href']!).toString(),
            'listingSource': p.uri.toString(),
            'checkedAt': p.date,
          },
    ...links(
      p,
      'a[href*="/diagnostika-analizi/laboratoria/"]:not(.b-analyzes-lab__button)',
      'category',
    ),
    // Some published tests have an individual descriptive page without a
    // tariff table. Preserve its exact title and explicit absence of a price.
    if (p.document.querySelector('tr.price__row') == null &&
        p.uri.path.startsWith('/diagnostika-analizi/laboratoria/') &&
        p.document.querySelector(
              r'.breadcrumbs a[href$="/laboratoria"], .breadcrumbs a[href$="/laboratoria/"]',
            ) !=
            null)
      if (p.document.querySelector('h1.h1_speciality') case final heading?)
        if (text(heading).isNotEmpty)
          {
            'id': stableId(source, '${p.city}:test:${p.uri}'),
            'network': source,
            'city': p.city,
            'kind': 'test',
            'name': text(heading),
            'availabilityStatus': 'unverified',
            'sourcePriceStatus': 'not_observed',
            'source': p.uri.toString(),
            'listingSource': p.uri.toString(),
            'checkedAt': p.date,
          },
    ...rows(
      p,
      'tr.price__row',
      '.name_cell',
      kind: p.uri.path.startsWith('/diagnostika-analizi/') ? 'test' : 'service',
      priceSelector: '.price__cell',
    ),
    // The general price list is a different template. Its second price is an
    // instalment, not a cheaper tariff. Folder rows have no td.name/data-code.
    for (final row in p.document.querySelectorAll(
      '.pricelist tr, .global-price tr',
    ))
      if (row.querySelector('td.name[data-code]') case final name?)
        if (text(name).isNotEmpty && name.attributes['data-code']!.isNotEmpty)
          {
            'id': stableId(
              source,
              '${p.city}:service:code:${name.attributes['data-code']}',
            ),
            'network': source,
            'city': p.city,
            'kind': 'service',
            'name': text(name),
            'sourceCode': name.attributes['data-code'],
            ...priceFields(
              text(row.querySelector('td.price:not(.js-price-part)')),
              details: [
                'Цена (руб.): ${text(row.querySelector('td.price:not(.js-price-part)'))}',
                if (row.querySelector('td.js-price-part') case final part?)
                  'В рассрочку*: ${text(part)}',
              ].join('; '),
            ),
            'currency': 'RUB',
            'availabilityStatus': 'unverified',
            'source': p.uri.toString(),
            'listingSource': p.uri.toString(),
            'checkedAt': p.date,
          },
  ];
  @override
  List<Uri> nextPages(SourcePage page) => [
    if (page.uri.path == '/doctor')
      for (final a in page.document.querySelectorAll(
        '.specialists-list__link[href^="/doctor/"]',
      ))
        page.url(a.attributes['href']!),
    if (page.uri.path.startsWith('/diagnostika-analizi'))
      for (final a in page.document.querySelectorAll(
        'a[href^="/diagnostika-analizi/laboratoria/"]:not(.b-analyzes-lab__button)',
      ))
        page.url(a.attributes['href']!),
  ];
  @override
  bool acceptsNext(Uri first, Uri next) => first.path == '/doctor'
      ? next.path.startsWith('/doctor/')
      : next.path.startsWith('/diagnostika-analizi/laboratoria/');
}
