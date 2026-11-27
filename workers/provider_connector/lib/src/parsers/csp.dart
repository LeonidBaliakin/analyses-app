import '../parser.dart';

final class CspParser extends NetworkParser {
  @override
  String get source => 'csp';
  @override
  List<Json> branches(SourcePage p) => [
    for (final e in p.document.querySelectorAll('.div100.contmap[id]'))
      p.branch(
        identity: e.id,
        name: 'ЦСП · ${text(e.querySelector('h3'))}',
        address: 'Воронеж, ${text(e.querySelector('h3'))}',
        website: '#${e.id}',
        phone: text(e.querySelector('a[href^="tel:"]')),
        phoneScope: 'branch',
        phoneObserved: true,
      ),
  ];
  @override
  List<Json> catalogue(SourcePage p) => [
    ...links(
      p,
      '.link_cardspec[href*="/catlab/"]',
      'category',
      nameSelector: 'h2',
    ),
    ...links(
      p,
      '.link_cardspec[href*="/catuzspecialist/"]',
      'specialty',
      nameSelector: 'h2',
    ),
    for (final e in p.document.querySelectorAll(
      '.link_cardspec[href*="/team/"]',
    ))
      ...links(
            p,
            '.link_cardspec[href="${e.attributes['href']}"]',
            'doctor',
            nameSelector: 'h2',
          )
          .take(1)
          .map((v) => {...v, 'sourceSpecialty': text(e.querySelector('p'))}),
    ...links(p, '.link_carddoctor[href], .link_doctor[href]', 'doctor'),
    // Both appointment and lab categories publish tariffs in the service
    // card itself. Its URL identifies the offer, not a matched doctor's name.
    for (final card in p.document.querySelectorAll(
      '.link_cardservice[href*="/analysis/"], '
      '.link_cardservice[href*="/uzspecialist/"], '
      '.link_cardservice[href*="/vaccine/"]',
    ))
      ...links(
            p,
            '.link_cardservice[href="${card.attributes['href']}"]',
            p.url(card.attributes['href']!).path.startsWith('/analysis/')
                ? 'test'
                : 'service',
            nameSelector: 'h4',
          )
          .take(1)
          .map(
            (v) => {
              ...v,
              ...priceFields(text(card.querySelector('.txt_priceh'))),
            },
          ),
    ...rows(p, 'tr', 'td:first-child'),
  ];
  @override
  List<Uri> nextPages(SourcePage page) => [
    for (final a in page.document.querySelectorAll(
      '.link_cardspec[href*="/catlab/"], .link_cardspec[href*="/catuzspecialist/"]',
    ))
      page.url(a.attributes['href']!),
  ];
  @override
  bool acceptsNext(Uri first, Uri next) => first.path == '/analysis/'
      ? next.path.startsWith('/catlab/')
      : next.path.startsWith('/catuzspecialist/');
}
