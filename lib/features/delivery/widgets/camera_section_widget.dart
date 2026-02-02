import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/barcode_scanner_controller.dart';

class CameraSectionWidget extends GetView<BarcodeScannerController> {
  const CameraSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            // Camera View Placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black87,
              child: Obx(
                () => controller.isCameraInitialized.value
                    ? _buildCameraView()
                    : _buildCameraLoading(),
              ),
            ),

            // Scanning Overlay
            Obx(
              () => controller.isScanning.value
                  ? _buildScanningOverlay()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview placeholder
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.black87],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 64.w, color: Colors.white54),
                SizedBox(height: 16.h),
                Text(
                  'Camera View',
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Point camera at barcode',
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),

        // Test scan button (for simulation)
        Positioned(
          bottom: 16.h,
          right: 16.w,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.primary,
            onPressed: controller.simulateScan,
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3.w),
          SizedBox(height: 16.h),
          Text(
            'Initializing Camera...',
            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black26,
      child: Center(
        child: Container(
          width: 250.w,
          height: 250.w,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 3.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            children: [
              // Corner indicators
              ...List.generate(4, (index) => _buildCornerIndicator(index)),

              // Scanning line animation
              _buildScanningLine(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(int index) {
    final positions = [
      {'top': 0.0, 'left': 0.0}, // Top-left
      {'top': 0.0, 'right': 0.0}, // Top-right
      {'bottom': 0.0, 'left': 0.0}, // Bottom-left
      {'bottom': 0.0, 'right': 0.0}, // Bottom-right
    ];

    final position = positions[index];

    return Positioned(
      top: position['top'],
      left: position['left'],
      right: position['right'],
      bottom: position['bottom'],
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2
                ? BorderSide(color: AppColors.accent, width: 4.w)
                : BorderSide.none,
            left: index % 2 == 0
                ? BorderSide(color: AppColors.accent, width: 4.w)
                : BorderSide.none,
            right: index % 2 == 1
                ? BorderSide(color: AppColors.accent, width: 4.w)
                : BorderSide.none,
            bottom: index >= 2
                ? BorderSide(color: AppColors.accent, width: 4.w)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildScanningLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Positioned(
          top: value * 220.w,
          left: 10.w,
          right: 10.w,
          child: Container(
            height: 2.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
