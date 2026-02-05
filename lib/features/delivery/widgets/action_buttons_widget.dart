import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/barcode_scanner_controller.dart';

class ActionButtonsWidget extends GetView<BarcodeScannerController> {
  const ActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => controller.toggleManualEntry(context),
              icon: const Icon(Icons.keyboard),
              label: Text('enter_manually'.tr),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.proceedToConfirmation,
              icon: const Icon(Icons.arrow_forward),
              label: Text('next'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
