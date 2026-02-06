import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/tour_state_service.dart';
import '../../../core/constants/network_paths.dart';
import '../../../data/local/storage_service.dart';
import '../../dashboard/controllers/todays_task_controller.dart';

class PickupConfirmationController extends GetxController {
  // Reactive variables
  final RxString doctorId = ''.obs;
  final RxString doctorName = ''.obs;
  final RxString visitId = ''.obs;
  final RxString appointmentId = ''.obs;
  final RxList<String> scannedSamples = <String>[].obs;
  final RxInt totalSamples = 0.obs;
  final RxBool isSubmitting = false.obs; // Loading state for submit button
  bool isExtraPickup = false; // Flag to check if this is an extra pickup
  dynamic extraPickupId; // Extra pickup ID for completing extra pickups

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
  }

  /// Load arguments passed from barcode scanner
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      doctorId.value = args['doctorId'] ?? '';
      doctorName.value = args['doctorName'] ?? '';
      visitId.value = args['visitId'] ?? '';
      appointmentId.value = args['appointmentId'] ?? '';
      scannedSamples.value = List<String>.from(args['scannedSamples'] ?? []);
      totalSamples.value = args['totalSamples'] ?? 0;
      isExtraPickup = args['isExtraPickup'] ?? false; // Load extra pickup flag
      extraPickupId = args['extraPickupId']; // Load extra pickup ID
    }
  }

  /// Check if all samples are collected
  bool get isAllSamplesCollected => scannedSamples.length >= totalSamples.value;

  /// Go back to barcode scanner
  void goBack() {
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

  /// Confirm pickup and proceed
  Future<void> confirmPickup() async {
    final tourStateService = Get.find<TourStateService>();

    // Set loading state to true
    isSubmitting.value = true;

    try {
      print('========================================');
      print('CONFIRM PICKUP STARTED');
      print('========================================');

      // Call startReport API
      print('Step 1: Calling startReport API...');
      final reportSuccess = await _callStartReportAPI();

      if (reportSuccess) {
        print('Step 1: startReport API SUCCESS');
        // Show success message
        SnackbarUtils.showSuccess(
          title: 'Report Submitted',
          message: 'Doctor samples submitted successfully',
        );
      } else {
        print('Step 1: startReport API FAILED');
        // Don't return early - continue with marking doctor as completed
        // The API failure is already logged in detail
      }

      // Track that samples were submitted (regardless of API success)
      await tourStateService.incrementSamplesSubmitted();

      // If this is an extra pickup, complete it
      // if (isExtraPickup) {
      //   print('Step 1.5: Extra Pickup detected - calling complete API...');
      //   final extraPickupCompleted = await _completeExtraPickup();
      //   if (extraPickupCompleted) {
      //     print('Step 1.5: Extra Pickup completed successfully');
      //   } else {
      //     print('Step 1.5: Extra Pickup completion failed');
      //   }
      // }

      // Mark doctor as completed
      print('Step 2: Marking doctor as completed...');
      if (doctorId.value.isNotEmpty) {
        await tourStateService.markDoctorCompleted(
          doctorId.value,
          appointmentId: appointmentId.value,
        );
        print('Step 2: Doctor marked as completed');
      } else {
        print('Step 2: Doctor ID empty, skipped');
      }

      print('Step 3: Checking if tour is complete...');
      int? aptIdInt = int.tryParse(appointmentId.value);
      String? tourId = tourStateService.currentTourId;
      if (tourId == null || tourId.isEmpty) {
        final storage = Get.find<StorageService>();
        final storedTourId = await storage.read<dynamic>(key: 'tourId');
        tourId = storedTourId?.toString();
      }
      if ((tourId == null || tourId.isEmpty) && aptIdInt != null) {
        if (Get.isRegistered<TodaysTaskController>()) {
          final todaysTaskController = Get.find<TodaysTaskController>();
          if (todaysTaskController.todaySchedule.value == null) {
            await todaysTaskController.refreshTasks();
          }
          final appointments =
              todaysTaskController.todaySchedule.value?.data?.appointments ??
              [];
          final match = appointments.firstWhereOrNull(
            (a) => a.appointmentId == aptIdInt,
          );
          tourId = match?.tour?.id?.toString();
        }
      }

      if (aptIdInt == null) {
        aptIdInt = tourStateService.currentAppointmentId;
      }

      if (aptIdInt == null && tourId != null && tourId.isNotEmpty) {
        if (Get.isRegistered<TodaysTaskController>()) {
          final todaysTaskController = Get.find<TodaysTaskController>();
          if (todaysTaskController.todaySchedule.value == null) {
            await todaysTaskController.refreshTasks();
          }
          final fromTour = int.tryParse(
            todaysTaskController.todaySchedule.value?.data
                    ?.getAppointmentIdForTour(int.tryParse(tourId)) ??
                '',
          );
          aptIdInt = fromTour;
        }
      }
      final remainingDoctors = await _getRemainingDoctorsCount(
        tourId: tourId,
        tourStateService: tourStateService,
      );

      final shouldEndTour = remainingDoctors == 0 && aptIdInt != null;
      final shouldGoTodaysTask = remainingDoctors == 0 || tourId == null;

      if (shouldEndTour) {
        print('🏁 Last doctor detected. Calling endTour API...');
        final ended = await tourStateService.endTour(
          appointmentId: aptIdInt,
          tourId: tourId,
        );
        if (!ended) {
          SnackbarUtils.showError(
            title: 'Error',
            message: 'Failed to end tour. Please try again.',
          );
        }
        if (Get.isRegistered<TodaysTaskController>()) {
          await Get.find<TodaysTaskController>().refreshTasks();
        }
      }

      if (shouldGoTodaysTask) {
        SnackbarUtils.showSuccess(
          title: 'tour_completed'.tr,
          message: 'tour_completed_message'.tr,
        );

        final navigator = Get.key.currentState;
        if (navigator != null) {
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.todaysTask,
            (route) => false,
          );
        }
      } else {
        SnackbarUtils.showSuccess(
          title: 'pickup_confirmed_title'.tr,
          message: 'pickup_confirmed_message'.tr,
        );

        final navigator = Get.key.currentState;
        if (navigator != null) {
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.tourDrList,
            (route) => false,
            arguments: {'taskId': tourId},
          );
        }
      }
    } finally {
      // Always set loading state to false
      isSubmitting.value = false;
    }
  }

  Future<int?> _getRemainingDoctorsCount({
    required String? tourId,
    required TourStateService tourStateService,
  }) async {
    if (tourId == null || tourId.isEmpty) return null;
    if (!Get.isRegistered<TodaysTaskController>()) return null;

    final todaysTaskController = Get.find<TodaysTaskController>();
    if (todaysTaskController.todaySchedule.value == null) {
      await todaysTaskController.refreshTasks();
    }

    final tours = todaysTaskController.todaySchedule.value?.data?.tours ?? [];
    final tour = tours.firstWhereOrNull((t) => t.id?.toString() == tourId);
    if (tour == null) return null;

    return tour.allDoctors.where((d) {
      final id = d.id?.toString() ?? '';
      return !tourStateService.completedDoctorIds.contains(id);
    }).length;
  }

  /// Call startReport API
  Future<bool> _callStartReportAPI() async {
    print('startReport API STARTING');
    try {
      final storage = Get.find<StorageService>();
      final driverId = await storage.read<int>(key: 'id');
      final tourId = await storage.read<int>(key: 'tourId');
      final tourStartDate = await storage.read<String>(
        key: 'appointment_start_date',
      );

      // Get current time in HH:MM format
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      print('Retrieved from storage:');
      print('   driverId: $driverId');
      print('   tourId: $tourId');
      print('   tourStartDate: $tourStartDate');
      print('   currentTime: $currentTime');
      print('Controller data:');
      print('   doctorId: ${doctorId.value}');
      print('   scannedSamples: ${scannedSamples.toList()}');
      print('   scannedSamples count: ${scannedSamples.length}');
      print('   ✅ isExtraPickup VALUE: $isExtraPickup');
      print('   ✅ ExtraTour WILL BE: ${isExtraPickup ? 1 : 0}');

      if (driverId == null) {
        print('Driver ID not found, CANNOT SEND REPORT');
        SnackbarUtils.showError(
          title: 'Error',
          message: 'Driver ID not found. Please login again.',
        );
        return false;
      }

      if (tourId == null) {
        print('Tour ID not found, CANNOT SEND REPORT');
        SnackbarUtils.showError(
          title: 'Error',
          message: 'Tour ID not found. Please restart tour.',
        );
        return false;
      }

      if (doctorId.value.isEmpty) {
        print('Doctor ID not found, CANNOT SEND REPORT');
        SnackbarUtils.showError(
          title: 'Error',
          message: 'Doctor ID not found. Please try again.',
        );
        return false;
      }

      if (scannedSamples.isEmpty) {
        print('No samples scanned, CANNOT SEND REPORT');
        SnackbarUtils.showError(
          title: 'Error',
          message: 'No samples found. Please scan samples first.',
        );
        return false;
      }

      // Backend expects: {driverId, tourId, doctorId, doctorSamples, ExtraTour, date, pickupTime}
      dynamic parsedDoctorId;
      if (doctorId.value.isNotEmpty && int.tryParse(doctorId.value) != null) {
        parsedDoctorId = int.parse(doctorId.value);
      } else {
        parsedDoctorId = doctorId.value;
      }

      // Determine pickupTime based on date comparison
      String pickupTime;
      if (tourStartDate != null) {
        final tourDate = DateTime.parse(tourStartDate);
        final today = DateTime.now();

        // Check if today is same date as tour start date
        if (today.year == tourDate.year &&
            today.month == tourDate.month &&
            today.day == tourDate.day) {
          // Same day - use current time
          pickupTime = currentTime;
        } else {
          // Different day - use 23:59
          pickupTime = '23:59';
        }
      } else {
        // If no tour start date, use current time
        pickupTime = currentTime;
      }

      final body = {
        'driverId': driverId,
        'tourId': tourId,
        'doctorId': parsedDoctorId,
        'doctorSamples': scannedSamples.toList(),
        'ExtraTour': isExtraPickup ? 1 : 0, // 1 if extra pickup, 0 if regular
        'date': tourStartDate, // Tour start date (YYYY-MM-DD)
        'pickupTime': pickupTime, // Current time if same day, else 23:59
      };

      final url = Uri.parse(
        '${NetworkPaths.baseUrl}${NetworkPaths.startReport}',
      );

      print('SENDING REQUEST TO BACKEND');
      print('URL: $url');
      print('Body: ${jsonEncode(body)}');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        print('RESPONSE FROM BACKEND');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('START REPORT API SUCCESS');
          return true;
        } else {
          print('START REPORT API FAILED: ${response.statusCode}');
          print('Error Response: ${response.body}');
          // Show detailed error message
          String errorMsg = 'Server returned status ${response.statusCode}';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['message'] != null) {
              errorMsg = errorData['message'];
            } else if (errorData['error'] != null) {
              errorMsg = errorData['error'];
            }
          } catch (err) {
            errorMsg = response.body.isEmpty ? errorMsg : response.body;
          }
          SnackbarUtils.showError(
            title: 'API Failed (${response.statusCode})',
            message: errorMsg,
          );
          return false;
        }
      } catch (e) {
        print('EXCEPTION IN START REPORT API (network)');
        print('Error: $e');
        SnackbarUtils.showError(
          title: 'Network Error',
          message: 'Failed to connect to server: ${e.toString()}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('EXCEPTION IN START REPORT API');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      return false;
    }
  }

  /// Complete Extra Pickup
  // Future<bool> _completeExtraPickup() async {
  //   print('========================================');
  //   print('COMPLETE EXTRA PICKUP API STARTING');
  //   print('========================================');
  //   try {
  //     // Use extraPickupId that was passed from navigation
  //     if (extraPickupId == null) {
  //       print('❌ No extraPickupId found');
  //       return false;
  //     }

  //     print('✅ extraPickupId: $extraPickupId');

  //     // Step 1: Call extra-pickups complete API
  //     print('Step 1: Calling extra-pickups complete API...');
  //     final completeUrl = Uri.parse(
  //       '${NetworkPaths.baseUrl}${NetworkPaths.extraPickupComplete(extraPickupId.toString())}',
  //     );

  //     print('Complete Extra Pickup URL: $completeUrl');

  //     // Get current date for status update
  //     final now = DateTime.now();
  //     final completedDate =
  //         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  //     final body = jsonEncode({
  //       'status': 'completed',
  //       'completedDate': completedDate,
  //     });

  //     print('Complete Request Body: $body');

  //     try {
  //       final completeResponse = await http.put(
  //         completeUrl,
  //         headers: {'Content-Type': 'application/json'},
  //         body: body,
  //       );

  //       print('Complete Response Status: ${completeResponse.statusCode}');
  //       print('Complete Response Body: ${completeResponse.body}');

  //       if (completeResponse.statusCode == 200 ||
  //           completeResponse.statusCode == 201) {
  //         print('✅ EXTRA PICKUP COMPLETED SUCCESSFULLY');
  //         return true;
  //       } else {
  //         print(
  //           '❌ EXTRA PICKUP COMPLETE API FAILED: ${completeResponse.statusCode}',
  //         );
  //         return false;
  //       }
  //     } catch (e) {
  //       print('❌ EXCEPTION IN COMPLETE EXTRA PICKUP');
  //       print('Error: $e');
  //       return false;
  //     }
  //   } catch (e, stackTrace) {
  //     print('❌ EXCEPTION IN COMPLETE EXTRA PICKUP');
  //     print('Error: $e');
  //     print('Stack Trace: $stackTrace');
  //     return false;
  //   }
  // }
}
