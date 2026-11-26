import '../delivery.dart';

class MaxAdapter implements DeliveryAdapter {
  @override
  String get channel => 'max';
  @override
  Future<void> simulate(DeliveryJob job) async {
    renderTemplate(job);
  }
}
