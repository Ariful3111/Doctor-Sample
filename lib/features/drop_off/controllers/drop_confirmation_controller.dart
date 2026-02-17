import 'dart:convert';
import 'package:doctor_app/features/drop_off/controllers/drop_location_controller.dart';
import 'package:doctor_app/features/drop_off/controllers/pending_drop_date_controller.dart';
import 'package:doctor_app/features/drop_off/controllers/sample_scanning_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/local/storage_service.dart';
import '../../dashboard/controllers/todays_task_controller.dart';
import '../repositories/submit_drop_off_repo.dart';

class DropConfirmationController extends GetxController {
  // Repository
  final SubmitDropOffRepository _repository = SubmitDropOffRepository();

  // Reactive variables for state management
  final RxBool _isAllSamplesAccounted = true.obs;
  final RxList<String> _missingSampleIds = <String>[].obs;
  final RxBool _isLoading = false.obs;
  final RxInt _totalSamples = 40.obs;
  final RxInt _scannedSamples = 40.obs;

  // Data to pass to next screen
  List<String> scannedSampleIds = [];
  String dropLocationName = '';
  String dropLocationId = '';
  String dropLocationQRCode = '';
  String selectedDate = ''; // ✅ Selected date from pending drop date
  String tourId = ''; // ✅ Tour ID if coming from tour context

  // Getters for reactive variables
  RxBool get isAllSamplesAccounted$ => _isAllSamplesAccounted;
  bool get isAllSamplesAccounted => _isAllSamplesAccounted.value;

  RxList<String> get missingSampleIds$ => _missingSampleIds;
  List<String> get missingSampleIds => _missingSampleIds.toList();

  RxBool get isLoading$ => _isLoading;
  bool get isLoading => _isLoading.value;

  RxInt get totalSamples$ => _totalSamples;
  int get totalSamples => _totalSamples.value;

  RxInt get scannedSamples$ => _scannedSamples;
  int get scannedSamples => _scannedSamples.value;

  @override
  void onInit() {
    super.onInit();
    _loadSampleDataFromArguments();
  }

  // Load sample data from previous screen
  void _loadSampleDataFromArguments() {
    final args = Get.arguments as Map<String, dynamic>?;

    if (args != null) {
      // Get actual scanned count from sample scanning screen
      _scannedSamples.value = args['scannedCount'] ?? 0;
      _totalSamples.value = args['totalSamples'] ?? 40;
      scannedSampleIds = List<String>.from(args['scannedSampleIds'] ?? []);
      dropLocationName = args['dropLocationName'] ?? '';
      dropLocationId = args['dropLocationId'] ?? '';
      dropLocationQRCode = args['dropLocationQRCode'] ?? '';
      selectedDate = args['selectedDate'] ?? ''; // ✅ Load selected date
      tourId = args['tourId'] ?? ''; // ✅ Load tour ID

      print('📅 Selected Date in Drop Confirmation: $selectedDate');
      if (tourId.isNotEmpty) {
        print('🎯 Tour ID in Drop Confirmation: $tourId');
      } else {
        print('⚠️ No tour ID (standalone drop point)');
      }

      // User can proceed with any number of samples, so always show success
      _isAllSamplesAccounted.value = true;
      _missingSampleIds.clear();
    } else {
      // Fallback to default values
      _scannedSamples.value = 0;
      _totalSamples.value = 40;
      _isAllSamplesAccounted.value = true;
      _missingSampleIds.clear();
    }
  }

  // Get status message based on current state
  String get statusMessage {
    return 'ready_to_submit_samples'.tr;
  }

  // Get status color based on current state
  bool get isSuccessState => _isAllSamplesAccounted.value;

