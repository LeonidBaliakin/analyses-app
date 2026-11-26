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
    ...links(
      p,
      'a[href*="/vrachi/vzroslyj-vrach/"], a[href*="/vrachi/detskij-vrach/"]',
      'doctor',
    ),
    ...rows(p, 'tr', 'td:first-child'),
  ];
}
