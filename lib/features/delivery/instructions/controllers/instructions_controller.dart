import 'package:get/get.dart';

class InstructionsController extends GetxController {
  // Doctor information
  final streetName = ''.obs;
  final areaName = ''.obs;

  // Google Maps location link
  final locationUrl = ''.obs;

  // Instructions text
  final detailsText = ''.obs;

  // PDF link
  final pdfLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDoctorInstructions();
  }

  /// Load doctor-specific instructions from backend or arguments
  void _loadDoctorInstructions() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      streetName.value = args['streetName'] ?? '';
      areaName.value = args['areaName'] ?? '';
      locationUrl.value = args['locationUrl'] ?? '';
      detailsText.value = args['instructions'] ?? '';
      pdfLink.value = args['pdfLink'] ?? '';

      // Debug: Print received values
      print('🔍 InstructionsController Received:');
      print('  streetName: ${streetName.value}');
      print('  areaName: ${areaName.value}');
      print('  locationUrl: ${locationUrl.value}');
      print('  instructions: ${detailsText.value}');
      print('  pdfLink: ${pdfLink.value}');
      print('  hasAddressInfo: $hasAddressInfo');
      print('  hasMapLocation: $hasMapLocation');
      print('  hasDescription: $hasDescription');
      print('  hasPdf: $hasPdf');
    }
  }

  /// Check if street/area info exists
  bool get hasAddressInfo {
    return streetName.value.isNotEmpty || areaName.value.isNotEmpty;
  }

  /// Check if map location exists
  bool get hasMapLocation {
    return locationUrl.value.isNotEmpty;
  }

  /// Check if description exists
  bool get hasDescription {
    return detailsText.value.isNotEmpty;
  }

  /// Check if PDF exists
  bool get hasPdf {
    return pdfLink.value.isNotEmpty;
  }
}
