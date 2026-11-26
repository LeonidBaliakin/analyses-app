import '../parser.dart';

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
  List<Json> catalogue(SourcePage p) => [
    ...links(
      p,
      '.doctorsList_item[href]',
      'doctor',
      nameSelector: '.doctorsList_itemNameLabel',
    ),
    ...rows(
      p,
      '.sectionPrice',
      '.sectionPrice_name',
      kind: 'test',
      priceSelector: '.sectionPrice_price',
    ),
  ];
  @override
  List<Uri> nextPages(SourcePage page) => [
    for (final a in page.document.querySelectorAll(
      'a.generalPagination_page.next[href]',
    ))
      page.url(a.attributes['href']!),
  ];
}
