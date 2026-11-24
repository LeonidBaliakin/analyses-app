import 'dart:async';

import 'package:health_app/features/settings/settings.dart';

class MemoryPreferencesRepository implements PreferencesRepository {
  AppPreferences value = const AppPreferences();
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;
  Completer<void>? writeGate;

  @override
  Future<AppPreferences> read() async {
    if (failRead) throw Exception('Read failed');
    return value;
  }

  @override
  Future<void> write(AppPreferences preferences) async {
    writes++;
    await writeGate?.future;
    if (failWrite) throw Exception('Write failed');
    value = preferences;
  }
}
