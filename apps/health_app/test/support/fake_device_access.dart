import 'dart:typed_data';

import 'package:health_app/platform/device_access.dart';

final class FakeDeviceAccess implements DeviceAccessGateway {
  int pickCalls = 0;
  int locateCalls = 0;
  int recoveryCalls = 0;
  int settingsCalls = 0;
  bool locationSettings = false;
  AttachmentSource? lastSource;
  SelectedAttachment? selection;
  List<SelectedAttachment> recovered = [];
  AccessIssue? pickIssue;
  AccessIssue? locationIssue;
  Future<SelectedAttachment?>? pendingPick;
  Future<DeviceCoordinates>? pendingLocation;
  @override
  bool supportsCamera = true;
  @override
  bool supportsSettings = true;

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async {
    pickCalls++;
    lastSource = source;
    if (pickIssue case final issue?) throw DeviceAccessException(issue);
    return pendingPick == null ? selection : await pendingPick;
  }

  @override
  Future<List<SelectedAttachment>> recoverAttachments() async {
    recoveryCalls++;
    return recovered;
  }

  @override
  Future<DeviceCoordinates> locate() async {
    locateCalls++;
    if (locationIssue case final issue?) throw DeviceAccessException(issue);
    if (pendingLocation case final pending?) return await pending;
    return const DeviceCoordinates(59.93, 30.33);
  }

  @override
  Future<bool> openSettings({bool locationServices = false}) async {
    settingsCalls++;
    locationSettings = locationServices;
    return true;
  }
}

SelectedAttachment syntheticAttachment([
  String name = 'synthetic-report.pdf',
]) => SelectedAttachment(
  name: name,
  size: 3,
  readBytes: () async => Uint8List.fromList([1, 2, 3]),
);
