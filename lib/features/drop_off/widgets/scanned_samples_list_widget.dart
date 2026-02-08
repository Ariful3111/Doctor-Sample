import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/sample_scanning_controller.dart';

class ScannedSamplesListWidget extends GetView<SampleScanningController> {
  const ScannedSamplesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.scannedSamples$.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 48.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Text(
                'no_samples_scanned_yet'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: List.generate(controller.scannedSamples$.length, (index) {
            final sampleId = controller.scannedSamples$[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4.h),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success,
                  child: Icon(
                    Icons.check,
                    color: AppColors.textOnPrimary,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  sampleId,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: InkWell(
                  onTap: () {
                    controller.scannedSamples$.removeAt(index);
                  Get.find<SampleScanningController>().scannedCount$.value--;
                  },
                  child: Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                    size: 20.sp,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
