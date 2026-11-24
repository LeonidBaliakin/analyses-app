import 'dart:async';

import 'package:file_selector/file_selector.dart' as files;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../platform/device_access.dart';

final class PluginDeviceAccess implements DeviceAccessGateway {
  PluginDeviceAccess({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  bool get supportsCamera => _picker.supportsImageSource(ImageSource.camera);

  @override
  bool get supportsSettings =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) =>
      _translate(() async {
        if (source == AttachmentSource.camera && !supportsCamera) {
          throw const DeviceAccessException(AccessIssue.unsupported);
        }
        final file = switch (source) {
          AttachmentSource.camera => await _picker.pickImage(
            source: ImageSource.camera,
            requestFullMetadata: false,
          ),
          AttachmentSource.gallery => await _picker.pickImage(
            source: ImageSource.gallery,
            requestFullMetadata: false,
          ),
          // The native document picker grants access to the selected file only.
          // No storage or manage-all-files permission is needed.
          AttachmentSource.files => await files.openFile(),
        };
        return file == null ? null : await _selection(file);
      });

  @override
  Future<List<SelectedAttachment>> recoverAttachments() => _translate(() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    return Future.wait((response.files ?? <XFile>[]).map(_selection));
  });

  Future<SelectedAttachment> _selection(XFile file) async => SelectedAttachment(
    name: file.name,
    size: await file.length(),
    readBytes: file.readAsBytes,
    openRead: () => file.openRead(),
  );

  @override
  Future<DeviceCoordinates> locate() => _translate(() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceAccessException(AccessIssue.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceAccessException(AccessIssue.permanentlyDenied);
    }
    // Browsers without the Permissions API report unableToDetermine even
    // though getCurrentPosition can still ask the user for permission.
    if (permission == LocationPermission.denied ||
        (!kIsWeb && permission == LocationPermission.unableToDetermine)) {
      throw const DeviceAccessException(AccessIssue.denied);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return DeviceCoordinates(position.latitude, position.longitude);
  });

  @override
  Future<bool> openSettings({bool locationServices = false}) => _translate(() {
    if (!supportsSettings) return Future.value(false);
    return locationServices
        ? Geolocator.openLocationSettings()
        : Geolocator.openAppSettings();
  });

  Future<T> _translate<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DeviceAccessException {
      rethrow;
    } on PermissionDeniedException {
      throw const DeviceAccessException(AccessIssue.denied);
    } on LocationServiceDisabledException {
      throw const DeviceAccessException(AccessIssue.serviceDisabled);
    } on TimeoutException {
      throw const DeviceAccessException(AccessIssue.timeout);
    } on MissingPluginException {
      throw const DeviceAccessException(AccessIssue.unsupported);
    } on UnsupportedError {
      throw const DeviceAccessException(AccessIssue.unsupported);
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      final issue = code.contains('restricted')
          ? AccessIssue.restricted
          : code.contains('denied') || code.contains('access_denied')
          ? AccessIssue.denied
          : code.contains('no_available_camera') ||
                code.contains('not_available')
          ? AccessIssue.unsupported
          : AccessIssue.failed;
      // Never expose native messages, paths or coordinates in diagnostic UI.
      throw DeviceAccessException(issue);
    } on Exception {
      throw const DeviceAccessException(AccessIssue.failed);
    }
  }
}
