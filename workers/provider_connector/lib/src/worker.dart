import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf;

import 'fetcher.dart';
import 'parser.dart';

Future<Json> collect(
  NetworkParser parser,
  Json config,
  PublicFetcher fetcher,
  Future<void> Function() heartbeat,
) async {
  final branches = <Json>[], items = <String, Json>{}, statuses = <Json>[];
  final started = DateTime.now().toUtc();
  for (final spec in config['branchPages'] as List) {
    await heartbeat();
    final uri = Uri.parse(spec['url'] as String);
    final page = SourcePage(
      parser.source,
      spec['city'] as String,
      uri,
      await fetcher.get(uri),
      DateTime.now().toUtc(),
    );
    final entries = parser.branches(page);
    if (entries.isEmpty) throw const FormatException('branches_missing');
    branches.addAll(entries);
  }
  var totalPages = 0;
  for (final spec in config['cataloguePages'] as List) {
    final first = Uri.parse(spec['url'] as String);
    final visited = <Uri>{}, queue = <Uri>[first];
    var count = 0;
    String? error;
    try {
      while (queue.isNotEmpty) {
        if (totalPages >= (config['maxPages'] as int)) {
          throw const FetchFailure('page_limit');
        }
        final uri = queue.removeAt(0);
        if (!visited.add(uri)) continue;
        await heartbeat();
        final page = SourcePage(
          parser.source,
          spec['city'] as String,
          uri,
          await fetcher.get(uri),
          DateTime.now().toUtc(),
        );
        totalPages++;
        final found = parser.catalogue(page);
        if (found.isEmpty) throw const FormatException('catalogue_missing');
        for (final item in found) {
          // Ignore navigation to partner domains. It is not fetched or published.
          if (fetcher.allows(Uri.parse(item['source'] as String))) {
            items[item['id'] as String] = item;
            count++;
          }
        }
        for (final next in parser.nextPages(page)) {
          // Pagination remains inside the selected regional collection.
          if (!parser.acceptsNext(first, next) || !fetcher.allows(next)) {
            throw const FetchFailure('pagination_region_mismatch');
          }
          if (!visited.contains(next)) queue.add(next);
        }
      }
    } catch (e) {
      error = failureCode(e);
    }
    statuses.add({
      'url': first.toString(),
      'city': spec['city'],
      'status': error == null ? 'observed' : 'failed',
      'pages': visited.length,
      'items': count,
      'error': ?error,
    });
  }
  return {
    'schemaVersion': 1,
    'sourceId': parser.source,
    'parserVersion': config['parserVersion'],
    'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    'startedAt': started.toIso8601String(),
    'branches': branches,
    'items': items.values.toList(),
    'catalogueStatus': statuses,
  };
}

Future<void> runConnector(
  NetworkParser parser,
  String origin,
  List<String> args,
) async {
  final env = Platform.environment;
  final endpoint = Uri.parse(
    env['DIRECTORY_ENDPOINT'] ?? 'http://provider-directory:8086/',
  );
  if (args.contains('--health')) {
    final client = http.Client();
    try {
      final r = await client
          .get(Uri.parse('http://127.0.0.1:8090/health'))
          .timeout(const Duration(seconds: 2));
      exitCode = r.statusCode == 200 ? 0 : 1;
    } catch (_) {
      exitCode = 1;
    } finally {
      client.close();
    }
    return;
  }
  final key = env['DIRECTORY_CONNECTOR_KEY'];
  if (key == null || key.length < 32) {
    throw StateError('Missing connector credential');
  }
  final client = http.Client();
  Future<Json> post(String path, Json body) async {
    final request = http.Request('POST', endpoint.resolve(path))
      ..followRedirects = false
      ..headers.addAll({
        'authorization': 'Bearer $key',
        'content-type': 'application/json',
      })
      ..body = jsonEncode(body);
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 15));
    final bytes = await response.stream.toBytes().timeout(
      const Duration(seconds: 15),
    );
    if (response.statusCode != 200 || bytes.length > 1024 * 1024) {
      throw const FetchFailure('registry_unavailable');
    }
    return jsonDecode(utf8.decode(bytes)) as Json;
  }

  var stopping = false;
  DateTime? contacted;
  final health = await shelf.serve(
    (Request r) => Response(
      r.url.path == 'health' &&
              !stopping &&
              contacted != null &&
              DateTime.now().difference(contacted!) <
                  const Duration(seconds: 90)
          ? 200
          : 503,
      body: jsonEncode({'sourceId': parser.source, 'parserVersion': '1'}),
      headers: {'content-type': 'application/json'},
    ),
    env['CONNECTOR_BIND'] ?? '127.0.0.1',
    8090,
  );
  final done = Completer<void>();
  void stop() {
    stopping = true;
    if (!done.isCompleted) done.complete();
  }

  final signals = [
    ProcessSignal.sigterm.watch().listen((_) => stop()),
    ProcessSignal.sigint.watch().listen((_) => stop()),
  ];
  try {
    do {
      try {
        final response = await post(
          'internal/sources/${parser.source}/claim',
          {},
        );
        contacted = DateTime.now();
        final job = response['job'] as Json?;
        if (job != null) {
          final path = 'internal/sources/${parser.source}/jobs/${job['jobId']}';
          final config = job['config'] as Json;
          if (config['id'] != parser.source ||
              (config['allowedOrigins'] as List).length != 1 ||
              (config['allowedOrigins'] as List).single != origin) {
            throw const FetchFailure('source_mismatch');
          }
          final fetcher = PublicFetcher(
            client,
            origin,
            delay: Duration(
              milliseconds: (config['requestDelayMs'] as int).clamp(
                1000,
                60000,
              ),
            ),
          );
          Future<void> heartbeat() async {
            if (stopping) throw const FetchFailure('stopping');
            await post(path, {'action': 'heartbeat', 'lease': job['lease']});
            contacted = DateTime.now();
          }

          try {
            final data = await collect(parser, config, fetcher, heartbeat);
            // A lost completion response is replayed with the same immutable data.
            Object? lastError;
            for (var attempt = 0; attempt < 3; attempt++) {
              try {
                await post(path, {
                  'action': 'complete',
                  'lease': job['lease'],
                  'result': data,
                });
                lastError = null;
                break;
              } catch (e) {
                lastError = e;
                await Future<void>.delayed(const Duration(seconds: 2));
              }
            }
            if (lastError != null) throw lastError;
            stdout.writeln(
              jsonEncode({
                'sourceId': parser.source,
                'jobId': job['jobId'],
                'status': 'published',
              }),
            );
          } catch (e) {
            final code = failureCode(e);
            try {
              await post(path, {
                'action': 'fail',
                'lease': job['lease'],
                'error': code,
              });
            } catch (_) {
              /* lease recovery */
            }
            stdout.writeln(
              jsonEncode({
                'sourceId': parser.source,
                'status': 'failed',
                'error': code,
              }),
            );
          }
        }
      } catch (_) {
        stderr.writeln(
          jsonEncode({
            'sourceId': parser.source,
            'error': 'registry_unavailable',
          }),
        );
      }
      if (args.contains('--once')) break;
      await Future.any([
        done.future,
        Future<void>.delayed(const Duration(seconds: 15)),
      ]);
    } while (!stopping);
  } finally {
    for (final subscription in signals) {
      await subscription.cancel();
    }
    await health.close(force: true);
    client.close();
  }
}
