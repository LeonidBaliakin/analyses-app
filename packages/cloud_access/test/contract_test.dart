import 'dart:convert';

import 'package:cloud_access/cloud_access.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  const p = CloudPolicy(
    ownerId: 'a',
    revision: 1,
    syncEnabled: true,
    storageEnabled: false,
    processingEnabled: true,
    recordLimit: 2,
    storageLimitBytes: 0,
    processingMonthlyLimit: 1,
    active: false,
  );
  test(
    'effective expiry preserves configured flags but denies every write',
    () {
      final parsed = CloudPolicy.fromJson(p.toJson());
      expect(parsed.syncEnabled, true);
      expect(parsed.canSync, false);
      expect(parsed.canStore, false);
      expect(parsed.canProcess, false);
      expect(
        () => CloudPolicy.fromJson({...p.toJson(), 'recordLimit': -1}),
        throwsFormatException,
      );
    },
  );
  test(
    'policy client fails closed on wrong owner, version and backend outage',
    () async {
      for (final body in [
        {...p.toJson(), 'ownerId': 'b'},
        {...p.toJson(), 'schemaVersion': 2},
      ]) {
        final gateway = HttpCloudPolicyGateway(
          Uri.parse('http://entitlements/'),
          'internal-key',
          client: MockClient((r) async {
            expect(r.headers['x-cloud-service-key'], 'internal-key');
            return http.Response(jsonEncode(body), 200);
          }),
        );
        await expectLater(
          gateway.policy('a'),
          throwsA(isA<CloudAccessFailure>()),
        );
        gateway.close();
      }
      final down = HttpCloudPolicyGateway(
        Uri.parse('http://entitlements/'),
        'internal-key',
        client: MockClient((_) async => http.Response('{}', 503)),
      );
      await expectLater(down.policy('a'), throwsA(isA<CloudAccessFailure>()));
      down.close();
    },
  );
}
