import '../parser.dart';
import '../pagination.dart';

final class ScandinaviaParser extends NetworkParser {
  @override
  String get source => 'scandinavia';
  @override
  List<Json> branches(SourcePage p) => [
    for (final e in p.document.querySelectorAll('.offices_card[data-id]'))
      if (e.querySelector('.offices_cardTitle') case final a?)
        if (text(e.querySelector('.offices_cardAddress'))
            .contains('Санкт-Петербург'))
          p.branch(
            identity: e.attributes['data-id']!,
            name: 'Скандинавия · ${text(a)}',
            address: text(e.querySelector('.offices_cardAddress')),
            website:
                a.attributes['href'] ??
                a.querySelector('a')!.attributes['href']!,
            phone: text(e.querySelector('.offices_cardPhone')),
            phoneObserved: true,
          ),
  ];
  @override
  List<Json> catalogue(SourcePage p) {
    if (p.uri.path == '/doctors/') {
      return [
        for (final e in p.document.querySelectorAll('.doctorsList_item[href]'))
          ...links(
                p,
                '.doctorsList_item[href="${e.attributes['href']}"]',
                'doctor',
                nameSelector: '.doctorsList_itemNameLabel',
              )
              .take(1)
              .map(
                (v) => {
                  ...v,
                  'sourceSpecialty': text(
                    e.querySelector(
                      '.doctorsList_itemSpeciality, .doctorsList_itemSpecialty',
                    ),
                  ),
                },
              ),
      ];
    }
    if (p.uri.path == '/prices/') {
      return [
        for (final e in p.document.querySelectorAll('.pricesSection_item'))
          if (text(e.querySelector('.pricesSection_name')).isNotEmpty)
            {
              'id': stableId(
                source,
                '${p.city}:service:${text(e.querySelector('.pricesSection_name'))}',
              ),
              'network': source,
              'city': p.city,
              'kind': 'service',
              'name': text(e.querySelector('.pricesSection_name')),
              ...priceFields(
                text(e.querySelector('.pricesSection_value.primary')),
                details: text(e.querySelector('.pricesSection_values')),
              ),
              'availabilityStatus': 'unverified',
              'source': p.uri.toString(),
              'listingSource': p.uri.toString(),
              'checkedAt': p.date,
            },
      ];
    }
    return rows(
      p,
      '.sectionPrice',
      '.sectionPrice_name',
      kind: 'test',
      priceSelector: '.sectionPrice_price',
    );
  }

  @override
  int? expectedItems(SourcePage page) => int.tryParse(
    page.document
            .querySelector('[data-total-count]')
            ?.attributes['data-total-count'] ??
        '',
  );
  @override
  Uri initialPage(Uri configured) => configured.path == '/prices/'
      ? Uri.parse('${configured.origin}${configured.path}')
      : configured;
  @override
  List<Uri> nextPages(SourcePage page) {
    final total = expectedItems(page);
    final doctors = page.uri.path == '/doctors/';
    final size = doctors ? 12 : 20;
    final current = doctors
        ? int.tryParse(page.uri.queryParameters['PAGEN_1'] ?? '1')
        : int.tryParse(
            (page.uri.queryParameters['SERVICE_NAV'] ?? 'page-1').replaceFirst(
              'page-',
              '',
            ),
          );
    if (total != null && current == 1) {
      return [
        for (
          var n = 2;
          n <= 1 + ((total - catalogue(page).length) / size).ceil();
          n++
        )
          page.uri.replace(
            queryParameters: doctors
                ? {'PAGEN_1': '$n', 'ajax': 'Y'}
                : {'SERVICE_NAV': 'page-$n', 'ajax': 'Y', 'APPEND': 'Y'},
          ),
      ];
    }
    // The first page scheduled the complete range; do not follow cached
    // show-more buttons past the reported end of the collection.
    if (total != null) return [];
    return [
      for (final a in page.document.querySelectorAll(
        'a.generalPagination_page.next[href]',
      ))
        page
            .url(a.attributes['href']!)
            .replace(
              queryParameters: {
                ...page.url(a.attributes['href']!).queryParameters,
                'ajax': 'Y',
              },
            ),
      for (final a in page.document.querySelectorAll(
        '.js_showMoreAjax[data-href]',
      ))
        page
            .url(a.attributes['data-href']!)
            .replace(
              queryParameters: {
                ...page.url(a.attributes['data-href']!).queryParameters,
                'ajax': 'Y',
                'APPEND': 'Y',
              },
            ),
    ];
  }

  @override
  bool publicCatalogueRequest(Uri uri) =>
      uri.origin == 'https://www.avaclinic.ru' &&
      uri.queryParameters['ajax'] == 'Y' &&
      ((uri.path == '/doctors/' &&
              onlyParameters(uri, {'PAGEN_1', 'ajax'}) &&
              (int.tryParse(uri.queryParameters['PAGEN_1'] ?? '') ?? 0) >= 2) ||
          (uri.path == '/prices/' &&
              onlyParameters(uri, {'SERVICE_NAV', 'ajax', 'APPEND'}) &&
              uri.queryParameters['APPEND'] == 'Y' &&
              RegExp(r'^page-[1-9][0-9]*$')
                  .hasMatch(uri.queryParameters['SERVICE_NAV'] ?? '')));
}
