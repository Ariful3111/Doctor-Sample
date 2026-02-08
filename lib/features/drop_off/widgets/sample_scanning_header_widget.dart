import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/sample_scanning_controller.dart';

class SampleScanningHeaderWidget extends StatelessWidget {
  const SampleScanningHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SampleScanningController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'scanning_progress'.tr,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        // Reactive text showing scanned count
        Obx(
          () => Text(
            controller.totalSamples > controller.totalSamples
                ? 'scanning'.trParams({
                    'count': controller.scannedCount.toString(),
                  })
                : '${controller.scannedCount} out of ${controller.totalSamples}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Reactive progress bar
        Obx(
          () => controller.totalSamples <= 1000
              ? LinearProgressIndicator(
                  value: controller.totalSamples > 0
                      ? controller.scannedCount / controller.totalSamples
                      : 0.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
