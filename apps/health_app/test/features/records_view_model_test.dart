import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/records/records.dart';
import 'package:medical_domain/medical_domain.dart';

import '../support/memory_records_repository.dart';

void main() {
  const profile = MedicalProfile(
    id: RecordsViewModel.profileId,
    name: 'Synthetic',
  );
  const mutation = RecordMutation(
    operationId: 'op',
    record: profile,
    expectedRevision: 0,
  );
  RecordsViewModel model(MemoryRecordsRepository repository) =>
      RecordsViewModel(
        repository: repository,
        newId: () => 'generated-id',
        clock: () => DateTime(2026, 11, 24),
      );

  test('failed load is explicit and can be retried', () async {
    final repository = MemoryRecordsRepository()..failRead = true;
    final vm = model(repository);
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.loaded, isFalse);
    expect(vm.error, RecordsError.load);
    expect(await vm.save(mutation), isFalse);
    expect(repository.mutations, isEmpty);
    repository.failRead = false;
    await vm.load();
    expect(vm.loaded, isTrue);
  });
  test('failed save preserves prior snapshot and retry commits once', () async {
    final repository = MemoryRecordsRepository();
    final vm = model(repository);
    addTearDown(vm.dispose);
    await vm.load();
    repository.failWrite = true;
    expect(await vm.save(mutation), isFalse);
    expect(vm.profile, isNull);
    expect(vm.error, RecordsError.save);
    repository.failWrite = false;
    expect(await vm.save(mutation), isTrue);
    expect(vm.profile!.record, same(profile));
    expect(repository.mutations, hasLength(1));
  });
  test(
    'concurrent submission is suppressed and busy state is exposed',
    () async {
      final repository = MemoryRecordsRepository()
        ..writeGate = Completer<void>();
      final vm = model(repository);
      addTearDown(vm.dispose);
      await vm.load();
      final first = vm.save(mutation);
      expect(vm.saving, isTrue);
      expect(await vm.save(mutation), isFalse);
      repository.writeGate!.complete();
      expect(await first, isTrue);
      expect(vm.saving, isFalse);
      expect(repository.mutations, hasLength(1));
    },
  );
  test('stale editor does not silently overwrite another edit', () async {
    final repository = MemoryRecordsRepository();
    final vm = model(repository);
    addTearDown(vm.dispose);
    await vm.load();
    await vm.save(mutation);
    expect(await vm.save(mutation), isFalse);
    expect(vm.error, RecordsError.conflict);
    expect(repository.mutations, hasLength(1));
  });
  test(
    'selected date comes from injected clock and dispose closes the repository',
    () async {
      final repository = MemoryRecordsRepository();
      final vm = model(repository);
      expect(vm.today, CalendarDate(2026, 11, 24));
      vm.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(repository.closed, isTrue);
    },
  );
}
