import 'package:get/get.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/tour_state_service.dart';
import '../../../data/local/storage_service.dart';
import '../../dashboard/controllers/todays_task_controller.dart';
import '../repositories/drop_location_repository.dart';

class DropLocationController extends GetxController {
  // Repository
  final DropLocationRepository _repository = DropLocationRepository();

  // Reactive variables
  final RxString currentLocation = ''.obs;
  final RxBool isScanning = false.obs;
  final RxBool isLocationValid = false.obs;
  final RxString scannedQRCode = ''.obs;
  final RxString dropLocationId = ''.obs;
  final RxString dropLocationName = ''.obs;
  final RxBool isCheckingTime = false.obs;
  final RxBool isValidating = false.obs; // Prevent double validation

  // Drop location data
  Map<String, dynamic>? dropLocationData;
  int _totalPendingSamples = 0; // Store extracted pending samples

  // Data from Pending Drop Date screen
  String selectedDate = ''; // Selected date from pending drop date screen
  bool fromPendingDropDate =
      false; // Flag to track if coming from pending drop date
  String tourId = ''; // Tour ID if coming from tour context

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
  }

  /// Load arguments passed from previous screen
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      currentLocation.value = args['currentLocation'] ?? '';
      dropLocationId.value = args['dropLocationId'] ?? '';
      dropLocationName.value = args['dropLocationName'] ?? '';

      // Load data from Pending Drop Date screen
      selectedDate = args['selectedDate'] ?? '';
      fromPendingDropDate = args['fromPendingDropDate'] ?? false;

      // ✅ Capture taskId from tour context if present
      final taskId = args['taskId'] as String?;
      if (taskId != null && taskId.isNotEmpty) {
        tourId = taskId; // Store tour ID locally
        try {
          final tourStateService = Get.find<TourStateService>();
          tourStateService.activeTourId?.value = taskId;
          print('🎯 [DropLocation] Captured Tour ID: $taskId');
          print('✅ [DropLocation] Tour ID stored locally: $tourId');
        } catch (e) {
          print('⚠️ [DropLocation] Tour State Service not found');
        }
      } else {
        print('⚠️ [DropLocation] No taskId (tour context) provided');
      }

      if (selectedDate.isNotEmpty) {
        print('📅 Selected Date from Pending Drop Date: $selectedDate');
        print('🔄 Coming from Pending Drop Date screen: $fromPendingDropDate');
      }
    }
  }

  /// Start QR code scanning
  Future<void> startQRScanning() async {
    if (isScanning.value) return;
    isScanning.value = true;

    try {
      SnackbarUtils.showInfo(
        title: 'qr_scanner'.tr,
        message: 'point_camera_to_scan'.tr,
      );

      await Get.toNamed(
        AppRoutes.barcodeScanner,
        arguments: {'isDropLocation': true},
      );
    } finally {
      isScanning.value = false;
    }
  }

  /// Handle scanned QR code result
  Future<bool> onQRCodeScanned(String qrCode) async {
    // Prevent double validation
    if (isValidating.value) {
      print('⚠️ Validation already in progress, ignoring duplicate scan');
      return false;
    }

    scannedQRCode.value = qrCode;
    isScanning.value = false;

    // Log scan time
    final scanTime = DateTime.now().toIso8601String();
    print('📷 QR Code Scanned at: $scanTime');
    print('📍 QR Code: $qrCode');

    return await _validateLocation();
  }

  /// Validate scanned location by NAME ONLY and check operating hours
  /// Verification uses only the location name, not numeric IDs
  Future<bool> _validateLocation() async {
    if (scannedQRCode.value.isEmpty) {
      isLocationValid.value = false;
      SnackbarUtils.showError(
        title: 'invalid_location'.tr,
        message: 'not_valid_drop_location'.tr,
      );
      return false;
    }

    // Set validation flag
    isValidating.value = true;

    try {
      // Extract location name from QR code (ignore any numeric ID parts)
      String locationName = '';
      final raw = scannedQRCode.value.trim();

      if (raw.startsWith('DROP_LOC_')) {
        // Format: DROP_LOC_FirstFloor
        locationName = raw.replaceFirst('DROP_LOC_', '').trim();
      } else if (raw.contains('_')) {
        // Format: FirstFloor_1 or First_Floor
        // Extract the name part (before the last underscore if it's a number)
        final parts = raw.split('_');
        if (parts.isNotEmpty) {
          // Check if last part is numeric (floor number) - skip it
          if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
            locationName = parts.sublist(0, parts.length - 1).join('_').trim();
          } else {
            locationName = parts[0].trim();
          }
        }
      } else {
        // Simple format: just use as-is (ignore pure numeric QR codes)
        if (!RegExp(r'^\d+$').hasMatch(raw)) {
          locationName = raw;
        }
      }

      if (locationName.isEmpty) {
        isLocationValid.value = false;
        SnackbarUtils.showError(
          title: 'invalid_location'.tr,
          message: 'not_valid_drop_location'.tr,
        );
        return false;
      }

      print('📍 Extracted location name from QR: "$locationName"');

      // Generate name candidates for matching (with different separators)
      final nameCandidates = <String>[locationName]
        ..addAll([
          locationName.replaceAll(' ', ''),
          locationName.replaceAll(' ', '-'),
          locationName.replaceAll(' ', '_'),
        ])
        ..removeWhere((s) => s.isEmpty);

      // Remove duplicates while preserving order
      final uniqueNameCandidates = <String>[];
      for (final c in nameCandidates) {
        if (!uniqueNameCandidates.contains(c)) uniqueNameCandidates.add(c);
      }

      print('🔎 Trying name candidates: $uniqueNameCandidates');

      // Get driver ID from storage
      final storage = Get.find<StorageService>();
      final driverId = await storage.read<int>(key: 'id');

      if (driverId == null) {
        isLocationValid.value = false;
        SnackbarUtils.showError(
          title: 'error'.tr,
          message: 'driver_id_not_found'.tr,
        );
        return false;
      }

      // Try to find location by name with driver authentication
      isCheckingTime.value = true;
      Map<String, dynamic>? foundLocation;

      // Use selectedDate if available (from pending drop date), otherwise use today's date
      final verificationDate = selectedDate.isNotEmpty
          ? selectedDate
          : DateTime.now().toIso8601String().split('T')[0];
      print('📅 Using date for location verification: $verificationDate');

      for (final candidate in uniqueNameCandidates) {
        final result = await _repository.getDropLocationByName(
          name: candidate,
          driverId: driverId,
          date: verificationDate,
        );
        if (result.isRight()) {
          result.fold((l) => null, (data) {
            foundLocation = data;
            print('✅ Found location with candidate name: "$candidate"');
          });
          break; // Found a match, stop trying candidates
        }
      }

      isCheckingTime.value = false;

      if (foundLocation == null) {
        isLocationValid.value = false;
        SnackbarUtils.showError(
          title: 'location_verification_failed'.tr,
          message: 'location_verification_failed'.tr,
        );
        return false;
      }

      // Location found - extract total samples count
      dropLocationData = foundLocation;

      // Extract pending samples from response
      print('🔍 Searching for pending samples in response...');
      print('📋 Top-level keys: ${foundLocation!.keys.toList()}');

      // Extract totalPendingSamples from pendingSamples object
      _totalPendingSamples = 0;

      if (foundLocation!['pendingSamples'] != null) {
        final pendingSamples = foundLocation!['pendingSamples'];
        if (pendingSamples is Map &&
            pendingSamples['totalPendingSamples'] != null) {
          final value = pendingSamples['totalPendingSamples'];
          if (value is int) {
            _totalPendingSamples = value;
            print('✅ Extracted totalPendingSamples: $_totalPendingSamples');
          }
        }
      }

      print('📦 Total pending samples: $_totalPendingSamples');

      // Store total samples if available in response
      if (foundLocation!['totalSamples'] != null) {
        final totalSamples = foundLocation!['totalSamples'] as int?;
        if (totalSamples != null && totalSamples > 0) {
          await storage.write(key: 'drop_total_samples', value: totalSamples);
          print('📦 Total samples for this drop: $totalSamples');
        }
      }
      final id = foundLocation!['id']?.toString() ?? '';
      final name = foundLocation!['name'] ?? locationName;

      dropLocationId.value = id;
      dropLocationName.value = name;
      isLocationValid.value = true;

      print('✅ Location verified: ID=$id, Name="$name"');

      SnackbarUtils.showSuccess(
        title: 'location_verified'.tr,
        message: 'location_verified'.tr,
      );
      return true;
    } finally {
      // Reset validation flag
      isCheckingTime.value = false;
      isValidating.value = false;
    }
  }

  /// Confirm drop location
  void confirmDropLocation() {
    if (!isLocationValid.value) {
      SnackbarUtils.showWarning(
        title: 'location_required'.tr,
        message: 'scan_valid_drop_location_first'.tr,
      );
      return;
    }

    // Show success message
    SnackbarUtils.showSuccess(
      title: 'drop_location_confirmed'.tr,
      message: 'samples_will_be_dropped_at'.trParams({
        'name': dropLocationName.value,
      }),
    );

    // Extract pending samples count from stored value
    print('📦 Using stored totalPendingSamples: $_totalPendingSamples');

    print('📤 Navigating to sample scanning with args:');
    print('   totalPendingSamples: $_totalPendingSamples');

    // Navigate to sample scanning screen with pending samples count
    Get.toNamed(
      AppRoutes.sampleScanning,
      arguments: {
        'dropLocationName': dropLocationName.value,
        'dropLocationId': dropLocationId.value,
        'dropLocationQRCode': scannedQRCode.value,
        'totalPendingSamples': _totalPendingSamples,
        'selectedDate': selectedDate, // ✅ Pass selected date
        'tourId': tourId, // ✅ Pass tour ID to sample scanning
      },
    );
  }

  /// Go back to previous screen
  void goBack() {
    // Reset navigation state to today_task
    try {
      final todaysTaskController = Get.find<TodaysTaskController>();
      todaysTaskController.switchToTodayTask();
    } catch (e) {
      // Controller not found, just go back
    }
    Get.back();
  }

  /// Reset scanning state
  void resetScanning() {
    isScanning.value = false;
    scannedQRCode.value = '';
    isLocationValid.value = false;
  }
}
