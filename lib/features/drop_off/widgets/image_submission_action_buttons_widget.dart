import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/image_submission_controller.dart';

class ImageSubmissionActionButtonsWidget
    extends GetView<ImageSubmissionController> {
  const ImageSubmissionActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed:
              controller.canSubmit$.value && !controller.isSubmitting$.value
              ? controller.onSubmitPressed
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.textSecondary.withValues(
              alpha: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: controller.isSubmitting$.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnPrimary,
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'submitting'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                )
              : Text(
                  'submit'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: controller.canSubmit$.value
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}
