import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:identity_service/identity_service.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as shelf;

Future<void> main(List<String> args) async {
  if (args.contains('--health')) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:8083/health'),
      );
      final response = await request.close();
      await response.drain<void>();
      exit(response.statusCode == 200 ? 0 : 1);
    } catch (_) {
      exit(1);
    } finally {
      client.close(force: true);
    }
  }
  final env = Platform.environment;
  String required(String k) => (env[k] ?? '').isEmpty
      ? throw StateError('Missing configuration: $k')
      : env[k]!;
  final db = Pool.withUrl(required('IDENTITY_DATABASE_URL'));
  final serviceKey = required('IDENTITY_SERVICE_KEY');
  final mailBytes = base64.decode(required('IDENTITY_MAIL_KEY'));
  if (serviceKey.length < 32 || mailBytes.length != 32) {
    throw StateError('Invalid identity key configuration');
  }
  final service = IdentityService(
    db,
    serviceKey: serviceKey,
    mailKey: SecretKey(mailBytes),
    secureCookie: env['IDENTITY_SECURE_COOKIE'] != 'false',
  );
  await service.migrate();
  final smtp = SmtpServer(
    required('SMTP_HOST'),
    port: int.parse(env['SMTP_PORT'] ?? '587'),
    username: env['SMTP_USERNAME'],
    password: env['SMTP_PASSWORD'],
    ssl: env['SMTP_SSL'] == 'true',
    allowInsecure: env['SMTP_ALLOW_INSECURE'] == 'true',
  );
  final from = required('SMTP_FROM');
  Future<void> deliver(String email, String purpose, String code) async {
    final message = Message()
      ..from = Address(from)
      ..recipients.add(email)
      ..subject =
          'Orange of Health — ${purpose == 'register' ? 'подтверждение email / verify email' : 'восстановление доступа / password recovery'}'
      ..text =
          'Код / Code: $code\n\nДействует 15 минут. Введите его только в приложении Orange of Health. Никому не сообщайте код. Если вы не отправляли запрос, проигнорируйте письмо.\nValid for 15 minutes. Enter it only in Orange of Health. Do not share the code. Ignore this email if you did not request it.';
    await send(message, smtp, timeout: const Duration(seconds: 15));
  }

  var sending = false;
  final timer = Timer.periodic(const Duration(seconds: 2), (_) async {
    if (sending) return;
    sending = true;
    try {
      await service.deliverOne(deliver);
    } catch (_) {
      stderr.writeln('Identity mail delivery deferred');
    } finally {
      sending = false;
    }
  });
  final server = await shelf.serve(
    service.call,
    env['IDENTITY_BIND'] ?? '127.0.0.1',
    int.parse(env['PORT'] ?? '8083'),
  );
  stdout.writeln('Identity ready on port ${server.port}');
  Future<void> stop() async {
    timer.cancel();
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
}
