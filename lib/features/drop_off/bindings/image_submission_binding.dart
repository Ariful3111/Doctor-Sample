import 'package:get/get.dart';
import '../controllers/image_submission_controller.dart';

class ImageSubmissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImageSubmissionController>(() => ImageSubmissionController());
  }
}