  // Handle confirm button press
  void onConfirmPressed() {
    _isLoading.value = true;

    // Submit drop-off data directly to API
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Get driver ID from storage
        final storage = Get.find<StorageService>();
        final driverId = await storage.read<int>(key: 'id');

        if (driverId == null) {
          // SnackbarUtils.showError(
          //   title: 'error'.tr,
          //   message: 'driver_id_not_found'.tr,
          // );
          _isLoading.value = false;
          return;
        }

        // Prepare complete drop-off data in format backend expects
        final now = DateTime.now();
        final dateString = selectedDate.isNotEmpty
            ? selectedDate // ✅ Use selected date from pending drop date
            : now.toIso8601String().split('T')[0]; // Fallback to current date
        final currentDate = now.toIso8601String().split(
          'T',
        )[0]; // Current date for dropDate
        final timeString =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'; // HH:MM

        final dropOffData = {
          'driverId': driverId,
          'scannedSamples': scannedSampleIds,
          'currentLocationName': dropLocationName,
          'date': dateString, // ✅ Pending drop date
          'dropTime': timeString,
          'dropDate': currentDate, // ✅ Current date when submitting
        };

        print('� [onConfirmPressed] Data preparation:');
        print('   driverId: $driverId (type: ${driverId.runtimeType})');
        print(
          '   scannedSampleIds: $scannedSampleIds (length: ${scannedSampleIds.length})',
        );
        print('   dropLocationName: $dropLocationName');
        print('   selectedDate (pending): $dateString');
        print('   currentDate (submit): $currentDate');
        print('   timeString: $timeString');
        print('📤 Submitting drop-off data: $dropOffData');
        print('📤 Data JSON will be: ${jsonEncode(dropOffData)}');

        // Show loading
        SnackbarUtils.showInfo(
          title: 'submitting'.tr,
          message: 'submitting_samples'.tr,
        );

        // Submit drop-off data to API
        final submitResult = await _repository.submitDropOff(
          dropOffData: dropOffData,
        );

        submitResult.fold(
          (error) {
            print('❌ Drop-off submission failed: $error');
            Get.snackbar(
              'submission_failed'.tr,
              error,
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
            _isLoading.value = false;
          },
          (data) {
            print('✅ Drop-off submitted successfully: $data');
            // Show success message
            SnackbarUtils.showSuccess(
              title: 'submitted_successfully'.tr,
              message: 'samples_submitted_successfully'.tr,
            );

            // ✅ Switch to Today's Task mode before navigating
            try {
              final todaysTaskController = Get.find<TodaysTaskController>();
              todaysTaskController.switchToTodayTask();
            } catch (e) {
              // Controller not found, just navigate
            }

            // 🎯 Determine navigation based on tour context
            print('═══════════════════════════════════════════════════════');
            print('🔍 NAVIGATION DEBUG - Checking tour context...');
            print('   tourId from local variable: "$tourId"');
            print('═══════════════════════════════════════════════════════');

            if (tourId.isNotEmpty) {
              // If we have a tour context, go back to tour doctor list page
              print('✅ Tour context detected - navigating to tour doctor list');
              // Use offNamed to clear the navigation stack
              Get.offNamed(AppRoutes.tourDrList, arguments: {'taskId': tourId});
            } else {
              // Drop point is standalone, go to todo page
              print(
                '📋 No tour context - navigating to today\'s task (todo page)',
              );
              if (Get.isRegistered<DropLocationController>()) {
                Get.delete<DropLocationController>(force: true);
              }
              if (Get.isRegistered<SampleScanningController>()) {
                Get.delete<SampleScanningController>(force: true);
              }
              if (Get.isRegistered<PendingDropDateController>()) {
                Get.delete<PendingDropDateController>(force: true);
              }
              // Use offNamed to clear the navigation stack
              Get.offAllNamed(AppRoutes.todaysTask);
            }
          },
        );
      } catch (e) {
        print('❌ Error submitting drop-off: $e');
        Get.snackbar(
          'submission_failed'.tr,
          e.toString(),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        _isLoading.value = false;
      }
    });
  }

  // Handle back button press
  void onBackPressed() {
    final navigator = Get.key.currentState;
    if (navigator == null) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (navigator.canPop()) {
        navigator.pop();
      }
    });
  }

  // Force refresh sample status (for testing purposes)
  void refreshSampleStatus() {
    _loadSampleDataFromArguments();
  }

  // Set custom sample status for testing
  void setCustomSampleStatus({
    required bool allAccounted,
    List<String>? missingSamples,
  }) {
    _isAllSamplesAccounted.value = allAccounted;
    if (missingSamples != null) {
      _missingSampleIds.value = missingSamples;
      _scannedSamples.value = _totalSamples.value - missingSamples.length;
    } else {
      _missingSampleIds.clear();
      _scannedSamples.value = _totalSamples.value;
    }
  }
}
