import 'package:doctor_app/core/themes/app_colors.dart';
import 'package:doctor_app/core/routes/app_routes.dart';
import 'package:doctor_app/features/dashboard/controllers/notifications_controller.dart';
import 'package:doctor_app/features/delivery/controllers/barcode_scanner_controller.dart';
import 'package:doctor_app/features/delivery/widgets/action_buttons_widget.dart';
import 'package:doctor_app/features/delivery/widgets/progress_header_widget.dart';
import 'package:doctor_app/features/delivery/widgets/scanned_samples_list_widget.dart';
import 'package:doctor_app/features/drop_off/controllers/drop_location_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late MobileScannerController cameraController;
  bool _hasNavigatedBack = false; // Prevent multiple back navigation

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BarcodeScannerController>();
    final isDropLocation = Get.arguments?['isDropLocation'] ?? false;

    // Detect if device is tablet/iPad
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double appBarHeight = isTablet ? 64.0 : 56.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          title: Text(
            isDropLocation ? 'QR code scanner' : 'Bar code scanner',
            style: TextStyle(
              fontSize: isTablet ? 14.sp : 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.goBack,
            iconSize: 24.0,
          ),
          actions: [
            // Only show notification icon for tour mode (not drop location)
            if (!isDropLocation)
              GetX<NotificationsController>(
                init: Get.find<NotificationsController>(),
                builder: (notifController) {
                  final pendingCount = notifController.pendingPickups.length;
                  final isTablet =
                      MediaQuery.of(context).size.shortestSide >= 600;
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.notifications);
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textOnPrimary,
                          size: isTablet ? 28.0 : 24.0,
                        ),
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: isTablet ? 10 : 8,
                          top: isTablet ? 10 : 8,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 6 : 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: isTablet ? 20 : 16,
                              minHeight: isTablet ? 20 : 16,
                            ),
                            child: Center(
                              child: Text(
                                pendingCount > 9
                                    ? '9+'
                                    : pendingCount.toString(),
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: isTablet ? 12 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showScanningInstructions(context),
              iconSize: 24.0,
            ),
          ],
          toolbarHeight: appBarHeight,
        ),
      ),
      body: Column(
        children: [
          // Only show progress/status for pickup mode, not for drop location verification
          if (!isDropLocation)
            ProgressHeaderWidget(isDropLocation: isDropLocation),
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  // Drop location mode - handle differently
                  if (isDropLocation &&
                      controller.isProcessing.value == false &&
                      !_hasNavigatedBack) {
                    controller.isProcessing.value = true;
                    _hasNavigatedBack = true; // Mark as navigated

                    print('📷 Drop location QR detected: ${barcode.rawValue}');
                    final qrCode = barcode.rawValue ?? '';

                    // Schedule navigation for next frame to ensure clean closure
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        print('🔙 Closing scanner and returning to drop point');
                        Navigator.of(context).pop();

                        // Validate after navigation
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (Get.isRegistered<DropLocationController>()) {
                            Get.find<DropLocationController>().onQRCodeScanned(
                              qrCode,
                            );
                          }
                          Future.delayed(const Duration(seconds: 2), () {
                            controller.isProcessing.value = false;
                          });
                        });
                      }
                    });

                    return;
                  }

                  // Regular pickup mode
                  controller.onBarcodeDetected(barcode.rawValue ?? '');
                }
              },
            ),
          ),
          // Only show scanned samples list for pickup mode
          if (!isDropLocation)
            const Expanded(flex: 2, child: ScannedSamplesListWidget()),
          // Only show action buttons for pickup mode
          if (!isDropLocation) const ActionButtonsWidget(),
        ],
      ),
    );
  }

  void _showScanningInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('scanning_instructions'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('point_camera_to_scan'.tr),
            Text('keep_barcode_within_area'.tr),
            Text('ensure_good_lighting'.tr),
            Text('hold_steady_until_complete'.tr),
            Text('use_enter_manually_if_scan_fails'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('got_it'.tr),
          ),
        ],
      ),
    );
  }
}
