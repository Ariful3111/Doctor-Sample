import 'package:get/get.dart';
import '../../../data/repositories/pending_drop_date_repository.dart';
import '../../../core/routes/app_routes.dart';

class PendingDropDateController extends GetxController {
  final PendingDropDateRepository _repository = PendingDropDateRepository();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxList<String> pendingDates = <String>[].obs;
  final RxString errorMessage = ''.obs;

  late int driverId;

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _fetchPendingDates();
  }

  /// Load arguments from previous screen
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['driverId'] != null) {
      driverId = args['driverId'];
    } else {
      // Default driverId
      driverId = 1;
    }
    print('📋 PendingDropDateController - Driver ID: $driverId');
  }

  /// Fetch pending drop dates from API
  Future<void> _fetchPendingDates() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔄 Fetching pending drop dates for driverId: $driverId');

      final result = await _repository.getPendingDropDates(driverId);

      if (result.success) {
        pendingDates.value = result.pendingDates;
        print('✅ Pending dates loaded: ${pendingDates.length} dates');
      } else {
        errorMessage.value = 'Failed to load pending dates';
        print('❌ API returned success: false');
      }
    } catch (e) {
      errorMessage.value = 'Error loading pending dates: $e';
      print('❌ Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle date selection - Navigate to Drop Location screen
  void selectDate(String date) {
    print('📅 Selected pending date: $date');
    // Navigate to drop location screen with selected date
    Get.toNamed(
      AppRoutes.dropLocation,
      arguments: {'selectedDate': date, 'fromPendingDropDate': true},
    );
  }

  /// Refresh pending dates
  Future<void> refreshPendingDates() async {
    await _fetchPendingDates();
  }
}
