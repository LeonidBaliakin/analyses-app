import 'package:flutter/foundation.dart';

/// Access options for the explicitly labelled synthetic link preview.
/// This model does not grant server permissions.
final class SharingViewModel extends ChangeNotifier {
  int duration = 0, scope = 0, period = 0;
  bool events = false;
  final Set<int> _groups = {};
  Set<int> get groups => Set.unmodifiable(_groups);
  void selectDuration(int value) {
    duration = value;
    notifyListeners();
  }

  void selectScope(int value) {
    scope = value;
    notifyListeners();
  }

  void selectPeriod(int value) {
    period = value;
    notifyListeners();
  }

  void includeEvents(bool value) {
    events = value;
    notifyListeners();
  }

  void selectGroup(int value) {
    if (!_groups.remove(value)) _groups.add(value);
    notifyListeners();
  }
}
