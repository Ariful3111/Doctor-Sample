import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/local/storage_service.dart';

class SampleScanningController extends GetxController {
  // Constants
  static const int _defaultTotalSamples = 40;
  static const Duration _scanDelay = Duration(seconds: 2);

  // Arguments from previous screen
  String dropLocationName = '';
  String dropLocationId = '';
  String dropLocationQRCode = '';
  int totalPendingSamples = 0; // Pending samples from backend API
  String selectedDate = ''; // Selected date from pending drop date screen
  String tourId = ''; // Tour ID if coming from tour context

  // Reactive variables
  final _scannedCount = 0.obs;
  final _totalSamples = _defaultTotalSamples.obs;
  final _isScanning = false.obs;
  final _scannedSamples = <String>[].obs;
  final _pendingBarcode =
      Rxn<String>(); // Store detected barcode waiting for confirmation

  // Getters
  RxInt get scannedCount$ => _scannedCount;
  RxInt get totalSamples$ => _totalSamples;
  RxBool get isScanning$ => _isScanning;
  RxList<String> get scannedSamples$ => _scannedSamples;

  int get scannedCount => _scannedCount.value;
  int get totalSamples => _totalSamples.value;
  bool get isScanning => _isScanning.value;
  List<String> get scannedSamples => _scannedSamples.toList();

  // Computed properties
  bool get isComplete => _scannedCount.value >= _totalSamples.value;
  bool get canProceed =>
      _scannedCount.value > 0; // Allow proceeding with any samples
  double get progress =>
      _totalSamples.value > 0 ? _scannedCount.value / _totalSamples.value : 0.0;

  @override
  void onInit() {
    super.onInit();
    _initializeSampleScanning();
  }

  /// Initialize sample scanning with mock data
  void _initializeSampleScanning() async {
    // Get total samples from previous screen arguments
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      // Get pending samples from API (backend count)
      final apiTotalPendingSamples = args['totalPendingSamples'] as int? ?? 0;
      _totalSamples.value = apiTotalPendingSamples;
      totalPendingSamples = apiTotalPendingSamples;
      print('📦 Total pending samples from backend: $apiTotalPendingSamples');
      dropLocationName = args['dropLocationName'] ?? '';
      dropLocationId = args['dropLocationId'] ?? '';
      dropLocationQRCode = args['dropLocationQRCode'] ?? '';
      selectedDate = args['selectedDate'] ?? ''; // ✅ Load selected date
      tourId = args['tourId'] ?? ''; // ✅ Load tour ID
      print('📅 Selected Date in Sample Scanning: $selectedDate');
      if (tourId.isNotEmpty) {
        print('🎯 Tour ID in Sample Scanning: $tourId');
      } else {
        print('⚠️ No tour ID (standalone drop point)');
      }
    } else {
      // Try to get total samples from storage (set during location verification)
      final storage = Get.find<StorageService>();
      final storedTotal = await storage.read<int>(key: 'drop_total_samples');
      if (storedTotal != null && storedTotal > 0) {
        _totalSamples.value = storedTotal;
        print('📦 Loaded total samples from storage: $storedTotal');
      } else {
        // Fallback to default if no arguments or storage value
        _totalSamples.value = _defaultTotalSamples;
      }
    }

