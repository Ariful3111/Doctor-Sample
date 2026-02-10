import 'package:doctor_app/core/services/tour_state_service.dart';
import 'package:doctor_app/features/drop_off/controllers/drop_location_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/routes/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/constants/network_paths.dart';

class BarcodeScannerController extends GetxController {
  // Scanner state management
  final RxBool isScanning = false.obs;
  final RxBool isCameraInitialized = false.obs;
  final RxString scannedBarcode = ''.obs;
  final RxString scannerStatus = 'ready_to_scan'.tr.obs;

  // Sample tracking
  final RxList<String> scannedSamples = <String>[].obs;
  final RxInt totalSamples = 0.obs;
  final RxInt scannedCount = 0.obs;

  // UI state
  final RxBool isProcessing = false.obs;
  bool _dialogOpen = false;
  String _lastHandledBarcode = '';
  DateTime? _lastHandledAt;

  // Doctor and visit information passed from previous screen
  final RxString doctorId = ''.obs;
  final RxString doctorName = ''.obs;
  final RxString visitId = ''.obs;
  final RxString appointmentId = ''.obs;
  final RxBool isDropLocationMode = false.obs;
  bool isExtraPickup = false; // Flag to indicate if this is an extra pickup
  dynamic extraPickupId; // Extra pickup ID for completing extra pickups

  @override
  void onInit() {
    super.onInit();
    _initializeScanner();
    _loadVisitData();
  }

  @override
  void onReady() {
    super.onReady();
    startScanning();
  }

  @override
  void onClose() {
    stopScanning();
    super.onClose();
  }

  /// Initialize scanner with mock data
  void _initializeScanner() {
    // Simulate camera initialization
    Future.delayed(const Duration(seconds: 2), () {
      isCameraInitialized.value = true;
      scannerStatus.value = 'camera_ready_point_at_barcode'.tr;
    });
  }

  /// Load visit data from arguments
  void _loadVisitData() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      doctorId.value = args['doctorId'] ?? '';
      doctorName.value = args['doctorName'] ?? '';
      visitId.value = args['visitId'] ?? '';
      appointmentId.value = args['appointmentId'] ?? '';
      totalSamples.value = args['totalSamples'] ?? 5; // Mock total samples
      isDropLocationMode.value = args['isDropLocation'] ?? false;
      isExtraPickup = args['isExtraPickup'] ?? false; // Load extra pickup flag
      extraPickupId = args['extraPickupId']; // Load extra pickup ID
      print('📱 BarcodeScannerController._loadVisitData:');
      print('   doctorId: ${doctorId.value}');
      print('   isExtraPickup: $isExtraPickup');
      print('   extraPickupId: $extraPickupId');
      print('   ExtraTour should be: ${isExtraPickup ? 1 : 0}');

