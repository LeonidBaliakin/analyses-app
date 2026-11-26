import '../delivery.dart';

class VkAdapter implements DeliveryAdapter {
  @override
  String get channel => 'vk';
  @override
  Future<void> simulate(DeliveryJob job) async {
    renderTemplate(job);
  }
}
