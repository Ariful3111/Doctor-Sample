import 'package:get/get.dart';
import '../controllers/pickup_confirmation_controller.dart';

class PickupConfirmationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PickupConfirmationController>(
      () => PickupConfirmationController(),
    );
  }
}
