import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider_connector/src/fetcher.dart';
import 'package:provider_connector/src/worker.dart';
import 'package:provider_connector/provider_connector.dart';
import 'package:test/test.dart';

void main() {
  test('robots longest rule, explicit group and allow tie are honored', () {
    expect(
      robotsAllow(
        'User-agent: *\nDisallow: /\nAllow: /public',
        Uri.parse('https://a/public/1'),
      ),
      isTrue,
    );
    expect(
      robotsAllow(
        'User-agent: *\nDisallow: /private',
        Uri.parse('https://a/private'),
      ),
      isFalse,
    );
    expect(
      robotsAllow(
        'User-agent: *\nAllow: /\nUser-agent: AnalysesDirectory\nDisallow: /',
        Uri.parse('https://a/public'),
      ),
      isFalse,
    );
    expect(
      robotsAllow(
        'User-agent: *\nDisallow: /*?secret=*',
        Uri.parse('https://a/path?secret=1'),
      ),
      isFalse,
    );
    expect(
      robotsAllow(
        '\uFEFFUser-agent: *\nDisallow: /private',
        Uri.parse('https://a/private'),
      ),
      isFalse,
    );
    expect(
      robotsAllow(
        'User-agent: *\nDisallow:\nUser-agent: Other\nDisallow: /',
        Uri.parse('https://a/public'),
      ),
      isTrue,
    );
  });
  test(
    'redirect cannot escape source origin; denied destination is never called',
    () async {
      final called = <Uri>[];
      final client = MockClient((r) async {
        called.add(r.url);
        return r.url.path == '/robots.txt'
            ? http.Response('', 200)
            : http.Response(
                '',
                302,
                headers: {'location': 'http://127.0.0.1/private'},
              );
      });
      addTearDown(client.close);
      final fetcher = PublicFetcher(
        client,
        'https://example.org',
        delay: Duration.zero,
      );
      await expectLater(
        fetcher.get(Uri.parse('https://example.org/list')),
        throwsA(
          isA<FetchFailure>().having((e) => e.code, 'code', 'origin_denied'),
        ),
      );
      expect(called.map((u) => u.host).toSet(), {'example.org'});
    },
  );
  test('robots denial prevents catalogue request', () async {
    var requests = 0;
    final client = MockClient((r) async {
      requests++;
      return http.Response('User-agent: *\nDisallow: /', 200);
    });
    addTearDown(client.close);
    await expectLater(
      PublicFetcher(
        client,
        'https://example.org',
        delay: Duration.zero,
      ).get(Uri.parse('https://example.org/list')),
      throwsA(
        isA<FetchFailure>().having((e) => e.code, 'code', 'robots_denied'),
      ),
    );
    expect(requests, 1);
  });
  test('oversized and timed out source responses fail explicitly', () async {
    final client = MockClient(
      (r) async =>
          http.Response(r.url.path == '/robots.txt' ? '' : 'x' * 100, 200),
    );
    addTearDown(client.close);
    await expectLater(
      PublicFetcher(
        client,
        'https://example.org',
        delay: Duration.zero,
        maxBytes: 10,
      ).get(Uri.parse('https://example.org/list')),
      throwsA(isA<FetchFailure>()),
    );
    final stalled = MockClient((r) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response('', 200);
    });
    addTearDown(stalled.close);
    await expectLater(
      PublicFetcher(
        stalled,
        'https://example.org',
        delay: Duration.zero,
        timeout: const Duration(milliseconds: 1),
      ).get(Uri.parse('https://example.org/list')),
      throwsA(isA<TimeoutException>()),
    );
  });
  test(
    'empty/malformed branches cannot be published as an empty catalogue',
    () async {
      final client = MockClient(
        (r) async => http.Response(
          r.url.path == '/robots.txt' ? '' : '<h1>Site changed</h1>',
          200,
        ),
      );
      addTearDown(client.close);
      await expectLater(
        collect(
          CspParser(),
          {
            'branchPages': [
              {'url': 'https://example.org/list', 'city': 'voronezh'},
            ],
          },
          PublicFetcher(client, 'https://example.org', delay: Duration.zero),
          () async {},
        ),
        throwsFormatException,
      );
    },
  );
  test('catalogue failure keeps contacts usable and explicitly marks partial result', () async {
    final client = MockClient(
      (r) async => http.Response(
        switch (r.url.path) {
          '/list' => '<div class="div100 contmap" id="one"><h3>Синтетическая, 1</h3><a href="tel:1">1</a></div>',
          '/catalogue' => 'Site changed',
          _ => '',
        },
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );
    addTearDown(client.close);
    final result = await collect(
      CspParser(),
      {
        'parserVersion': '1',
        'maxPages': 10,
        'branchPages': [
          {'url': 'https://example.org/list', 'city': 'voronezh'},
        ],
        'cataloguePages': [
          {'url': 'https://example.org/catalogue', 'city': 'voronezh'},
        ],
      },
      PublicFetcher(client, 'https://example.org', delay: Duration.zero),
      () async {},
    );
    expect(result['branches'], hasLength(1));
    expect(result['catalogueStatus'], [containsPair('status', 'failed')]);
  });
}