    // Start with clean state - no samples scanned yet
    _scannedCount.value = 0;
    _scannedSamples.clear();
  }

  /// Simulate barcode scanning
  void startScanning() {
    if (_isScanning.value || isComplete) return;

    _isScanning.value = true;

    // Simulate scanning delay
    Future.delayed(_scanDelay, () {
      if (_isScanning.value) {
        _simulateScanResult();
      }
    });
  }

  /// Handle barcode detected from real scanner
  void onBarcodeDetected(String barcodeValue) {
    // Prevent processing if already scanning
    if (_isScanning.value) return;

    _isScanning.value = true;

    // Log scan time
    final scanTime = DateTime.now().toIso8601String();
    print('📷 Sample Barcode Scanned at: $scanTime');
    print('🔖 Barcode: $barcodeValue');

    // TODO: Send scan time to backend when API is ready
    // await _sendScanTimeToBackend(barcodeValue, scanTime, 'sample');

    try {
      // Check if already scanned
      if (_scannedSamples.contains(barcodeValue)) {
        SnackbarUtils.showWarning(
          title: 'already_scanned'.tr,
          message: 'already_scanned'.tr,
        );
        // Reset scanning state immediately to allow new scans
        _isScanning.value = false;
        _pendingBarcode.value = null;
        return;
      }

      // Store pending barcode and show confirmation dialog
      _pendingBarcode.value = barcodeValue;
      _showAddConfirmationDialog(barcodeValue);
    } catch (e) {
      SnackbarUtils.showError(
        title: 'scan_error'.tr,
        message: 'failed_to_scan_sample_try_again'.tr,
      );
      // Reset scanning state and pending barcode on error
      _isScanning.value = false;
      _pendingBarcode.value = null;
    }
  }

  /// Show confirmation dialog to add scanned sample
  void _showAddConfirmationDialog(String barcodeValue) {
    Get.dialog(
      AlertDialog(
        title: Text('sample_detected'.tr),
        content: Text('add_sample_question'.trParams({'id': barcodeValue})),
        actions: [
          TextButton(
            onPressed: () {
              // Reset scanning state
              _isScanning.value = false;
              _pendingBarcode.value = null;
              // Close dialog using Navigator to ensure it closes
              Navigator.of(Get.overlayContext!).pop();
            },
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog first
              Navigator.of(Get.overlayContext!).pop();
              // Then add sample with small delay
              Future.delayed(const Duration(milliseconds: 200), () {
                confirmAddSample(barcodeValue);
              });
            },
            child: Text('add'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Confirm and add the scanned sample
  void confirmAddSample(String barcodeValue) {
    try {
      // Check if already scanned before adding
      if (_scannedSamples.contains(barcodeValue)) {
        SnackbarUtils.showWarning(
          title: 'already_scanned'.tr,
          message: 'already_scanned_sample'.trParams({'id': barcodeValue}),
        );
        _isScanning.value = false;
        _pendingBarcode.value = null;
        return;
      }

      // Add to scanned samples
      _scannedSamples.add(barcodeValue);
      _scannedCount.value++;
      _pendingBarcode.value = null;

      // Show success message after small delay to ensure dialog is fully closed
      Future.delayed(const Duration(milliseconds: 200), () {
        SnackbarUtils.showSuccess(
          title: 'sample_added'.tr,
          message: 'sample_scanned_success'.trParams({'id': barcodeValue}),
        );
      });

      // Reset scanning state immediately after adding
      _isScanning.value = false;

      // Check if all samples are scanned
      if (isComplete) {
        Future.delayed(const Duration(milliseconds: 500), () {
          SnackbarUtils.showSuccess(
            title: 'scanning_complete'.tr,
            message: 'all_samples_scanned_count'.trParams({
              'count': _totalSamples.value.toString(),
            }),
          );
        });
      }
    } catch (e) {
      SnackbarUtils.showError(
        title: 'error'.tr,
        message: 'failed_to_add_sample'.tr,
      );
      _isScanning.value = false;
      _pendingBarcode.value = null;
    }
  }

  /// Simulate scan result
  void _simulateScanResult() {
    try {
      // Generate mock sample ID
      final sampleId =
          'SAMPLE_${(_scannedCount.value + 1).toString().padLeft(3, '0')}';

      // Check if already scanned
      if (_scannedSamples.contains(sampleId)) {
        SnackbarUtils.showWarning(
          title: 'already_scanned'.tr,
          message: 'already_scanned'.tr,
        );
        _isScanning.value = false;
        return;
      }

      // Add to scanned samples
      _scannedSamples.add(sampleId);
      _scannedCount.value++;

      SnackbarUtils.showSuccess(
        title: 'sample_scanned'.tr,
        message: 'sample_scanned_success'.trParams({'id': sampleId}),
      );

      // Check if all samples are scanned
      if (isComplete) {
        SnackbarUtils.showSuccess(
          title: 'scanning_complete'.tr,
          message: 'all_samples_scanned_count'.trParams({
            'count': _totalSamples.value.toString(),
          }),
        );

        // Navigate to drop confirmation screen
        Get.toNamed(
          AppRoutes.dropConfirmation,
          arguments: {
            'scannedCount': _scannedCount.value,
            'totalSamples': _totalSamples.value,
            'scannedSampleIds': _scannedSamples.toList(),
            'dropLocationName': dropLocationName,
            'dropLocationId': dropLocationId,
            'dropLocationQRCode': dropLocationQRCode,
            'selectedDate': selectedDate,
            'tourId': tourId, // ✅ Pass tour ID to confirmation screen
          },
        );
      }
    } catch (e) {
      SnackbarUtils.showError(
        title: 'scan_error'.tr,
        message: 'failed_to_scan_sample_try_again'.tr,
      );
    } finally {
      _isScanning.value = false;
    }
  }

  /// Handle manual entry button press
  void onEnterManuallyPressed() {
    if (_isScanning.value) {
      SnackbarUtils.showWarning(
        title: 'scanning_in_progress'.tr,
        message: 'please_wait_for_current_scan_to_complete'.tr,
      );
      return;
    }

    _showManualEntryDialog();
  }

  /// Show manual entry dialog
  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();

    // Dismiss any existing keyboard first to prevent screen shift
    FocusScope.of(Get.context!).unfocus();

    Future.delayed(const Duration(milliseconds: 300), () {
      Get.dialog(
        SimpleDialog(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 24.h,
          ),
          title: Text(
            'enter_sample_id'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          children: [
            SizedBox(height: 16.h),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'sample_id'.tr,
                hintText: 'sample_id_hint_example'.tr,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final sampleId = value.trim();
                Navigator.of(Get.overlayContext!).pop();
                // Use Future.delayed to ensure dialog is fully closed
                Future.delayed(const Duration(milliseconds: 200), () {
                  textController.dispose();
                  _processManuallySample(sampleId);
                });
              },
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(Get.overlayContext!).pop();
                    Future.delayed(const Duration(milliseconds: 50), () {
                      textController.dispose();
                    });
                  },
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = textController.text.trim();
                    Navigator.of(Get.overlayContext!).pop();
                    final sampleId = value.isNotEmpty
                        ? value
                        : 'SAMPLE_${(_scannedCount.value + 1).toString().padLeft(3, '0')}';
                    // Use Future.delayed to ensure dialog is fully closed
                    Future.delayed(const Duration(milliseconds: 200), () {
                      textController.dispose();
                      _processManuallySample(sampleId);
                    });
                  },
                  child: Text('add'.tr),
                ),
              ],
            ),
          ],
        ),
        barrierDismissible: false,
      );
    });
  }

  /// Process manually entered sample
  void _processManuallySample(String sampleId) {
    if (sampleId.isEmpty) {
      SnackbarUtils.showError(
        title: 'invalid_input'.tr,
        message: 'please_enter_valid_sample_id'.tr,
      );
      return;
    }

    // Check if already scanned
    if (_scannedSamples.contains(sampleId)) {
      SnackbarUtils.showWarning(
        title: 'already_scanned'.tr,
        message: 'already_scanned'.tr,
      );
      return;
    }

    // Add to scanned samples
    _scannedSamples.add(sampleId);
    _scannedCount.value++;

    SnackbarUtils.showSuccess(
      title: 'sample_added'.tr,
      message: 'sample_added_success'.trParams({'id': sampleId}),
    );

    // Check if all samples are scanned - show notification but don't auto-navigate
    if (isComplete) {
      SnackbarUtils.showSuccess(
        title: 'scanning_complete'.tr,
        message: 'all_samples_scanned_count'.trParams({
          'count': _totalSamples.value.toString(),
        }),
      );
      // User will manually click Next button to proceed
    }
  }

  /// Handle back button press
  void onBackPressed() {
    if (_isScanning.value) {
      SnackbarUtils.showWarning(
        title: 'scanning_in_progress'.tr,
        message: 'please_wait_for_current_scan_to_complete'.tr,
      );
      return;
    }

    _showBackConfirmationDialog();
  }

  /// Show back confirmation dialog
  void _showBackConfirmationDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('go_back_question'.tr),
          content: Text(
            'go_back_confirmation_message'.trParams({
              'scanned': _scannedCount.value.toString(),
              'total': _totalSamples.value.toString(),
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('go_back'.tr),
            ),
          ],
        );
      },
    );
  }

  /// Reset scanning state
  void resetScanning() {
    _isScanning.value = false;
    _scannedCount.value = 0;
    _scannedSamples.clear();
  }

  /// Set total samples (for testing or API integration)
  void setTotalSamples(int total) {
    if (total > 0) {
      _totalSamples.value = total;
    }
  }

  @override
  void onClose() {
    // Clean up resources
    _isScanning.value = false;
    super.onClose();
  }
}
