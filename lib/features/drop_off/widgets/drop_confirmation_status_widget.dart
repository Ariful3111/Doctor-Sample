import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/drop_confirmation_controller.dart';

class DropConfirmationStatusWidget extends GetView<DropConfirmationController> {
  const DropConfirmationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<DropConfirmationController>(
      builder: (controller) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: controller.isSuccessState
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: controller.isSuccessState
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Icon
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: controller.isSuccessState
                      ? AppColors.success
                      : AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.isSuccessState
                      ? Icons.check_circle
                      : Icons.warning,
                  color: AppColors.textOnPrimary,
                  size: 40.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // Status Title
              Text(
                'samples_ready_for_drop'.tr,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Sample Count Info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      controller.totalSamples > 1000
                          ? '${controller.scannedSamples} samples scanned'
                          : '${controller.scannedSamples}/${controller.totalSamples}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Status Message
              Text(
                controller.statusMessage,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
