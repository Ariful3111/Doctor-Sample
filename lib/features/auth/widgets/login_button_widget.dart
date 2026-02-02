import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../shared/shared_widgets/shared_widgets.dart';
import '../controllers/login_controller.dart';

class LoginButtonWidget extends StatelessWidget {
  const LoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Obx(
      () => PrimaryButton(
        text: 'login'.tr,
        onPressed: controller.handleLogin,
        isLoading: controller.isLoading,
        height: 56.h,
      ),
    );
  }
}
