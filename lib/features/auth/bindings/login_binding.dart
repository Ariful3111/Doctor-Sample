import 'package:doctor_app/features/auth/repositories/login_repo.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

/// Login Binding
/// This class is responsible for dependency injection for the Login feature
/// It ensures that LoginController is properly initialized when navigating to login screen
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginRepository>(
      () => LoginRepository(postWithResponse: Get.find()),
    );
    Get.lazyPut<LoginController>(
      () => LoginController(loginRepository: Get.find()),
    );
  }
}