      // Call appointment start API
      if (appointmentId.value.isNotEmpty && !isDropLocationMode.value) {
        _callAppointmentStartAPI();
      }
    } else {
      // Mock data for testing
      doctorId.value = 'DR001';
      doctorName.value = 'Dr. John Smith';
      visitId.value = 'V001';
      totalSamples.value = 5;
      isDropLocationMode.value = false;
      isExtraPickup = false;
      print('📱 BarcodeScannerController._loadVisitData: USING MOCK DATA');
    }
  }

  /// Call appointment start API
  Future<void> _callAppointmentStartAPI() async {
    try {
      // Construct URL with appointment ID
      final url = Uri.parse(
        '${NetworkPaths.baseUrl}${NetworkPaths.appointmentStart(appointmentId.value)}',
      );

      // Format date as YYYY-MM-DD
      final now = DateTime.now();
      final formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final body = jsonEncode({'date': formattedDate});

      print('📤 appointmentStart URL: $url');
      print('📤 appointmentStart Body: $body');

      // Backend expects POST request with date in body
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('📥 appointmentStart Response: ${response.statusCode}');
      print('📥 appointmentStart Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Appointment start API called successfully');
      } else {
        print('⚠️ Appointment start API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling appointment start API: $e');
    }
  }

  /// Start barcode scanning
  void startScanning() {
    if (!isCameraInitialized.value) return;

    isScanning.value = true;
    scannerStatus.value = 'scanning_point_camera_at_barcode'.tr;
  }

  /// Stop barcode scanning
  void stopScanning() {
    isScanning.value = false;
    scannerStatus.value = 'scanner_stopped'.tr;
  }

  /// Process scanned barcode after confirmation
  void _addSample(String barcode) {
    if (barcode.isEmpty) return;

    scannedBarcode.value = barcode;

    // Add to scanned samples
    scannedSamples.add(barcode);
    scannedCount.value = scannedSamples.length;

    // Update status
    scannerStatus.value = 'sample_scanned_success'.trParams({'id': barcode});

    // Show success feedback
    _showScanSuccessDialog(barcode);

    // Continue scanning - user will manually click Next when done
  }

  /// Show confirmation dialog for a scanned barcode
  Future<void> onBarcodeDetected(String barcode, BuildContext context) async {
    if (barcode.isEmpty) return;

    final now = DateTime.now();
    final lastAt = _lastHandledAt;
    if (barcode == _lastHandledBarcode &&
        lastAt != null &&
        now.difference(lastAt) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastHandledBarcode = barcode;
    _lastHandledAt = now;

    // Prevent multiple dialogs
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      final scanTime = now.toIso8601String();
      print('📷 Barcode Scanned at: $scanTime');
      print('🔖 Barcode: $barcode');
      print(
        '📍 Mode: ${isDropLocationMode.value ? "Drop Location" : "Pickup"}',
      );

      if (isDropLocationMode.value) {
        print('⚠️ Drop location mode - should be handled in scanner screen');
        return;
      }

      if (scannedSamples.contains(barcode)) {
        await _showDuplicateScanDialog(context, barcode);
        return;
      }

      final shouldAdd = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('barcode_scanned'.tr),
          content: Text('add_sample_question'.trParams({'id': barcode})),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('add'.tr),
            ),
          ],
        ),
      );

      if (shouldAdd == true) {
        _addSample(barcode);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  /// Simulate barcode scan for testing
  void simulateScan(BuildContext context) {
    if (isProcessing.value) return;

    final mockBarcodes = [
      'SAMPLE001',
      'SAMPLE002',
      'SAMPLE003',
      'SAMPLE004',
      'SAMPLE005',
    ];

    final nextBarcode = mockBarcodes[scannedCount.value % mockBarcodes.length];
    // Simulate the full flow for testing
    onBarcodeDetected(nextBarcode, context);
  }

  /// Handle manual barcode entry
  void onManualEntrySubmitted(String barcode, BuildContext context) {
    if (barcode.trim().isEmpty) {
      SnackbarUtils.showError(
        title: 'error'.tr,
        message: 'please_enter_valid_barcode'.tr,
      );
      return;
    }

    final trimmedBarcode = barcode.trim();
    if (scannedSamples.contains(trimmedBarcode)) {
      _showDuplicateScanDialog(context, trimmedBarcode);
      return;
    }

    _addSample(trimmedBarcode);
  }

  /// Toggle manual entry mode
  void toggleManualEntry(BuildContext context) {
    _showManualEntryDialog(context);
  }

  /// Show manual entry dialog with proper keyboard handling
  void _showManualEntryDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('enter_barcode_manually'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'please_enter_the_barcode_number'.tr,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'enter_barcode_number'.tr,
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                textAlign: TextAlign.center,
                onSubmitted: (value) {
                  Navigator.of(Get.overlayContext!).pop();
                  if (value.trim().isNotEmpty) {
                    onManualEntrySubmitted(value.trim(), context);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.overlayContext!).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop();
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                onManualEntrySubmitted(barcode, context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text('submit'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Remove scanned sample
  void removeSample(String barcode) {
    scannedSamples.remove(barcode);
    scannedCount.value = scannedSamples.length;
    scannerStatus.value = 'sample_removed'.trParams({'id': barcode});
  }

  /// Navigate to pickup confirmation
  Future<void> proceedToConfirmation() async {
    if (scannedCount.value == 0) {
      SnackbarUtils.showWarning(
        title: 'no_samples'.tr,
        message: 'please_scan_at_least_one_sample'.tr,
      );
      return;
    }

    if (isDropLocationMode.value) {
      TourStateService().endTour(
        appointmentId: int.tryParse(appointmentId.value),
      );
      // For drop location, go to location code screen
      Get.offNamed(
        AppRoutes.locationCode,
        arguments: {
          'qrCode': scannedSamples.isNotEmpty ? scannedSamples.first : '',
          'scannedSamples': scannedSamples.toList(),
        },
      );
    } else {
      // For pickup, go to confirmation
      if (doctorId.value.isEmpty) {
        print(
          '❌ ERROR: doctorId is missing before navigating to pickup confirmation!',
        );
        SnackbarUtils.showError(
          title: 'Error',
          message: 'Doctor ID missing. Cannot proceed to confirmation.',
        );
        return;
      }
      print(
        'Navigating to pickup confirmation with doctorId: [32m${doctorId.value}[0m',
      );
      Get.toNamed(
        AppRoutes.pickupConfirmation,
        arguments: {
          'doctorId': doctorId.value,
          'doctorName': doctorName.value,
          'visitId': visitId.value,
          'appointmentId': appointmentId.value,
          'scannedSamples': scannedSamples.toList(),
          'totalSamples': totalSamples.value,
          'isExtraPickup': isExtraPickup, // Pass extra pickup flag
          'extraPickupId': extraPickupId, // Pass extra pickup ID
        },
      );
    }
  }

  /// Go back to previous screen
  void goBack() {
    // Stop scanning and cleanup
    stopScanning();
    isProcessing.value = false;
    if (Get.isRegistered<DropLocationController>()) {
      Get.find<DropLocationController>().isScanning.value = false;
    }
    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    final ctx = Get.context;
    if (ctx != null && Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }
  }

  // Show duplicate scan dialog
  Future<void> _showDuplicateScanDialog(
    BuildContext context,
    String barcode,
  ) async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('duplicate_scan'.tr),
          content: Text('already_scanned_sample'.trParams({'id': barcode})),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('ok'.tr),
            ),
          ],
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  /// Show scan success dialog
  void _showScanSuccessDialog(String barcode) {
    // SnackbarUtils.showSuccess(
    //   title: 'success'.tr,
    //   message: 'sample_scanned_success'.trParams({'id': barcode}),
    //   duration: const Duration(seconds: 2),
    // );
  }

  /// Get progress percentage
  double get progressPercentage {
    if (totalSamples.value == 0) return 0.0;
    return scannedCount.value / totalSamples.value;
  }

  /// Get progress text
  String progressText({required bool isDropLocation}) {
    // Show only scanned count for both modes
    return '${'scanned'.tr}: ${scannedCount.value}';
  }
}
