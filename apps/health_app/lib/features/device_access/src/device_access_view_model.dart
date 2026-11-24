import 'package:flutter/foundation.dart';

import '../../../platform/device_access.dart';

final class DeviceAccessViewModel extends ChangeNotifier {
  DeviceAccessViewModel({
    required this._gateway,
    this.introductionRequired = false,
    this._rememberIntroduction,
  });

  final DeviceAccessGateway _gateway;
  final Future<void> Function()? _rememberIntroduction;
  bool introductionRequired;
  bool isBusy = false;
  bool _disposed = false;
  bool _recovered = false;
  AccessIssue? attachmentIssue;
  AccessIssue? locationIssue;
  AccessIssue? introductionIssue;
  final List<SelectedAttachment> _attachments = [];
  List<SelectedAttachment> get attachments => List.unmodifiable(_attachments);
  DeviceCoordinates? coordinates;
  String? manualLocation;
  bool get supportsCamera => _gateway.supportsCamera;
  bool get supportsSettings => _gateway.supportsSettings;

  Future<void> recoverAttachments() async {
    if (_recovered || isBusy || _disposed) return;
    _recovered = true;
    await _run(() async {
      _attachments.addAll(await _gateway.recoverAttachments());
    }, (issue) => attachmentIssue = issue);
  }

  Future<void> pick(AttachmentSource source) async {
    if (isBusy || _disposed) return;
    attachmentIssue = null;
    await _run(() async {
      final selected = await _gateway.pick(source);
      if (selected == null) {
        attachmentIssue = AccessIssue.cancelled;
      } else {
        _attachments.add(selected);
      }
    }, (issue) => attachmentIssue = issue);
  }

  void removeAttachment(SelectedAttachment attachment) {
    if (_disposed || isBusy) return;
    _attachments.remove(attachment);
    _notify();
  }

  Future<void> locate() async {
    if (isBusy || _disposed) return;
    locationIssue = null;
    await _run(() async {
      final result = await _gateway.locate();
      coordinates = result;
      manualLocation = null;
    }, (issue) => locationIssue = issue);
  }

  bool setManualLocation(String value) {
    if (isBusy || _disposed || value.trim().isEmpty) return false;
    manualLocation = value.trim();
    coordinates = null;
    locationIssue = null;
    _notify();
    return true;
  }

  Future<void> openSettings({bool location = true}) async {
    if (isBusy || _disposed) return;
    await _run(
      () async {
        if (!await _gateway.openSettings(
          locationServices:
              location && locationIssue == AccessIssue.serviceDisabled,
        )) {
          throw const DeviceAccessException(AccessIssue.unsupported);
        }
      },
      (issue) {
        if (location) {
          locationIssue = issue;
        } else {
          attachmentIssue = issue;
        }
      },
    );
  }

  Future<bool> finishIntroduction() async {
    if (isBusy || _disposed) return false;
    introductionIssue = null;
    await _run(() async {
      await _rememberIntroduction?.call();
      introductionRequired = false;
    }, (issue) => introductionIssue = issue);
    return !introductionRequired;
  }

  Future<void> _run(
    Future<void> Function() action,
    void Function(AccessIssue) onIssue,
  ) async {
    isBusy = true;
    _notify();
    try {
      await action();
    } on DeviceAccessException catch (error) {
      onIssue(error.issue);
    } on Exception {
      onIssue(AccessIssue.failed);
    } finally {
      isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
