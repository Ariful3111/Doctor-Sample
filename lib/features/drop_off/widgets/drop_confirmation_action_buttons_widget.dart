import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../shared/shared_widgets/shared_widgets.dart';
import '../controllers/drop_confirmation_controller.dart';

class DropConfirmationActionButtonsWidget
    extends GetView<DropConfirmationController> {
  const DropConfirmationActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<DropConfirmationController>(
      builder: (controller) {
        return Column(
          children: [
            // Confirm Button
            PrimaryButton(
              text: 'confirm'.tr,
              onPressed: controller.isLoading$.value
                  ? null
                  : controller.onConfirmPressed,
              isLoading: controller.isLoading$.value,
              backgroundColor: AppColors.success,
            ),

            SizedBox(height: 12.h),

            // Back Button
            SecondaryButton(
              text: 'back'.tr,
              onPressed: controller.isLoading$.value
                  ? null
                  : controller.onBackPressed,
            ),
          ],
        );
      },
    );
  }
}
