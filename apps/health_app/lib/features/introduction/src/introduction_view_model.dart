import 'package:flutter/foundation.dart';

enum IntroductionStep {
  profile,
  reports,
  summary,
  laboratories,
  specialists,
  appointment,
}

final class IntroductionViewModel extends ChangeNotifier {
  IntroductionViewModel({required this._complete});

  final Future<bool> Function() _complete;
  int _index = 0;
  int get index => _index;
  IntroductionStep get step => IntroductionStep.values[_index];
  bool get isLast => _index == IntroductionStep.values.length - 1;
  bool isSaving = false;
  bool saveFailed = false;
  bool _disposed = false;

  void next() {
    if (isSaving || isLast || _disposed) return;
    _index++;
    notifyListeners();
  }

  void previous() {
    if (isSaving || _index == 0 || _disposed) return;
    _index--;
    notifyListeners();
  }

  Future<bool> finish() async {
    if (isSaving || _disposed) return false;
    isSaving = true;
    saveFailed = false;
    notifyListeners();
    try {
      saveFailed = !await _complete();
    } on Exception {
      saveFailed = true;
    } finally {
      isSaving = false;
      if (!_disposed) notifyListeners();
    }
    return !saveFailed && !_disposed;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
