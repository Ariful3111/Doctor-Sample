import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/drop_location_controller.dart';

class DropLocationInstructionsWidget extends GetView<DropLocationController> {
  const DropLocationInstructionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.info.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'instructions'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${'ensure_at_correct_drop_location'.tr}\n'
            '${'scan_qr_at_drop_location'.tr}\n'
            '${'wait_for_location_verification'.tr}\n'
            '${'confirm_drop_location_to_proceed'.tr}',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.info.withValues(alpha: .8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
