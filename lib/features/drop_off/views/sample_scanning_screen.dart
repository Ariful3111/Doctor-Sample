import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../widgets/sample_scanning_header_widget.dart';
import '../widgets/sample_scanning_camera_widget.dart';
import '../widgets/sample_scanning_action_buttons_widget.dart';
import '../widgets/scanned_samples_list_widget.dart';
import '../controllers/sample_scanning_controller.dart';

class SampleScanningScreen extends StatelessWidget {
  const SampleScanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SampleScanningController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Handle back button press via the controller
          controller.onBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('scan_samples'.tr),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Handle back button press via the controller
              controller.onBackPressed();
            },
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Progress header
                const SampleScanningHeaderWidget(),

                SizedBox(height: 16.h),

                // Camera view with scanning overlay
                const Expanded(flex: 2, child: SampleScanningCameraWidget()),

                SizedBox(height: 16.h),

                // Scanned samples list
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'scanned_samples'.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      const Expanded(child: ScannedSamplesListWidget()),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Action buttons
                SampleScanningActionButtonsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
