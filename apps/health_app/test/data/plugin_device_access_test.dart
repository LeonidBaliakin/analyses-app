import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/device_access/plugin_device_access.dart';
import 'package:health_app/platform/device_access.dart';
import 'package:image_picker/image_picker.dart';

final class TestImagePicker extends ImagePicker {
  bool available = true;
  PlatformException? failure;
  ImageSource? requestedSource;
  bool? fullMetadata;
  @override
  bool supportsImageSource(ImageSource source) => available;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    requestedSource = source;
    fullMetadata = requestFullMetadata;
    if (failure case final error?) throw error;
    return null;
  }
}

void main() {
  test('unavailable camera never invokes the camera picker', () async {
    final picker = TestImagePicker()..available = false;
    final adapter = PluginDeviceAccess(picker: picker);
    await expectLater(
      adapter.pick(AttachmentSource.camera),
      throwsA(
        isA<DeviceAccessException>().having(
          (e) => e.issue,
          'issue',
          AccessIssue.unsupported,
        ),
      ),
    );
    expect(picker.requestedSource, isNull);
  });

  test(
    'gallery uses selected photo access without full metadata permission',
    () async {
      final picker = TestImagePicker();
      final adapter = PluginDeviceAccess(picker: picker);
      expect(await adapter.pick(AttachmentSource.gallery), isNull);
      expect(picker.requestedSource, ImageSource.gallery);
      expect(picker.fullMetadata, isFalse);
    },
  );

  for (final entry in {
    'camera_access_denied': AccessIssue.denied,
    'photo_access_restricted': AccessIssue.restricted,
    'no_available_camera': AccessIssue.unsupported,
    'unrelated_error': AccessIssue.failed,
  }.entries) {
    test('maps native ${entry.key} to a safe user-facing result', () async {
      final picker = TestImagePicker()
        ..failure = PlatformException(
          code: entry.key,
          message: 'synthetic private native details',
        );
      final adapter = PluginDeviceAccess(picker: picker);
      await expectLater(
        adapter.pick(AttachmentSource.camera),
        throwsA(
          isA<DeviceAccessException>().having(
            (e) => e.issue,
            'issue',
            entry.value,
          ),
        ),
      );
    });
  }
}
