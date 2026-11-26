import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/device_access/photon_address_lookup.dart';
import 'package:health_app/data/preferences/location_repository.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/fake_device_access.dart';

// Uses real Android HTTP and preferences with a synthetic location. No real
// coordinates, addresses or native errors are logged.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android retrieves live address suggestions', (tester) async {
    final client = http.Client();
    addTearDown(client.close);
    final lookup = PhotonAddressLookup(client: client);
    final results = await lookup.search('Воронеж', language: 'ru');
    expect(
      results,
      isNotEmpty,
      reason: 'Native HTTP must return address suggestions',
    );
    expect(results.first.address, contains('Воронеж'));
  });

  testWidgets(
    'Android resolves a synthetic GPS point and rechecks saved address confirmation',
    (tester) async {
      final client = http.Client();
      addTearDown(client.close);
      final storage = SharedPreferencesLocationRepository(
        SharedPreferencesAsync(),
      );
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess()
          ..pendingLocation = Future.value(
            const DeviceCoordinates(51.6606, 39.2006),
          ),
        addressLookup: PhotonAddressLookup(client: client),
        locationRepository: storage,
      );
      addTearDown(model.dispose);
      await model.prepareLocationForSession(language: 'ru');
      expect(model.locationIssue, isNull);
      expect(model.addressLookupFailed, isFalse);
      expect(model.pendingLocation, isNotNull);
      expect(model.pendingLocation!.address, isNotEmpty);
      expect(model.locationConfirmed, isFalse);
      await model.confirmLocation();
      expect(model.locationConfirmed, isTrue);
      final restored = DeviceAccessViewModel(
        gateway: const UnavailableDeviceAccess(),
        locationRepository: storage,
      );
      addTearDown(restored.dispose);
      await restored.restoreLocation();
      await restored.prepareLocationForSession(language: 'ru');
      expect(restored.locationConfirmed, isFalse);
      expect(restored.pendingLocation!.address, model.location!.address);
    },
  );
}
