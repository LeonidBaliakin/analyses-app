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

abstract interface class DeviceAccessGateway {
  bool get supportsCamera;
  bool get supportsSettings;
  Future<SelectedAttachment?> pick(AttachmentSource source);
  Future<List<SelectedAttachment>> recoverAttachments();
  Future<DeviceCoordinates> locate();
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
  Future<DeviceCoordinates> locate() async =>
      throw const DeviceAccessException(AccessIssue.unsupported);
  @override
  Future<bool> openSettings({bool locationServices = false}) async => false;
}
