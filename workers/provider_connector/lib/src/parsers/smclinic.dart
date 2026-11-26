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
    ...links(
      p,
      '.doctor-card__top[href]',
      'doctor',
      nameSelector: '.doctor-card__name',
    ),
    ...links(
      p,
      'a[href*="/diagnostika-analizi/laboratoria/"]:not(.b-analyzes-lab__button)',
      'category',
    ),
    ...rows(
      p,
      'tr.price__row',
      '.name_cell',
      kind: p.uri.path.startsWith('/diagnostika-analizi/') ? 'test' : 'service',
      priceSelector: '.price__cell',
    ),
  ];
  @override
  List<Uri> nextPages(SourcePage page) => [
    if (page.uri.path == '/doctor')
      for (final a in page.document.querySelectorAll(
        '.specialists-list__link[href^="/doctor/"]',
      ))
        page.url(a.attributes['href']!),
    if (page.uri.path == '/diagnostika-analizi')
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
