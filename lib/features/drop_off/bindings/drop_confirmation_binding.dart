import 'package:get/get.dart';
import '../controllers/drop_confirmation_controller.dart';

class DropConfirmationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DropConfirmationController>(() => DropConfirmationController());
  }
}
