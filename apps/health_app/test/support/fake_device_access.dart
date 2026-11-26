import 'dart:typed_data';

import 'package:health_app/platform/device_access.dart';

final class FakeDeviceAccess implements DeviceAccessGateway {
  int pickCalls = 0;
  int locateCalls = 0;
  bool? requestedLocationPermission;
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
  Future<DeviceCoordinates> locate({bool requestPermission = true}) async {
    locateCalls++;
    requestedLocationPermission = requestPermission;
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

final class FakeAddressLookup implements AddressLookupGateway {
  DeviceLocation? result = const DeviceLocation(
    address: 'Санкт-Петербург, Невский проспект, 1',
    coordinates: DeviceCoordinates(59.93, 30.33),
    source: LocationSource.gps,
  );
  List<DeviceLocation> suggestions = [];
  bool fail = false;
  int searchCalls = 0;
  Future<List<DeviceLocation>> Function(String)? onSearch;
  @override
  Future<DeviceLocation?> reverse(
    DeviceCoordinates coordinates, {
    required String language,
  }) async {
    if (fail) throw Exception('synthetic lookup failure');
    return result;
  }

  @override
  Future<List<DeviceLocation>> search(
    String query, {
    required String language,
  }) async {
    searchCalls++;
    if (fail) throw Exception('synthetic lookup failure');
    return onSearch == null ? suggestions : await onSearch!(query);
  }
}

final class MemoryLocationRepository implements LocationRepository {
  DeviceLocation? saved;
  bool fail = false;
  @override
  Future<DeviceLocation?> read() async {
    if (fail) throw Exception('synthetic read failure');
    return saved;
  }

  @override
  Future<void> write(DeviceLocation location) async {
    if (fail) throw Exception('synthetic write failure');
    saved = location;
  }
}

SelectedAttachment syntheticAttachment([
  String name = 'synthetic-report.pdf',
]) => SelectedAttachment(
  name: name,
  size: 3,
  readBytes: () async => Uint8List.fromList([1, 2, 3]),
);
