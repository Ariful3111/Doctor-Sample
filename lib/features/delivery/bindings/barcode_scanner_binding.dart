import 'package:get/get.dart';
import '../controllers/barcode_scanner_controller.dart';

class BarcodeScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BarcodeScannerController>(() => BarcodeScannerController());
  }
}
