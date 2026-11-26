class AccountFailure implements Exception {
  const AccountFailure(this.code);
  final String code;
}

class AccountSession {
  const AccountSession({
    required this.ownerId,
    required this.email,
    required this.sessionId,
    required this.token,
  });
  final String ownerId, email, sessionId, token;
}

class AccountDevice {
  const AccountDevice(this.id, this.label, this.createdAt, this.current);
  final String id, label;
  final DateTime createdAt;
  final bool current;
}

abstract interface class AccountGateway {
  Future<AccountCloudStatus> cloudStatus();
  Future<String> challenge(String email, bool recovery);
  Future<AccountSession> register(
    String challengeId,
    String code,
    String password,
    String label,
  );
  Future<AccountSession> login(String email, String password, String label);
  Future<void> recover(String challengeId, String code, String password);
  Future<AccountSession> current();
  Future<List<AccountDevice>> devices();
  Future<void> revoke(String id);
  Future<void> logout({bool all = false});
  void close();
}

class AccountCloudStatus {
  const AccountCloudStatus({
    required this.syncAllowed,
    required this.storageAllowed,
    required this.processingAllowed,
    required this.recordsUsed,
    required this.recordLimit,
    required this.bytesUsed,
    required this.bytesReserved,
    required this.storageLimit,
    required this.jobsUsed,
    required this.jobsReserved,
    required this.jobLimit,
    required this.period,
    this.validUntil,
  });
  final bool syncAllowed, storageAllowed, processingAllowed;
  final int recordsUsed,
      recordLimit,
      bytesUsed,
      bytesReserved,
      storageLimit,
      jobsUsed,
      jobsReserved,
      jobLimit;
  final String period;
  final DateTime? validUntil;
}

abstract interface class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}
