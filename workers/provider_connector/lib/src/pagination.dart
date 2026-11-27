import 'parser.dart';

int sourceTotal(Json data) {
  final total = data['total'];
  if (total is! int || total < 0 || total > 30000) {
    throw const FormatException('invalid_source_total');
  }
  return total;
}

List<Uri> offsetPages(
  SourcePage p,
  Json data,
  String offsetKey,
  String limitKey,
) {
  final total = sourceTotal(data);
  final offset = int.parse(p.uri.queryParameters[offsetKey]!);
  final limit = int.parse(p.uri.queryParameters[limitKey]!);
  if (limit < 1 || limit > 100 || offset < 0) {
    throw const FormatException('invalid_pagination');
  }
  return [
    if (offset == 0)
      for (var next = limit; next < total; next += limit)
        p.uri.replace(
          queryParameters: {...p.uri.queryParameters, offsetKey: '$next'},
        ),
  ];
}

bool onlyParameters(Uri uri, Set<String> keys) =>
    uri.queryParametersAll.keys.toSet().length == keys.length &&
    keys.every((k) => uri.queryParametersAll[k]?.length == 1);
