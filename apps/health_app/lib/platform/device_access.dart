import 'dart:typed_data';

enum AttachmentSource { camera, gallery, files }

enum AccessIssue {
  denied,
  permanentlyDenied,
  restricted,
  serviceDisabled,
  unsupported,
  cancelled,
  timeout,
  failed,
}

final class DeviceAccessException implements Exception {
  const DeviceAccessException(this.issue);
  final AccessIssue issue;
}

/// A selected handle for the current session, not a saved medical document.
final class SelectedAttachment {
  const SelectedAttachment({
    required this.name,
    required this.size,
    required this.readBytes,
    this.openRead,
  });
  final String name;
  final int size;
  final Future<Uint8List> Function() readBytes;
  final Stream<Uint8List> Function()? openRead;
}

final class DeviceCoordinates {
  const DeviceCoordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

enum LocationSource { manual, gps }

enum AddressLevel { city, street, building }

/// A readable place; coordinates are optional implementation data for search.
final class DeviceLocation {
  const DeviceLocation({
    required this.address,
    this.coordinates,
    this.source = LocationSource.manual,
    this.isAddressPoint = true,
    this.completion,
    this.level,
  });
  final String address;
  final DeviceCoordinates? coordinates;
  final LocationSource source;

  /// False for geocoder results representing a city or street, not a house.
  final bool isAddressPoint;

  /// The editable city/street/building prefix, without region/country labels.
  final String? completion;
  final AddressLevel? level;
  String get inputText => completion ?? address;
}

abstract interface class AddressLookupGateway {
  Future<List<DeviceLocation>> search(String query, {required String language});
  Future<DeviceLocation?> reverse(
    DeviceCoordinates coordinates, {
    required String language,
  });
}

final class UnavailableAddressLookup implements AddressLookupGateway {
  const UnavailableAddressLookup();
  @override
  Future<List<DeviceLocation>> search(
    String query, {
    required String language,
  }) async => [];
  @override
  Future<DeviceLocation?> reverse(
    DeviceCoordinates coordinates, {
    required String language,
  }) async => null;
}

abstract interface class LocationRepository {
  Future<DeviceLocation?> read();
  Future<void> write(DeviceLocation location);
}

abstract interface class DeviceAccessGateway {
  bool get supportsCamera;
  bool get supportsSettings;
  Future<SelectedAttachment?> pick(AttachmentSource source);
  Future<List<SelectedAttachment>> recoverAttachments();
  Future<DeviceCoordinates> locate({bool requestPermission = true});
  Future<bool> openSettings({bool locationServices = false});
}

/// Used by UI previews that have no platform adapters injected.
final class UnavailableDeviceAccess implements DeviceAccessGateway {
  const UnavailableDeviceAccess();
  @override
  bool get supportsCamera => false;
  @override
  bool get supportsSettings => false;
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async =>
      throw const DeviceAccessException(AccessIssue.unsupported);
  @override
  Future<List<SelectedAttachment>> recoverAttachments() async => [];
  @override
  Future<DeviceCoordinates> locate({bool requestPermission = true}) async =>
      throw const DeviceAccessException(AccessIssue.unsupported);
  @override
  Future<bool> openSettings({bool locationServices = false}) async => false;
}
