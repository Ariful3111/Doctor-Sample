import 'package:get/get.dart';
import '../controllers/location_code_controller.dart';

class LocationCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationCodeController>(() => LocationCodeController());
  }
}
