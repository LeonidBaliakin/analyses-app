import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class FetchFailure implements Exception {
  const FetchFailure(this.code);
  final String code;
}

/// Only the source's compiled origin is reachable. Redirects cannot expand it.
class PublicFetcher {
  PublicFetcher(
    this.client,
    this.origin, {
    this.delay = const Duration(seconds: 2),
    this.maxBytes = 8 * 1024 * 1024,
    this.timeout = const Duration(seconds: 20),
  });
  final http.Client client;
  final String origin;
  final Duration delay, timeout;
  final int maxBytes;
  DateTime? _last;
  String? _robots;

  bool allows(Uri uri) =>
      uri.scheme == 'https' && uri.origin == origin && uri.userInfo.isEmpty;

  Future<String> _read(Uri url) async {
    var uri = url;
    for (var redirect = 0; redirect < 4; redirect++) {
      if (!allows(uri)) throw const FetchFailure('origin_denied');
      if (_last != null) {
        final wait = delay - DateTime.now().difference(_last!);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _last = DateTime.now();
      final request = http.Request('GET', uri)..followRedirects = false;
      request.headers['user-agent'] = 'AnalysesDirectory/1.0';
      request.headers['accept'] = 'text/html,application/json,text/plain;q=0.5';
      final response = await client.send(request).timeout(timeout);
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers['location'];
        if (location == null) throw const FetchFailure('bad_redirect');
        await response.stream.drain<void>().timeout(timeout);
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        // Closing the stream releases the connection; never save error pages.
        await response.stream.take(1).drain<void>().timeout(timeout);
        throw FetchFailure('http_${response.statusCode}');
      }
      final bytes = <int>[];
      final subscription = response.stream.listen(null);
      final done = Completer<void>();
      subscription.onData((chunk) {
        if (bytes.length + chunk.length > maxBytes) {
          unawaited(subscription.cancel());
          if (!done.isCompleted) {
            done.completeError(const FetchFailure('response_too_large'));
          }
        } else {
          bytes.addAll(chunk);
        }
      });
      subscription.onError((Object e, StackTrace st) {
        if (!done.isCompleted) done.completeError(e, st);
      });
      subscription.onDone(() {
        if (!done.isCompleted) done.complete();
      });
      try {
        await done.future.timeout(timeout);
      } finally {
        await subscription.cancel();
      }
      return utf8.decode(bytes);
    }
    throw const FetchFailure('too_many_redirects');
  }

  Future<String> get(Uri uri) async {
    if (!allows(uri)) throw const FetchFailure('origin_denied');
    if (_robots == null) {
      try {
        _robots = await _read(Uri.parse('$origin/robots.txt'));
      } on FetchFailure catch (e) {
        if (e.code == 'http_404') {
          _robots = '';
        } else {
          rethrow;
        }
      }
    }
    if (!robotsAllow(_robots!, uri)) throw const FetchFailure('robots_denied');
    return _read(uri);
  }
}

bool robotsAllow(String content, Uri uri) {
  final groups =
      <({List<String> agents, List<({bool allow, String path})> rules})>[];
  var agents = <String>[], rules = <({bool allow, String path})>[];
  var hadDirective = false;
  for (final original
      in content.replaceFirst(RegExp('^\uFEFF'), '').split('\n')) {
    final line = original.split('#').first.trim(), colon = line.indexOf(':');
    if (colon < 0) continue;
    final key = line.substring(0, colon).trim().toLowerCase(),
        value = line.substring(colon + 1).trim();
    if (key == 'user-agent') {
      if (hadDirective) {
        groups.add((agents: agents, rules: rules));
        agents = [];
        rules = [];
        hadDirective = false;
      }
      agents.add(value.toLowerCase());
    } else if ((key == 'allow' || key == 'disallow') && agents.isNotEmpty) {
      hadDirective = true;
      if (value.isNotEmpty) rules.add((allow: key == 'allow', path: value));
    }
  }
  groups.add((agents: agents, rules: rules));
  int specificity(List<String> agents) => agents
      .where(
        (a) => a.isNotEmpty && a != '*' && 'analysesdirectory'.startsWith(a),
      )
      .fold(0, (length, a) => a.length > length ? a.length : length);
  final longest = groups.fold(
    0,
    (length, g) =>
        specificity(g.agents) > length ? specificity(g.agents) : length,
  );
  final specific = groups
      .where((g) => longest > 0 && specificity(g.agents) == longest)
      .toList();
  final selected = specific.isNotEmpty
      ? specific
      : groups.where((g) => g.agents.contains('*')).toList();
  final target = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
  var length = -1, allow = true;
  for (final g in selected) {
    for (final r in g.rules) {
      var pattern = RegExp.escape(r.path).replaceAll(r'\*', '.*');
      if (pattern.endsWith(r'\$')) {
        pattern = '${pattern.substring(0, pattern.length - 2)}\$';
      }
      final score = r.path.replaceAll('*', '').replaceAll(r'$', '').length;
      if (RegExp('^$pattern').hasMatch(target) &&
          (score > length || (score == length && r.allow))) {
        length = score;
        allow = r.allow;
      }
    }
  }
  return allow;
}

String failureCode(Object error) => switch (error) {
  FetchFailure e => e.code,
  TimeoutException() => 'timeout',
  FormatException() => 'markup_changed',
  _ => 'fetch_failed',
};
