import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf;

import 'fetcher.dart';
import 'parser.dart';

Uri canonicalPage(Uri uri) => uri.hasQuery
    ? uri.removeFragment().replace(
        queryParameters: {
          for (final key in (uri.queryParametersAll.keys.toList()..sort()))
            key: uri.queryParametersAll[key]!,
        },
      )
    : uri.removeFragment();

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
    final visited = <Uri>{},
        queue = <Uri>[canonicalPage(parser.initialPage(first))],
        ids = <String>{};
    final failures = <Json>[];
    final signatures = <String>{};
    int? expected;
    var successfulPages = 0, observedRows = 0;
    while (queue.isNotEmpty) {
      final uri = queue.removeAt(0);
      if (!visited.add(uri)) continue;
      if (totalPages >= (config['maxPages'] as int)) {
        failures.add({'url': uri.toString(), 'error': 'page_limit'});
        break;
      }
      totalPages++;
      // Registry/lease failures abort the job; they are not website page gaps.
      await heartbeat();
      // A failed child must not discard the remaining discovered inventory.
      try {
        final page = SourcePage(
          parser.source,
          spec['city'] as String,
          uri,
          await fetcher.get(uri),
          DateTime.now().toUtc(),
        );
        final found = parser.catalogue(page);
        final total = parser.expectedItems(page);
        if (total != null) {
          if (expected != null && expected != total) {
            throw const FetchFailure('inventory_changed');
          }
          expected = total;
        }
        final nextPages = parser.nextPages(page);
        if (found.isEmpty && !parser.emptyAllowed(page) && nextPages.isEmpty) {
          throw const FormatException('catalogue_missing');
        }
        if (expected != null && found.isNotEmpty) {
          final signature = stableId(
            parser.source,
            jsonEncode([
              for (final item in found)
                [
                  for (final key in [
                    'id',
                    'name',
                    'sourcePrice',
                    'sourceSpecialty',
                    'sourceLocation',
                  ])
                    item[key],
                ],
            ]),
          );
          if (!signatures.add(signature)) {
            throw const FetchFailure('repeated_inventory_page');
          }
        }
        for (final item in found) {
          if (fetcher.allows(Uri.parse(item['source'] as String))) {
            observedRows++;
            final id = item['id'] as String;
            items[id] = mergeObservation(items[id], item);
            ids.add(id);
          }
        }
        for (final discovered in nextPages) {
          final next = canonicalPage(discovered);
          if (!parser.acceptsNext(first, next) || !fetcher.allows(next)) {
            failures.add({
              'url': next.toString(),
              'error': 'pagination_region_mismatch',
            });
          } else if (!visited.contains(next) && !queue.contains(next)) {
            queue.add(next);
          }
        }
        successfulPages++;
      } catch (e) {
        failures.add({'url': uri.toString(), 'error': failureCode(e)});
      }
    }
    if (expected != null && expected != observedRows) {
      failures.add({
        'url': first.toString(),
        'error': 'inventory_count_mismatch',
      });
    }
    statuses.add({
      'url': first.toString(),
      'city': spec['city'],
      'status': failures.isEmpty ? 'observed' : 'failed',
      'coverage': failures.isEmpty ? 'complete' : 'partial',
      'coverageMethod': expected == null
          ? parser.coverageMethod
          : 'source_total',
      'pages': visited.length,
      'successfulPages': successfulPages,
      'pendingPages': queue.length,
      'items': ids.length,
      'observedRows': observedRows,
      'duplicateRows': observedRows - ids.length,
      'expectedItems': ?expected,
      if (failures.isNotEmpty) ...{
        'error': failures.first['error'],
        'failures': failures,
      },
    });
  }
  return {
    'schemaVersion': 1,
    'sourceId': parser.source,
    'parserVersion': parser.version,
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
    if (bytes.length > 1024 * 1024) {
      throw const FetchFailure('registry_unavailable');
    }
    if (response.statusCode != 200) {
      // Surface only the registry's bounded technical code, never its body or
      // credentials. A rejected import is different from a network outage.
      final error = (jsonDecode(utf8.decode(bytes)) as Json)['error'];
      throw FetchFailure(
        error is String && RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(error)
            ? 'registry_$error'
            : 'registry_http_${response.statusCode}',
      );
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
      body: jsonEncode({
        'sourceId': parser.source,
        'parserVersion': parser.version,
      }),
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
          final fetcher = PublicFetcher(
            client,
            origin,
            publicCatalogueRequest: parser.publicCatalogueRequest,
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
            if (config['parserVersion'] != parser.version ||
                config['id'] != parser.source ||
                (config['allowedOrigins'] as List).length != 1 ||
                (config['allowedOrigins'] as List).single != origin) {
              throw const FetchFailure('source_mismatch');
            }
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
