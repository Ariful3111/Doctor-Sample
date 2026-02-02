import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/pickup_confirmation_controller.dart';

class PickupSamplesSummaryWidget extends GetView<PickupConfirmationController> {
  const PickupSamplesSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Samples Collected',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Obx(
                () => Text(
                  '${controller.scannedSamples.length}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => CircleAvatar(
              radius: 24.w,
              backgroundColor: controller.isAllSamplesCollected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              child: Icon(
                controller.isAllSamplesCollected
                    ? Icons.check_circle
                    : Icons.warning,
                color: controller.isAllSamplesCollected
                    ? AppColors.success
                    : AppColors.warning,
                size: 28.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
