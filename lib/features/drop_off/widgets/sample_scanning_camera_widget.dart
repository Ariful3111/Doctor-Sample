import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/sample_scanning_controller.dart';

class SampleScanningCameraWidget extends StatefulWidget {
  const SampleScanningCameraWidget({super.key});

  @override
  State<SampleScanningCameraWidget> createState() =>
      _SampleScanningCameraWidgetState();
}

class _SampleScanningCameraWidgetState extends State<SampleScanningCameraWidget>
    with WidgetsBindingObserver {
  late final MobileScannerController _cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    );
    _safeStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _safeStart();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _safeStop();
    }
  }

  void _safeStart() {
    try {
      _cameraController.start();
    } catch (_) {}
  }

  void _safeStop() {
    try {
      _cameraController.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SampleScanningController>();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final shortestSide = size.width < size.height
                ? size.width
                : size.height;
            final scanWidth = shortestSide * 0.78;
            final scanHeight = shortestSide * 0.46;
            final scanWindow = Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: scanWidth,
              height: scanHeight,
            );

            return Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
                  scanWindow: scanWindow,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final value = barcode.rawValue;
                      if (value == null || value.isEmpty) continue;
                      controller.onBarcodeDetected(value);
                    }
                  },
                ),
                IgnorePointer(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ScanAreaOverlayPainter(scanWindow: scanWindow),
                  ),
                ),
                Obx(() {
                  final isScanning = controller.isScanning$.value;
                  if (!isScanning) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'scanning_in_progress'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScanAreaOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  const _ScanAreaOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final windowPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final background = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      );
    final overlayPath = Path.combine(
      PathOperation.difference,
      background,
      cutout,
    );

    canvas.drawPath(overlayPath, overlayPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      windowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanAreaOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
