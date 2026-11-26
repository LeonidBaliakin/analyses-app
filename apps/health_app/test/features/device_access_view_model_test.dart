import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/device_access/device_access.dart';

import '../support/fake_device_access.dart';

void main() {
  test('no permission or picker is requested by constructing the model', () {
    final gateway = FakeDeviceAccess();
    final model = DeviceAccessViewModel(gateway: gateway);
    addTearDown(model.dispose);
    expect(gateway.locateCalls, 0);
    expect(gateway.pickCalls, 0);
  });

  test('concurrent taps cannot start a second platform dialog', () async {
    final gate = Completer<SelectedAttachment?>();
    final gateway = FakeDeviceAccess()..pendingPick = gate.future;
    final model = DeviceAccessViewModel(gateway: gateway);
    addTearDown(model.dispose);
    final first = model.pick(AttachmentSource.camera);
    await model.pick(AttachmentSource.files);
    await model.locate();
    expect(gateway.pickCalls, 1);
    expect(gateway.locateCalls, 0);
    gate.complete(syntheticAttachment());
    await first;
    expect(model.attachments, hasLength(1));
    expect(model.isBusy, isFalse);
  });

  test(
    'cancellation and failure preserve previous selected attachments',
    () async {
      final gateway = FakeDeviceAccess()..selection = syntheticAttachment();
      final model = DeviceAccessViewModel(gateway: gateway);
      addTearDown(model.dispose);
      await model.pick(AttachmentSource.files);
      gateway.selection = null;
      await model.pick(AttachmentSource.gallery);
      expect(model.attachmentIssue, AccessIssue.cancelled);
      gateway.pickIssue = AccessIssue.denied;
      await model.pick(AttachmentSource.camera);
      expect(model.attachmentIssue, AccessIssue.denied);
      expect(model.attachments, hasLength(1));
      gateway.pickIssue = null;
      gateway.selection = syntheticAttachment('another.pdf');
      await model.pick(AttachmentSource.files);
      expect(model.attachmentIssue, isNull);
      expect(model.attachments, hasLength(2));
    },
  );

  for (final issue in [
    AccessIssue.denied,
    AccessIssue.permanentlyDenied,
    AccessIssue.serviceDisabled,
    AccessIssue.unsupported,
    AccessIssue.timeout,
  ]) {
    test('manual location works after $issue and keeps user input', () async {
      final gateway = FakeDeviceAccess()..locationIssue = issue;
      final model = DeviceAccessViewModel(gateway: gateway);
      addTearDown(model.dispose);
      await model.setManualLocation('  Казань, улица Баумана  ');
      await model.locate();
      expect(model.manualLocation, 'Казань, улица Баумана');
      expect(model.locationIssue, issue);
      expect(await model.setManualLocation(' '), isFalse);
      expect(model.manualLocation, 'Казань, улица Баумана');
      expect(await model.setManualLocation('Москва'), isTrue);
      expect(model.locationIssue, isNull);
      expect(gateway.locateCalls, 1);
    });
  }

  test(
    'a successful location replaces manual address; manual replaces GPS',
    () async {
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: FakeAddressLookup(),
      );
      addTearDown(model.dispose);
      await model.setManualLocation('Казань');
      await model.locate();
      expect(model.pendingLocation!.address, contains('Невский'));
      expect(model.manualLocation, 'Казань');
      await model.confirmLocation();
      expect(model.coordinates!.latitude, 59.93);
      expect(model.manualLocation, isNull);
      await model.setManualLocation('Москва');
      expect(model.coordinates, isNull);
    },
  );

  test(
    'disabled location opens service settings and retry rechecks platform',
    () async {
      final gateway = FakeDeviceAccess()
        ..locationIssue = AccessIssue.serviceDisabled;
      final model = DeviceAccessViewModel(gateway: gateway);
      addTearDown(model.dispose);
      await model.locate();
      await model.openSettings();
      expect(gateway.locationSettings, isTrue);
      gateway.locationIssue = null;
      await model.locate();
      expect(model.locationIssue, isNull);
      expect(model.coordinates, isNull); // GPS still requires confirmation.
    },
  );

  test(
    'introduction can be skipped without granting any permissions',
    () async {
      var saved = false;
      final gateway = FakeDeviceAccess();
      final model = DeviceAccessViewModel(
        gateway: gateway,
        introductionRequired: true,
        rememberIntroduction: () async => saved = true,
      );
      addTearDown(model.dispose);
      expect(await model.finishIntroduction(), isTrue);
      expect(saved, isTrue);
      expect(model.introductionRequired, isFalse);
      expect(gateway.pickCalls, 0);
      expect(gateway.locateCalls, 0);
    },
  );

  test('failed introduction persistence can be retried', () async {
    var fail = true;
    final model = DeviceAccessViewModel(
      gateway: FakeDeviceAccess(),
      introductionRequired: true,
      rememberIntroduction: () async {
        if (fail) throw Exception('synthetic failure');
      },
    );
    addTearDown(model.dispose);
    expect(await model.finishIntroduction(), isFalse);
    expect(model.introductionIssue, AccessIssue.failed);
    fail = false;
    expect(await model.finishIntroduction(), isTrue);
  });

  test(
    'Android recovery runs once without duplicating the selected file',
    () async {
      final gateway = FakeDeviceAccess()..recovered = [syntheticAttachment()];
      final model = DeviceAccessViewModel(gateway: gateway);
      addTearDown(model.dispose);
      await model.recoverAttachments();
      await model.recoverAttachments();
      expect(gateway.recoveryCalls, 1);
      expect(model.attachments, hasLength(1));
    },
  );

  test(
    'completion after disposal does not notify or start new requests',
    () async {
      final gate = Completer<DeviceCoordinates>();
      final gateway = FakeDeviceAccess()..pendingLocation = gate.future;
      final model = DeviceAccessViewModel(gateway: gateway);
      var notifications = 0;
      model.addListener(() => notifications++);
      final pending = model.locate();
      model.dispose();
      gate.complete(const DeviceCoordinates(0, 0));
      await pending;
      await model.locate();
      expect(notifications, 1);
      expect(gateway.locateCalls, 1);
    },
  );
}
