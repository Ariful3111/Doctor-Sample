import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../shared/shared_widgets/shared_widgets.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/sample_scanning_controller.dart';

class SampleScanningActionButtonsWidget extends StatelessWidget {
  const SampleScanningActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SampleScanningController>();

    void handleNext() {
      final missing = controller.totalSamples - controller.scannedCount;
      final pendingSamplesText = controller.totalPendingSamples > 0
          ? '\n${controller.totalPendingSamples} sample(s) are still pending from backend.'
          : '';

      if (missing > 0) {
        Get.dialog(
          AlertDialog(
            title: Text('⚠️ Incomplete Scanning'),
            content: Text(
              'You have scanned ${controller.scannedCount} out of ${controller.totalSamples} samples.$pendingSamplesText\n\n'
              'Do you want to submit anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('No, Continue Scanning'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(
                    AppRoutes.dropConfirmation,
                    arguments: {
                      'scannedCount': controller.scannedCount,
                      'totalSamples': controller.totalSamples,
                      'scannedSampleIds': controller.scannedSamples,
                      'dropLocationName': controller.dropLocationName,
                      'dropLocationId': controller.dropLocationId,
                      'dropLocationQRCode': controller.dropLocationQRCode,
                      'selectedDate':
                          controller.selectedDate, // ✅ Pass selected date
                      'tourId': controller.tourId, // ✅ Pass tour ID
                    },
                  );
                },
                child: Text('Yes, Submit'),
              ),
            ],
          ),
        );
      } else {
        Get.toNamed(
          AppRoutes.dropConfirmation,
          arguments: {
            'scannedCount': controller.scannedCount,
            'totalSamples': controller.totalSamples,
            'scannedSampleIds': controller.scannedSamples,
            'dropLocationName': controller.dropLocationName,
            'dropLocationId': controller.dropLocationId,
            'dropLocationQRCode': controller.dropLocationQRCode,
            'selectedDate': controller.selectedDate, // ✅ Pass selected date
            'tourId': controller.tourId, // ✅ Pass tour ID
          },
        );
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'enter_manually'.tr,
                onPressed: controller.onEnterManuallyPressed,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: PrimaryButton(text: 'next'.tr, onPressed: handleNext),
            ),
          ],
        ),
      ],
    );
  }
}
