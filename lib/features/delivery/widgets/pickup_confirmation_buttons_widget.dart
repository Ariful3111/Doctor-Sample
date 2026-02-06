import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/pickup_confirmation_controller.dart';

class PickupConfirmationButtonsWidget
    extends GetView<PickupConfirmationController> {
  const PickupConfirmationButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => TextButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.goBack,
                style: TextButton.styleFrom(
                  foregroundColor: controller.isSubmitting.value
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(
                      color: controller.isSubmitting.value
                          ? AppColors.border.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                ),
                child: Text('back'.tr),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.confirmPickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isSubmitting.value
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: controller.isSubmitting.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text('submitting'.tr),
                        ],
                      )
                    : Text('confirm'.tr),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
