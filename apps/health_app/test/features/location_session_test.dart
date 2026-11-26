import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/device_access/device_access.dart';

import '../support/fake_device_access.dart';

void main() {
  test(
    'manual address lookup failures keep offline entry and allow retry',
    () async {
      const address = 'Воронеж, Никитинская улица 52';
      final lookup = FakeAddressLookup()..fail = true;
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      expect(await model.setManualLocation(address), isTrue);
      expect(model.location!.address, address);
      expect(model.coordinates, isNull);
      lookup.fail = false;
      lookup.suggestions = [
        const DeviceLocation(
          address: address,
          coordinates: DeviceCoordinates(51.66, 39.19),
        ),
      ];
      expect(await model.setManualLocation(address), isTrue);
      expect(model.coordinates, isNotNull);
      expect(model.addressSearchFailed, isFalse);
    },
  );

  test(
    'ambiguous and city-level lookup results never become a house point',
    () async {
      const address = 'Воронеж, Никитинская улица 52';
      final lookup = FakeAddressLookup()
        ..suggestions = [
          const DeviceLocation(
            address: address,
            coordinates: DeviceCoordinates(51.66, 39.19),
          ),
          const DeviceLocation(
            address: address,
            coordinates: DeviceCoordinates(51.67, 39.20),
          ),
        ];
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      expect(await model.setManualLocation(address), isFalse);
      expect(model.locationConfirmed, isFalse);
      expect(model.pendingLocation, isNull);
      expect(model.addressSuggestions, hasLength(2));
      lookup.suggestions = [
        const DeviceLocation(
          address: address,
          coordinates: DeviceCoordinates(51.66, 39.19),
          isAddressPoint: false,
        ),
      ];
      expect(await model.setManualLocation(address), isTrue);
      expect(model.coordinates, isNull);
    },
  );

  test(
    'closing the model during confirmation discards the late geocode',
    () async {
      final response = Completer<List<DeviceLocation>>();
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: FakeAddressLookup()..onSearch = (_) => response.future,
      );
      final selection = model.setManualLocation('Synthetic address');
      model.dispose();
      response.complete([
        const DeviceLocation(
          address: 'Synthetic address',
          coordinates: DeviceCoordinates(51.66, 39.19),
        ),
      ]);
      expect(await selection, isFalse);
      expect(model.location, isNull);
    },
  );

  test(
    'saved manual address needs confirmation after restart without GPS',
    () async {
      final storage = MemoryLocationRepository();
      final first = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        locationRepository: storage,
      );
      await first.setManualLocation('Казань, улица Баумана, 1');
      first.dispose();
      final gateway = FakeDeviceAccess()..locationIssue = AccessIssue.denied;
      final next = DeviceAccessViewModel(
        gateway: gateway,
        locationRepository: storage,
      );
      addTearDown(next.dispose);
      await next.restoreLocation();
      await next.prepareLocationForSession(language: 'ru');
      expect(next.locationConfirmed, isFalse);
      expect(next.pendingLocation!.address, 'Казань, улица Баумана, 1');
      expect(gateway.requestedLocationPermission, isFalse);
      await next.confirmLocation();
      await next.prepareLocationForSession(language: 'ru');
      expect(next.locationConfirmed, isTrue);
      expect(gateway.locateCalls, 1);
    },
  );

  test(
    'fresh GPS address is a candidate and is confirmed anew in every session',
    () async {
      final storage = MemoryLocationRepository();
      for (var i = 0; i < 2; i++) {
        final model = DeviceAccessViewModel(
          gateway: FakeDeviceAccess(),
          addressLookup: FakeAddressLookup(),
          locationRepository: storage,
        );
        await model.restoreLocation();
        await model.prepareLocationForSession(language: 'en');
        expect(model.location, isNull);
        expect(model.pendingLocation!.source, LocationSource.gps);
        expect(model.pendingLocation!.address, contains('Невский'));
        await model.confirmLocation();
        expect(model.location!.address, contains('Невский'));
        model.dispose();
      }
    },
  );

  test('reverse lookup failure preserves saved address and never exposes coordinates', () async {
    final storage = MemoryLocationRepository()
      ..saved = const DeviceLocation(address: 'Москва');
    final model = DeviceAccessViewModel(
      gateway: FakeDeviceAccess(),
      addressLookup: FakeAddressLookup()..fail = true,
      locationRepository: storage,
    );
    addTearDown(model.dispose);
    await model.restoreLocation();
    await model.prepareLocationForSession(language: 'ru');
    expect(model.coordinates, isNull);
    expect(model.pendingLocation!.address, 'Москва');
    expect(model.addressLookupFailed, isTrue);
    await model.setManualLocation('Казань');
    expect(model.addressLookupFailed, isFalse);
    expect(storage.saved!.address, 'Казань');
  });

  test(
    'no saved location and unavailable GPS leave manual entry available',
    () async {
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess()..locationIssue = AccessIssue.unsupported,
      );
      addTearDown(model.dispose);
      await model.prepareLocationForSession(language: 'en');
      expect(model.pendingLocation, isNull);
      expect(await model.setManualLocation('London'), isTrue);
      expect(model.location!.address, 'London');
    },
  );

  test(
    'storage failure keeps the selected address for the current session',
    () async {
      final storage = MemoryLocationRepository()..fail = true;
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        locationRepository: storage,
      );
      addTearDown(model.dispose);
      await model.restoreLocation();
      expect(await model.setManualLocation('Казань'), isTrue);
      expect(model.location!.address, 'Казань');
      expect(model.locationSaveFailed, isTrue);
      storage.fail = false;
      await model.setManualLocation('Казань');
      expect(model.locationSaveFailed, isFalse);
      expect(storage.saved!.address, 'Казань');
    },
  );

  test('debounce suppresses short and superseded queries', () async {
    final lookup = FakeAddressLookup()
      ..suggestions = [const DeviceLocation(address: 'Казань')];
    final model = DeviceAccessViewModel(
      gateway: FakeDeviceAccess(),
      addressLookup: lookup,
    );
    addTearDown(model.dispose);
    expect(await model.searchAddresses('Ка', language: 'ru'), isEmpty);
    final first = model.searchAddresses('Каз', language: 'ru');
    final second = model.searchAddresses('Казань', language: 'ru');
    expect(await first, isEmpty);
    expect((await second).single.address, 'Казань');
    expect(lookup.searchCalls, 1);
  });

  test(
    'late lookup results cannot replace a newer query or a closed form',
    () async {
      final old = Completer<List<DeviceLocation>>();
      final lookup = FakeAddressLookup()
        ..onSearch = (query) async => query == 'Old'
            ? old.future
            : [const DeviceLocation(address: 'New address')];
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      final first = model.searchAddresses('Old', language: 'en');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final second = model.searchAddresses('New', language: 'en');
      expect(await first, isEmpty);
      expect((await second).single.address, 'New address');
      old.complete([const DeviceLocation(address: 'Old address')]);
      await Future<void>.delayed(Duration.zero);
      expect(model.isSearchingAddresses, isFalse);
      final pending = model.searchAddresses('Closed', language: 'en');
      model.cancelAddressSearch();
      expect(await pending, isEmpty);
      expect(lookup.searchCalls, 2);
    },
  );

  test(
    'failed suggestions keep manual confirmation and can be retried',
    () async {
      final lookup = FakeAddressLookup()..fail = true;
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      expect(await model.searchAddresses('Москва', language: 'ru'), isEmpty);
      expect(model.addressSearchFailed, isTrue);
      lookup.fail = false;
      lookup.suggestions = [const DeviceLocation(address: 'Москва')];
      final suggestion = (await model.searchAddresses(
        'Москва',
        language: 'ru',
      )).single;
      expect(model.addressSearchFailed, isFalse);
      await model.setManualLocation(suggestion.address, suggestion: suggestion);
      expect(model.locationConfirmed, isTrue);
    },
  );
}
