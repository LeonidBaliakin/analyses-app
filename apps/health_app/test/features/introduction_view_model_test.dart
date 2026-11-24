import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/introduction/src/introduction_view_model.dart';

void main() {
  test('pending completion blocks repeat writes and step changes', () async {
    final gate = Completer<bool>();
    var writes = 0;
    final model = IntroductionViewModel(
      complete: () {
        writes++;
        return gate.future;
      },
    );
    addTearDown(model.dispose);
    model.next();
    final pending = model.finish();
    expect(await model.finish(), isFalse);
    model.next();
    model.previous();
    expect(model.index, 1);
    expect(model.isSaving, isTrue);
    expect(writes, 1);
    gate.complete(true);
    expect(await pending, isTrue);
    expect(model.isSaving, isFalse);
  });

  test(
    'late completion after disposal does not notify or close another route',
    () async {
      final gate = Completer<bool>();
      final model = IntroductionViewModel(complete: () => gate.future);
      var notifications = 0;
      model.addListener(() => notifications++);
      final pending = model.finish();
      model.dispose();
      gate.complete(true);
      expect(await pending, isFalse);
      expect(notifications, 1);
    },
  );
}
