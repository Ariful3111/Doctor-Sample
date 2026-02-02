import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../shared/shared_widgets/shared_widgets.dart';
import '../controllers/login_controller.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'user_id'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 8.h),

          CustomTextFormField(
            controller: controller.userIdController,
            hintText: 'enter_your_user_id'.tr,
            prefixIcon: Icon(Icons.person_outline, size: 20.sp),
            validator: controller.validateUserId,
          ),

          SizedBox(height: 20.h),

          // Password Field
          Text(
            'password'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 8.h),

          Obx(
            () => CustomTextFormField(
              controller: controller.passwordController,
              obscureText: controller.obscurePassword,
              hintText: 'enter_your_password'.tr,
              prefixIcon: Icon(Icons.lock_outline, size: 20.sp),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20.sp,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              validator: controller.validatePassword,
            ),
          ),
        ],
      ),
    );
  }
}
