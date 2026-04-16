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
          ? '\n${controller.totalPendingSamples} sample(s) are still pending.'
          : '';

      if (missing > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: Text('incomplete_scanning'.tr),
              content: Text(
                '${'scanning_status'.trParams({'scanned': controller.scannedCount.toString(), 'total': controller.totalSamples.toString(), 'pending': (controller.totalSamples - controller.scannedCount).toString()})}\n${'send_anyway_question'.tr}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('continue_scanning_button'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Get.toNamed(
                        AppRoutes.dropConfirmation,
                        arguments: {
                          'scannedCount': controller.scannedCount,
                          'totalSamples': controller.totalSamples,
                          'scannedSampleIds': controller.scannedSamples,
                          'dropLocationName': controller.dropLocationName,
                          'dropLocationId': controller.dropLocationId,
                          'dropLocationQRCode': controller.dropLocationQRCode,
                          'selectedDate': controller.selectedDate,
                          'tourId': controller.tourId,
                        },
                      );
                    });
                  },
                  child: Text('send_anyway_button'.tr),
                ),
              ],
            ),
          );
        });
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
