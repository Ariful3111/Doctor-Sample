import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/local/storage_service.dart';
import '../instructions/views/instructions_popup.dart';

class DrDetailsController extends GetxController {
  final RxString doctorId = ''.obs;
  final RxString doctorName = ''.obs;
  final RxString doctorImage = ''.obs;
  final RxString appointmentId = ''.obs;
  final RxString tourId = ''.obs; // Add tourId as member variable
  bool isExtraPickup = false; // Flag to track if this is an extra pickup
  dynamic extraPickupId; // Extra pickup ID for completing extra pickups
  bool _isPopping = false;

  // Instruction data from backend
  final RxString instructionPdf = ''.obs;
  final RxString instructionDescription = ''.obs;
  final RxString instructionMapLocation = ''.obs;
  final RxString streetName = ''.obs;
  final RxString areaName = ''.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      doctorId.value = args['doctorId']?.toString() ?? '';
      appointmentId.value = args['appointmentId']?.toString() ?? '';
      tourId.value =
          args['tourId']?.toString() ?? ''; // Extract tourId from arguments
      isExtraPickup = args['isExtraPickup'] ?? false; // Load extra pickup flag
      extraPickupId = args['extraPickupId']; // Load extra pickup ID
      print('🏥 DrDetailsController.onInit:');
      print('   doctorId: $doctorId');
      print('   isExtraPickup: $isExtraPickup');
      print('   extraPickupId: $extraPickupId');
      print('   ExtraTour should be: ${isExtraPickup ? 1 : 0}');
      final data = args['doctorData'] as Map<String, dynamic>?;
      if (data != null) {
        doctorName.value = (data['name'] ?? '').toString();
        doctorImage.value = (data['image'] ?? '').toString();

        // Load instruction data from backend API response
        // Backend field names: pdfFile, description, locationLink, street, area
        instructionPdf.value = (data['pdfFile'] ?? '').toString();
        instructionDescription.value = (data['description'] ?? '').toString();
        instructionMapLocation.value = (data['locationLink'] ?? '').toString();
        streetName.value = (data['street'] ?? '').toString();
        areaName.value = (data['area'] ?? '').toString();

        // Clean PDF file URL if it has duplicate prefix
        instructionPdf.value = _cleanPdfUrl(instructionPdf.value);

        // Debug: Print loaded values
        print('📋 Instruction Data Loaded:');
        print('  PDF: ${instructionPdf.value}');
        print('  Description: ${instructionDescription.value}');
        print('  Location: ${instructionMapLocation.value}');
        print('  Street: ${streetName.value}');
        print('  Area: ${areaName.value}');
      } else {
        doctorName.value = (args['doctorName'] ?? '').toString();
        doctorImage.value = '';
      }
    } else if (args is String) {
      doctorId.value = args;
    }
  }

  /// Clean PDF URL if it has duplicate base URL prefix
  String _cleanPdfUrl(String pdfUrl) {
    if (pdfUrl.isEmpty) return pdfUrl;

    // Check if URL has duplicate /uploads/ prefix
    final uploadsPattern = RegExp(r'uploads/.*uploads/');
    if (uploadsPattern.hasMatch(pdfUrl)) {
      // Extract just the filename and remove duplicates
      final match = RegExp(r'uploads/([^/]*\.\w+)$').firstMatch(pdfUrl);
      if (match != null) {
        final filename = match.group(1);
        return 'http://5.189.172.20:5000/uploads/$filename';
      }
    }

    return pdfUrl;
  }

  /// Check if any instruction data exists
  bool get hasInstructions {
    return instructionPdf.value.isNotEmpty ||
        instructionDescription.value.isNotEmpty ||
        instructionMapLocation.value.isNotEmpty;
  }

  void startVisit() {
    SnackbarUtils.showSuccess(
      title: 'visit_started'.tr,
      message: 'visit_started_message'.trParams({'name': doctorName.value}),
    );

    // tourId pass from arguments if available
    String? tourId;
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      tourId = args['tourId']?.toString();
    }
    if (tourId != null && tourId.isNotEmpty) {
      // Save tourId to storage for later use
      final storage = Get.find<StorageService>();
      storage.write(key: 'tourId', value: int.tryParse(tourId) ?? tourId);
      print('✅ tourId saved to storage: $tourId');
    } else {
      print('⚠️ tourId not found in arguments, not saved to storage');
    }

    Get.toNamed(
      AppRoutes.barcodeScanner,
      arguments: {
        'doctorId': doctorId.value,
        'doctorName': doctorName.value,
        'appointmentId': appointmentId.value,
        'isDropLocation': false,
        'tourId': tourId,
        'isExtraPickup': isExtraPickup, // Pass extra pickup flag
        'extraPickupId': extraPickupId, // Pass extra pickup ID
      },
    );
    print(
      '✅ startVisit -> BarcodeScannerController: isExtraPickup=$isExtraPickup, extraPickupId=$extraPickupId',
    );
  }

  void showInstructions() {
    Get.dialog(
      const InstructionsPopup(),
      arguments: {
        'pdfLink': instructionPdf.value,
        'instructions': instructionDescription.value,
        'locationUrl': instructionMapLocation.value,
        'streetName': streetName.value,
        'areaName': areaName.value,
      },
      barrierDismissible: true,
    );
  }

  void goBack() {
    if (_isPopping) return;
    _isPopping = true;

    Future.microtask(() {
      try {
        final navigator = Get.key.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        final ctx = Get.context;
        if (ctx != null && Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop();
        }
      } finally {
        _isPopping = false;
      }
    });
  }
}
