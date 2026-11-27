import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider_connector/provider_connector.dart';
import 'package:provider_connector/src/fetcher.dart';
import 'package:provider_connector/src/worker.dart';
import 'package:test/test.dart';

class InventoryParser extends NetworkParser {
  @override
  String get source => 'synthetic';
  @override
  List<Json> branches(SourcePage p) => [
    p.branch(
      identity: 'one',
      name: 'Synthetic',
      address: 'Synthetic street, 1',
      website: '/branch',
      phone: '',
    ),
  ];
  @override
  List<Json> catalogue(SourcePage p) => p.body == 'broken'
      ? []
      : [
          {
            'id': 'synthetic-${p.uri.pathSegments.last}',
            'network': source,
            'city': p.city,
            'kind': 'service',
            'name': p.body,
            'source': p.uri.toString(),
            'checkedAt': p.date,
          },
        ];
  @override
  List<Uri> nextPages(SourcePage p) =>
      p.uri.path == '/catalogue' ? [p.url('/bad'), p.url('/last')] : [];
  @override
  bool acceptsNext(Uri first, Uri next) => true;
}

void main() {
  test('query ordering does not fetch the same pagination page twice', () {
    expect(
      canonicalPage(Uri.parse('https://example.org/list?ajax=Y&page=2')),
      canonicalPage(Uri.parse('https://example.org/list?page=2&ajax=Y')),
    );
  });
  test('lost lease aborts immediately instead of treating every page as a site error', () async {
    final client = MockClient((r) async => http.Response('', 200));
    addTearDown(client.close);
    var calls = 0;
    await expectLater(
      collect(
        InventoryParser(),
        {
          'maxPages': 20,
          'branchPages': [],
          'cataloguePages': [
            {'url': 'https://example.org/catalogue', 'city': 'spb'},
          ],
        },
        PublicFetcher(client, 'https://example.org', delay: Duration.zero),
        () async {
          calls++;
          throw const FetchFailure('stopping');
        },
      ),
      throwsA(isA<FetchFailure>().having((e) => e.code, 'code', 'stopping')),
    );
    expect(calls, 1);
  });

  test('a failed child page does not truncate later inventory pages', () async {
    final requested = <String>[];
    final client = MockClient((r) async {
      requested.add(r.url.path);
      return http.Response(switch (r.url.path) {
        '/robots.txt' => '',
        '/bad' => 'broken',
        _ => 'Synthetic item',
      }, 200);
    });
    addTearDown(client.close);
    final result = await collect(
      InventoryParser(),
      {
        'parserVersion': '1',
        'maxPages': 20,
        'branchPages': [
          {'url': 'https://example.org/branch', 'city': 'spb'},
        ],
        'cataloguePages': [
          {'url': 'https://example.org/catalogue', 'city': 'spb'},
        ],
      },
      PublicFetcher(client, 'https://example.org', delay: Duration.zero),
      () async {},
    );
    expect(
      requested,
      contains('/last'),
      reason: 'One changed category must not stop all following categories',
    );
    expect(
      (result['items'] as List).any((j) => j['id'] == 'synthetic-last'),
      isTrue,
    );
    expect(
      (result['catalogueStatus'] as List).single['status'],
      'failed',
      reason: 'A gap remains visible even when later pages succeed',
    );
  });
}
