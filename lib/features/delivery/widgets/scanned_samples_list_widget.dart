import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/barcode_scanner_controller.dart';

class ScannedSamplesListWidget extends GetView<BarcodeScannerController> {
  const ScannedSamplesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
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
              'scanned_samples_title'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => controller.scannedSamples.isEmpty
                  ? Center(
                      child: Text(
                        'no_samples_scanned_yet'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: controller.scannedSamples.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final sample = controller.scannedSamples[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success.withValues(
                              alpha: 0.1,
                            ),
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
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20.w,
                            ),
                            onPressed: () => controller.removeSample(sample),
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
