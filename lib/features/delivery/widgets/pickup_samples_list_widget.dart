import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/pickup_confirmation_controller.dart';

class PickupSamplesListWidget extends GetView<PickupConfirmationController> {
  const PickupSamplesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              'collected_samples_title'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: controller.scannedSamples.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final sample = controller.scannedSamples[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 20.w,
                      ),
                    ),
                    title: Text(
                      sample,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${'sample'.tr} ${index + 1}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      'collected'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
