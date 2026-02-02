import 'package:doctor_app/features/delivery/instructions/controllers/instructions_controller.dart';
import 'package:get/get.dart';

class InstructionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InstructionsController>(() => InstructionsController());
  }
}
