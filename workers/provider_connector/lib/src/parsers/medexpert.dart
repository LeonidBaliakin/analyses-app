import '../parser.dart';

final class MedexpertParser extends NetworkParser {
  @override
  String get source => 'medexpert';
  @override
  List<Json> branches(SourcePage p) => [
    for (final e in p.document.querySelectorAll('a.service_1[href*="center="]'))
      if (text(e.querySelector('.med_points_hover')).contains('г. Воронеж'))
        p.branch(
          identity: p.url(e.attributes['href']!).queryParameters['center']!,
          name: 'МедЭксперт · ${text(e.querySelector('.med_point_status'))}',
          address: text(e.querySelector('.med_points_hover')),
          website: e.attributes['href']!,
          phone: '+7 (800) 333-08-00',
        ),
  ];
  @override
  List<Json> catalogue(SourcePage p) => [
    for (final e in p.document.querySelectorAll('a.speci_a[data-target]'))
      {
        'id': stableId(source, 'doctor:${e.attributes['data-target']}'),
        'sourceId': e.attributes['data-target'],
        'network': source,
        'city': p.city,
        'kind': 'doctor',
        'availabilityStatus': 'unverified',
        'name': text(e.querySelector('.doc_meta')),
        'sourceSpecialty': text(e.querySelector('.doc_job')),
        'source': '${p.uri}#${e.attributes['data-target']}',
        'checkedAt': p.date,
      },
    for (final e in p.document.querySelectorAll('.price_table_boxes'))
      if (e.querySelector('label[data-name][id]') case final label?)
        {
          'id': stableId(source, '${p.city}:service:${label.id}'),
          'sourceId': label.id,
          'network': source,
          'city': p.city,
          'kind': 'service',
          'availabilityStatus': 'unverified',
          'name': label.attributes['data-name'],
          'sourceCategory': label.attributes['data-category'],
          if ((e
                      .querySelector('.about_centers[data-centers]')
                      ?.attributes['data-centers'] ??
                  label.attributes['data-centers'])
              case final String centers when centers.isNotEmpty)
            'sourceCenters': centers,
          ...priceFields(
            text(e.querySelector('.block_2_price')),
            details: text(e.querySelector('.block_2')),
          ),
          'source': '${p.uri}#${label.id}',
          'listingSource': p.uri.toString(),
          'checkedAt': p.date,
        },
  ];
}
