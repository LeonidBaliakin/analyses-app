import 'package:medical_domain/medical_domain.dart';

import 'record_codec.dart';

class SyncFailure implements Exception {
  const SyncFailure(this.code, {this.retryable = false});
  final String code;
  final bool retryable;
}

class SyncIdentity {
  const SyncIdentity(this.ownerId, this.profileId, this.epoch, this.canWrite);
  final String ownerId, profileId, epoch;
  final bool canWrite;
}

class RemoteRecord {
  RemoteRecord({
    required this.payload,
    required this.version,
    required this.deleted,
    required this.sequence,
    this.deviceId = '',
    this.operationId = '',
  }) {
    record.validate();
    if (version < 1 || sequence < 1) throw const SyncFailure('schema');
  }
  final Map<String, dynamic> payload;
  final int version, sequence;
  final bool deleted;
  final String deviceId, operationId;
  HealthRecord get record => decodeRecord(payload);
  Map<String, Object?> toJson() => {
    'payload': payload,
    'version': version,
    'deleted': deleted,
    'sequence': sequence,
    'deviceId': deviceId,
    'operationId': operationId,
  };
  factory RemoteRecord.fromJson(Map<String, dynamic> j) => RemoteRecord(
    payload: Map<String, dynamic>.from(j['payload'] as Map),
    version: j['version'] as int,
    deleted: j['deleted'] as bool,
    sequence: j['sequence'] as int,
    deviceId: j['deviceId'] as String,
    operationId: j['operationId'] as String,
  );
}

class SyncCommand {
  const SyncCommand({
    required this.operationId,
    required this.deviceId,
    required this.baseVersion,
    required this.payload,
    required this.deleted,
  });
  final String operationId, deviceId;
  final int baseVersion;
  final Map<String, dynamic> payload;
  final bool deleted;
  HealthRecord get record => decodeRecord(payload);
  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'deviceId': deviceId,
    'baseVersion': baseVersion,
    'payload': payload,
    'deleted': deleted,
  };
  factory SyncCommand.fromJson(Map<String, dynamic> j) => SyncCommand(
    operationId: j['operationId'] as String,
    deviceId: j['deviceId'] as String,
    baseVersion: j['baseVersion'] as int,
    payload: Map<String, dynamic>.from(j['payload'] as Map),
    deleted: j['deleted'] as bool,
  );
}

class SyncReply {
  const SyncReply(this.applied, this.current);
  final bool applied;
  final RemoteRecord current;
}

class SyncChangePage {
  const SyncChangePage(this.epoch, this.cursor, this.more, this.records);
  final String epoch;
  final int cursor;
  final bool more;
  final List<RemoteRecord> records;
}

class SyncScope {
  const SyncScope({
    required this.destination,
    required this.deviceId,
    required this.epoch,
    required this.cursor,
    this.attempts = 0,
    this.error,
    this.retryAt,
    this.lastSuccess,
  });
  final String destination, deviceId, epoch;
  final int cursor, attempts;
  final String? error;
  final DateTime? retryAt, lastSuccess;
}

class SyncConflict {
  const SyncConflict(this.local, this.remote);
  final RecordEntry local;
  final RemoteRecord remote;
}

abstract interface class SyncGateway {
  Future<SyncIdentity> identity();
  Future<SyncChangePage> pull(int cursor, String epoch);
  Future<SyncReply> push(SyncCommand command, String epoch);
  void close();
}

abstract interface class SyncStore {
  Future<SyncScope?> syncScope(String profile);
  Future<void> bindSync(
    String profile,
    String destination,
    String deviceId,
    SyncIdentity identity,
  );
  Future<SyncCommand?> nextSyncCommand(String profile);
  Future<void> acceptSyncReply(
    String profile,
    SyncCommand command,
    SyncReply reply,
  );
  Future<void> applySyncChangePage(String profile, SyncChangePage page);
  Future<int> pendingSyncCount(String profile);
  Future<List<SyncConflict>> syncConflicts(String profile);
  Future<void> resolveSyncConflict(
    String profile,
    String recordId, {
    required bool keepLocal,
    required String operationId,
    required int localRevision,
    required int remoteVersion,
  });
  Future<void> syncFailed(String profile, SyncFailure failure, DateTime now);
  Future<void> syncSucceeded(String profile, DateTime now);
}

class SyncRunner {
  const SyncRunner(this.store, this.gateway, this.profile, this.clock);
  final SyncStore store;
  final SyncGateway gateway;
  final String profile;
  final DateTime Function() clock;
  Future<void> run({bool force = false, bool Function()? cancelled}) async {
    final scope = await store.syncScope(profile);
    if (scope == null) throw const SyncFailure('connection');
    if (!force &&
        scope.error != null &&
        (scope.retryAt == null || scope.retryAt!.isAfter(clock()))) {
      return;
    }
    void check() {
      if (cancelled?.call() == true) throw const SyncFailure('cancelled');
    }

    Future<void> pull() async {
      for (var n = 0; n < 50; n++) {
        check();
        final current = (await store.syncScope(profile))!;
        final page = await gateway.pull(current.cursor, current.epoch);
        check();
        await store.applySyncChangePage(profile, page);
        if (!page.more) return;
      }
      throw const SyncFailure('batch_limit', retryable: true);
    }

    try {
      await pull();
      for (var n = 0; n < 100; n++) {
        check();
        final command = await store.nextSyncCommand(profile);
        if (command == null) break;
        final reply = await gateway.push(command, scope.epoch);
        check();
        await store.acceptSyncReply(profile, command, reply);
      }
      await pull();
      check();
      await store.syncSucceeded(profile, clock());
    } catch (e) {
      final failure = e is SyncFailure
          ? e
          : const SyncFailure('network', retryable: true);
      if (failure.code != 'cancelled') {
        await store.syncFailed(profile, failure, clock());
      }
      rethrow;
    }
  }
}
