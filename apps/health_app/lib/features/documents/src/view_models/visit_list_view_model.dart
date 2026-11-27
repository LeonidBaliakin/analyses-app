import 'package:flutter/foundation.dart';

/// UI filters and editable reasons in the explicitly synthetic visit preview.
/// Confirmed medical records are owned by the records feature.
final class VisitListViewModel extends ChangeNotifier {
  VisitListViewModel(List<List<String>> visits)
    : reasons = [
        for (var i = 0; i < visits.length; i++)
          i < 4
              ? 0
              : i == 4
              ? 1
              : i == 5
              ? -1
              : i == 6
              ? 2
              : i == 7
              ? 3
              : 4,
      ];
  final List<int> reasons;
  int filter = -1;
  Iterable<int> get visible =>
      Iterable<int>.generate(reasons.length)
          .where((i) => filter < 0 || reasons[i] == filter);
  void selectFilter(int value) {
    filter = value;
    notifyListeners();
  }

  void setReason(int index, int value) {
    reasons[index] = value;
    notifyListeners();
  }
}
