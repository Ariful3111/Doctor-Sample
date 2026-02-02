import 'package:get/get.dart';
import '../controllers/dr_details_controller.dart';

class DrDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DrDetailsController>(() => DrDetailsController());
  }
}
