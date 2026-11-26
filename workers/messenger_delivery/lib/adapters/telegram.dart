import '../delivery.dart';

class TelegramAdapter implements DeliveryAdapter {
  @override
  String get channel => 'telegram';
  @override
  Future<void> simulate(DeliveryJob job) async {
    renderTemplate(job);
  }
}
