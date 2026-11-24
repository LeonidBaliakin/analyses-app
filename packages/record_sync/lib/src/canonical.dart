import 'dart:convert';

/// JSON object order is not part of a record or an operation's identity.
String canonicalSyncJson(Object? value) => value is Map<Object?, Object?>
    ? jsonEncode({
        for (final key in value.keys.cast<String>().toList()..sort())
          key: jsonDecode(canonicalSyncJson(value[key])),
      })
    : value is List
    ? jsonEncode(value.map((v) => jsonDecode(canonicalSyncJson(v))).toList())
    : jsonEncode(value);
