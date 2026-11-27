import 'package:flutter/foundation.dart';

final class SummaryViewModel extends ChangeNotifier {
  bool selecting = false;
  final Set<int> printSystems = {};
  void togglePrinting() {
    selecting = !selecting;
    notifyListeners();
  }

  void togglePrintSystem(int id) {
    if (!printSystems.remove(id)) printSystems.add(id);
    notifyListeners();
  }

  String _query = '';
  String get query => _query;
  Set<int> _visible = Set<int>.from(List<int>.generate(16, (i) => i));
  Set<int> get visible => Set.unmodifiable(_visible);
  void search(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  void selectSystems(Set<int> ids) {
    _visible = Set.of(ids);
    notifyListeners();
  }

  void toggleSection(List<int> ids) {
    if (ids.any(_visible.contains)) {
      _visible.removeAll(ids);
    } else {
      _visible.addAll(ids);
    }
    notifyListeners();
  }
}
