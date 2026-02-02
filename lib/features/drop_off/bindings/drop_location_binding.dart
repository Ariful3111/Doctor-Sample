import 'package:get/get.dart';
import '../controllers/drop_location_controller.dart';

class DropLocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DropLocationController>(() => DropLocationController());
  }
}
