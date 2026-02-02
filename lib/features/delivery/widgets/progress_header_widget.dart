import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/barcode_scanner_controller.dart';

class ProgressHeaderWidget extends GetView<BarcodeScannerController> {
  final bool isDropLocation;
  const ProgressHeaderWidget({super.key, required this.isDropLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Obx(
            () => Text(
              controller.progressText(isDropLocation: isDropLocation),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          isDropLocation ? SizedBox(height: 8.h) : SizedBox(),
          isDropLocation
              ? Obx(
                  () => LinearProgressIndicator(
                    value: controller.progressPercentage,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6.h,
                  ),
                )
              : SizedBox(),
          SizedBox(height: 8.h),
          Obx(
            () => Text(
              controller.scannerStatus.value,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
