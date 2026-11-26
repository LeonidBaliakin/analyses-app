import '../parser.dart';

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
  @override
  List<Json> catalogue(SourcePage p) => [
    ...links(
      p,
      '.analyzes-item a[href], .catalog-item a[href], .catalog-item__title[href]',
      'test',
    ),
    ...rows(
      p,
      '.analyzes-item, .catalog-item',
      'h2, h3, .analyzes-item__title',
      kind: 'test',
    ),
  ];
}
