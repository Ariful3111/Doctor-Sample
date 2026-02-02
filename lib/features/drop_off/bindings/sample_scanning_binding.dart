import 'package:get/get.dart';
import '../controllers/sample_scanning_controller.dart';

class SampleScanningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SampleScanningController>(() => SampleScanningController());
  }
}
