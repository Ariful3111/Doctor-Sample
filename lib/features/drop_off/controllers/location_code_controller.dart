import 'package:doctor_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/tour_state_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../dashboard/controllers/todays_task_controller.dart';
import 'drop_location_controller.dart';

/// Controller for managing location code input and validation
/// Handles location code validation and navigation to next screen
class LocationCodeController extends GetxController {
  // Constants
  static const int _minLocationCodeLength = 3;
  static const int _maxLocationCodeLength = 20;

  // Text controller for location code input
  final TextEditingController locationCodeController = TextEditingController();

  // Reactive variables
  final RxString _locationCode = ''.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isLocationCodeValid = false.obs;
  final RxBool _isProcessing = false.obs;

  // Drop location data
  String? dropLocationId;
  String? dropLocationName;

  // Getters
  String get locationCode => _locationCode.value;
  String get errorMessage => _errorMessage.value;
  bool get isLocationCodeValid => _isLocationCodeValid.value;
  bool get isProcessing => _isProcessing.value;

  // Reactive getters for UI
  RxString get errorMessage$ => _errorMessage;
  RxBool get isLocationCodeValid$ => _isLocationCodeValid;
  RxBool get isProcessing$ => _isProcessing;

  @override
  void onInit() {
    super.onInit();
    _initializeListeners();
    _loadDropLocationData();
  }

  /// Load drop location data from arguments or from DropLocationController
  void _loadDropLocationData() {
    // First try to get from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      dropLocationId = args['dropLocationId']?.toString();
      dropLocationName = args['dropLocationName']?.toString();
    }

    // If not in arguments, try to get from DropLocationController
    if ((dropLocationId == null || dropLocationName == null)) {
      try {
        final dropController = Get.find<DropLocationController>();
        dropLocationId ??= dropController.dropLocationId.value;
        dropLocationName ??= dropController.dropLocationName.value;
      } catch (e) {
        print('⚠️ DropLocationController not found: $e');
      }
    }

    print(
      '📍 LocationCodeController loaded: ID=$dropLocationId, Name=$dropLocationName',
    );
  }

  @override
  void onClose() {
    locationCodeController.dispose();
    super.onClose();
  }

  /// Initialize listeners for text field changes
  void _initializeListeners() {
    // Listen to text changes
    locationCodeController.addListener(_onTextChanged);
  }

  /// Handle text field changes
  void _onTextChanged() {
    _locationCode.value = locationCodeController.text;
    _validateLocationCode();
  }

  /// Handle location code input changes
  void onLocationCodeChanged(String value) {
    _locationCode.value = value;
    _validateLocationCode();
  }

  /// Validate location code with comprehensive rules
  void _validateLocationCode() {
    _errorMessage.value = '';

    final code = _locationCode.value.trim();

    // Check if empty
    if (code.isEmpty) {
      _isLocationCodeValid.value = false;
      return;
    }

    // Check minimum length
    if (code.length < _minLocationCodeLength) {
      _errorMessage.value = 'location_code_min_length'.trParams({
        'min': _minLocationCodeLength.toString(),
      });
      _isLocationCodeValid.value = false;
      return;
    }

    // Check maximum length
    if (code.length > _maxLocationCodeLength) {
      _errorMessage.value = 'location_code_max_length'.trParams({
        'max': _maxLocationCodeLength.toString(),
      });
      _isLocationCodeValid.value = false;
      return;
    }

    // Check for valid characters (alphanumeric and some special characters)
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(code)) {
      _errorMessage.value = 'location_code_allowed_chars'.tr;
      _isLocationCodeValid.value = false;
      return;
    }

    // All validations passed
    _isLocationCodeValid.value = true;
  }

  /// Handle Next button press
  /// Validates code and navigates to image submission screen
  Future<void> onNextPressed() async {
    if (_isProcessing.value) {
      return; // Prevent double processing
    }

    if (!_isLocationCodeValid.value) {
      SnackbarUtils.showWarning(
        title: 'invalid_location'.tr,
        message: 'enter_valid_location_code'.tr,
      );
      return;
    }

    await _processLocationCode();
  }

  /// Process the location code and navigate to next screen
  Future<void> _processLocationCode() async {
    try {
      _isProcessing.value = true;

      // Show processing message
      SnackbarUtils.showInfo(
        title: 'verifying_location_code'.tr,
        message: 'verifying_location_code'.tr,
      );

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Show success message
      SnackbarUtils.showSuccess(
        title: 'location_code_verified_success'.tr,
        message: 'location_code_verified_success'.tr,
      );

      // Navigate to image submission screen
      Get.toNamed(AppRoutes.imageSubmission);
    } catch (e) {
      SnackbarUtils.showError(
        title: 'location_code_verification_failed'.tr,
        message: 'failed_to_submit_image_try_again'.tr,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Handle Report button press
  /// Shows dialog for reporting location code issues
  void onReportPressed() {
    if (_isProcessing.value) {
      SnackbarUtils.showWarning(
        title: 'please_wait'.tr,
        message: 'location_code_verification_in_progress'.tr,
      );
      return;
    }

    _showReportDialog();
  }

  /// Show dialog for reporting issues
  void _showReportDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('report'.tr),
        content: Text('report_location_issue_question'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              _submitReport();
            },
            child: Text('report'.tr),
          ),
        ],
      ),
    );
  }

  /// Submit the issue report with image
  Future<void> _submitReport() async {
    try {
      String tourId = '';
      try {
        final dropController = Get.find<DropLocationController>();
        tourId = dropController.tourId;
      } catch (_) {}

      if (tourId.isEmpty) {
        if (Get.isRegistered<TourStateService>()) {
          tourId = Get.find<TourStateService>().currentTourId ?? '';
        }
      }

      var isExtraPickup = false;
      if (tourId.isNotEmpty && Get.isRegistered<TodaysTaskController>()) {
        final todaysTaskController = Get.find<TodaysTaskController>();
        final tours = todaysTaskController.todaySchedule.value?.data?.tours ?? [];
        final tour = tours.firstWhereOrNull((t) => t.id?.toString() == tourId);
        isExtraPickup = tour?.allDoctors.any((d) => d.isExtraPickup) ?? false;
      }

      // Navigate to image submission screen with drop point report flags
      Get.toNamed(
        AppRoutes.imageSubmission,
        arguments: {
          'isFromDoctorReport': false,
          'isDropPointReport': true,
          'dropLocationName': dropLocationName ?? '',
          'dropLocationId': dropLocationId ?? '',
          'reportText': 'Drop point location issue', // Default report text
          'tourId': tourId,
          'isExtraPickup': isExtraPickup,
        },
      );
    } catch (e) {
      SnackbarUtils.showError(
        title: 'error'.tr,
        message: 'Failed to navigate to image submission',
      );
    }
  }

  /// Clear the location code input
  void clearLocationCode() {
    if (_isProcessing.value) {
      return; // Don't allow clearing during processing
    }

    locationCodeController.clear();
    _locationCode.value = '';
    _errorMessage.value = '';
    _isLocationCodeValid.value = false;
  }

  /// Set location code programmatically (e.g., from QR scan)
  void setLocationCode(String code) {
    if (_isProcessing.value) {
      return; // Don't allow setting during processing
    }

    locationCodeController.text = code;
    _locationCode.value = code;
    _validateLocationCode();
  }
}
