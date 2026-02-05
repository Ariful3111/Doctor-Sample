import 'package:doctor_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/network_paths.dart';
import '../../../data/local/storage_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class ReportController extends GetxController {
  RxString reportText = ''.obs;

  // Doctor info from arguments
  String doctorId = '';
  String doctorName = '';
  String visitId = '';
  String appointmentId = '';
  String tourId = ''; // Add tourId
  bool isDropPointReport = false; // Flag to check if report is for drop point
  bool isExtraPickup = false; // Flag to track if this is an extra pickup
  dynamic extraPickupId; // Extra pickup ID for marking incomplete

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _callAppointmentStartAPI();
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      doctorId = args['doctorId']?.toString() ?? '';
      doctorName = args['doctorName']?.toString() ?? '';
      visitId = args['visitId']?.toString() ?? '';
      appointmentId = args['appointmentId']?.toString() ?? '';
      tourId = args['tourId']?.toString() ?? ''; // Load tourId
      isDropPointReport = args['isDropPoint'] ?? false;
      isExtraPickup = args['isExtraPickup'] ?? false; // Load extra pickup flag
      extraPickupId = args['extraPickupId']; // Load extra pickup ID
      print('📝 ReportController._loadArguments:');
      print('   doctorId: $doctorId');
      print('   isExtraPickup: $isExtraPickup');
      print('   extraPickupId: $extraPickupId');
      print('   ExtraTour should be: ${isExtraPickup ? 1 : 0}');
    }
  }

  /// Call appointment start API when doctor report starts
  Future<void> _callAppointmentStartAPI() async {
    // Only call for doctor reports, not drop point reports
    if (visitId.isEmpty || isDropPointReport) return;

    try {
      final storage = Get.find<StorageService>();
      final driverId = await storage.read<int>(key: 'id');

      if (driverId == null) {
        print('⚠️ Driver ID not found, skipping appointment start API');
        return;
      }

      final url = Uri.parse(
        '${NetworkPaths.baseUrl}${NetworkPaths.appointmentStart(visitId)}',
      );

      // Format date as YYYY-MM-DD
      final now = DateTime.now();
      final formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': formattedDate,
          'visitId': visitId,
          'doctorId': doctorId,
          'driverId': driverId,
          'startTime': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Appointment start API called successfully (Report)');
      } else {
        print('⚠️ Appointment start API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling appointment start API: $e');
    }
  }

  void toggleReportText(String text) {
    final List<String> texts = reportText.value.split(', ')..remove('');
    if (texts.contains(text)) {
      texts.remove(text);
    } else {
      texts.add(text);
    }
    reportText.value = texts.join(', ');
  }

  Future<void> goToNext() async {
    if (reportText.value.isEmpty) {
      SnackbarUtils.showWarning(
        title: 'warning'.tr,
        message: 'Please select at least one report option',
      );
      return;
    }
    // Navigate to image submission screen with flag and doctor info
    // Set appropriate flags based on report type
    Get.toNamed(
      AppRoutes.imageSubmission,
      arguments: {
        'isFromDoctorReport': !isDropPointReport,
        'isDropPointReport': isDropPointReport,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'visitId': visitId,
        'appointmentId': appointmentId,
        'reportText': reportText.value, // Pass report text to image submission
        'tourId': tourId, // Pass tourId from member variable
        'isExtraPickup': isExtraPickup, // Pass extra pickup flag
        'extraPickupId': extraPickupId, // Pass extra pickup ID
      },
    );
    print(
      '✅ submitReport -> ImageSubmissionController: isExtraPickup=$isExtraPickup',
    );
  }
}
