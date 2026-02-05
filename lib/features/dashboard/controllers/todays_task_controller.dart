import 'package:doctor_app/features/dashboard/models/tour_model.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/tour_state_service.dart';
import '../../../data/local/storage_service.dart';
import '../repositories/get_tour_repo.dart';
import '../repositories/extra_pickup_repository.dart';
import 'package:doctor_app/shared/extensions/date_extensions.dart';
import 'notifications_controller.dart';
import '../widgets/tour_start_confirmation_dialog.dart';

class TodaysTaskController extends GetxController {
  final GetTourRepository getTourRepository;
  TodaysTaskController({required this.getTourRepository});
  // Observable variables
  final _isLoading = false.obs;
  final _selectedDate = DateTime.now().obs;
  final _currentScreenMode = 'today_task'.obs;
  // Getters
  bool get isLoading => _isLoading.value;
  DateTime get selectedDate => _selectedDate.value;
  String get currentScreenMode => _currentScreenMode.value;
  final todaySchedule = Rxn<CombinedScheduleModel>();

  @override
  void onInit() {
    super.onInit();
    loadTodaysTasks();
  }

  void loadTodaysTasks() {
    print('📋 [TodaysTask] Loading tasks...');
    _isLoading.value = true;
    _loadTodaysTasksAsync();
  }

  /// Load today's tasks with proper async/await
  /// Ensures extra pickups are cached BEFORE parsing tours
  Future<void> _loadTodaysTasksAsync() async {
    print('📋 [TodaysTask] _loadTodaysTasksAsync started');
    await _fetchAllExtraPickups(); // Wait for extra pickups to be cached first!
    await _fetchTours();
    print('📋 [TodaysTask] _loadTodaysTasksAsync completed');
  }

  /// Fetch and cache all extra pickups before loading tours
  /// This ensures extra pickup location data is available for tour doctors
  Future<void> _fetchAllExtraPickups() async {
    try {
      final driverId = await _getDriverIdAsync();
      if (driverId == null) {
        // User not logged in - silently skip
        return;
      }

      final result = await _repository().getPendingPickups(driverId: driverId);
      result.fold(
        (error) => print('⚠️ Could not pre-cache extra pickups: $error'),
        (pickups) {
          final notifController = Get.find<NotificationsController>();
          for (var pickup in pickups) {
            final pickupId = pickup['id'] as int?;
            if (pickupId != null) {
              notifController.extraPickupCacheById[pickupId] = pickup;
              print(
                '📦 Pre-cached extra pickup: ID $pickupId (${pickup['street']}, ${pickup['area']})',
              );
            }
          }
          print('✅ Pre-cached ${pickups.length} extra pickups');
        },
      );
    } catch (e) {
      print('⚠️ Error pre-caching extra pickups: $e');
    }
  }

  /// Helper to get driver ID asynchronously
  Future<int?> _getDriverIdAsync() async {
    final storage = Get.find<StorageService>();
    return await storage.read<int>(key: 'id');
  }

  /// Helper to get repository
  ExtraPickupRepository _repository() => ExtraPickupRepository();

  Future<void> _fetchTours() async {
    try {
      final storage = Get.find<StorageService>();
      final driverId = await storage.read<int>(key: 'id');

      if (driverId == null) {
        // User not logged in - silently return without error
        todaySchedule.value = null;
        _isLoading.value = false;
        return;
      }

      final String date = _selectedDate.value.toApiDate();
      print('🗓️ Fetching tours for driver $driverId, date: $date');

      final response = await getTourRepository.execute(
        date: date,
        driverId: driverId,
      );

      response.fold(
        (error) {
          print('❌ Error fetching tours: $error');
          // Create empty schedule so UI doesn't break
          todaySchedule.value = CombinedScheduleModel(
            success: false,
            message: error,
            data: CombinedScheduleData(
              driverId: driverId.toString(),
              date: _selectedDate.value.toApiDate(),
              totalTours: 0,
              appointments: [],
              tours: [],
            ),
          );
        },
        (data) {
          final toursCount = data.data?.tours?.length ?? 0;
          print('✅ Tours fetched for driver $driverId: $toursCount tours');

          // Debug: Print doctors for each tour
          if (data.data?.tours != null) {
            for (var i = 0; i < data.data!.tours!.length; i++) {
              final tour = data.data!.tours![i];
              final regularCount = tour.regularDoctors?.length ?? 0;
              final allCount = tour.allDoctors.length;
              print(
                '   Tour ${i + 1} (${tour.name}): $regularCount regularDoctors, $allCount allDoctors',
              );
              // Print all doctor names for debug
              if (tour.allDoctors.isNotEmpty) {
                for (var doc in tour.allDoctors) {
                  print('Doctor: ${doc.name} (ID: ${doc.id})');
                }
              }
            }
          }

          // Debug: Print appointment statuses
          if (data.data?.appointments != null) {
            for (var apt in data.data!.appointments!) {
              print(
                'AppointmentId: [1m${apt.appointmentId}[0m, Status: [1m${apt.status}[0m',
              );
            }
          }
          // Cache all doctor data for later use
          _cacheDoctorData(data);
          todaySchedule.value = data;
        },
      );
    } catch (e) {
      print('❌ Exception fetching tours: $e');
      todaySchedule.value = null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh tasks
  Future<void> refreshTasks() async {
    loadTodaysTasks();
  }

  /// Navigate to tour details
  void navigateToTourDetails(String taskId) {
    final tourStateService = Get.find<TourStateService>();

    // Date validation is now disabled - users can continue tours across date boundaries
    // (Removed the date mismatch check)

    // Find tour info for confirmation dialog
    final tours = todaySchedule.value?.data?.tours ?? [];
    final tour = tours.firstWhere(
      (t) => t.id?.toString() == taskId,
      orElse: () => tours.first,
    );

    final tourName = tour.name ?? 'tour'.tr;
    final doctorCount = tour.allDoctors.length;

    // Show confirmation dialog
    Get.dialog(
      TourStartConfirmationDialog(
        tourName: tourName,
        doctorCount: doctorCount,
        onConfirm: () async {
          final appointmentId = int.tryParse(
            todaySchedule.value?.data?.getAppointmentIdForTour(
                  int.tryParse(taskId),
                ) ??
                '',
          );
          // Start the tour
          print('🚀 Starting tour: $taskId');
          await tourStateService.startTour(taskId, appointmentId);
          print('✅ Tour started, navigating to tour list');
          // Add small delay to ensure tour state is updated
          await Future.delayed(const Duration(milliseconds: 300));
          // Navigate to tour details
          Get.toNamed(AppRoutes.tourDrList, arguments: {'taskId': taskId});
        },
      ),
      barrierDismissible: false,
    );
  }

  /// Navigate to Drop Location screen
  void navigateToDropLocation({String? taskId}) {
    Get.toNamed(
      AppRoutes.dropLocation,
      arguments: taskId != null ? {'taskId': taskId} : {},
    );
  }

  /// Switch to Today's Task mode
  void switchToTodayTask() {
    _currentScreenMode.value = 'today_task';
  }

  /// Switch to Drop Location mode - Navigate to Pending Drop Date directly
  void switchToDropLocation() {
    _currentScreenMode.value = 'drop_location';
    // Navigate to Pending Drop Date screen directly (full page)
    _getDriverIdAndNavigate();
  }

  /// Get actual driver ID from storage and navigate to pending drop date
  void _getDriverIdAndNavigate() async {
    try {
      final storage = Get.find<StorageService>();
      final driverId = await storage.read<int>(key: 'id') ?? 1;

      print('👤 Driver ID: $driverId');

      Get.toNamed(
        AppRoutes.pendingDropDate,
        arguments: {
          'driverId': driverId, // Actual logged-in driver ID
        },
      );
    } catch (e) {
      print('❌ Error getting driver ID: $e');
      // Fallback to hardcoded if storage fails
      Get.toNamed(AppRoutes.pendingDropDate, arguments: {'driverId': 1});
    }
  }

  /// Cache all doctor data from tours into NotificationsController
  /// This ensures old/regular doctors have their complete info available
  /// Also fetches extra pickup details for doctors marked as extra pickups
  void _cacheDoctorData(CombinedScheduleModel data) {
    try {
      final notifController = Get.find<NotificationsController>();

      if (data.data?.tours != null) {
        int cachedCount = 0;
        final extraPickupRepository = ExtraPickupRepository();

        for (var tour in data.data!.tours!) {
          if (tour.allDoctors.isNotEmpty) {
            for (var doctor in tour.allDoctors) {
              if (doctor.id != null) {
                // Build complete doctor data map
                final doctorData = {
                  'id': doctor.id,
                  'name': doctor.name,
                  'street': doctor.street,
                  'area': doctor.area,
                  'zip': doctor.zip,
                  'locationLink': doctor.locationLink,
                  'pdfFile': doctor.pdfFile,
                  'phone': doctor.phone,
                  'email': doctor.email,
                  'description': doctor.description,
                };

                // Cache it
                notifController.acceptedDoctorsCache[doctor.id!] = doctorData;
                cachedCount++;
                print(
                  '📦 Cached doctor data: ${doctor.name} (ID: ${doctor.id})',
                );

                // If this is an extra pickup with no street data, fetch extra pickup details
                if (doctor.extraPickupId != null &&
                    (doctor.street == null || doctor.street!.isEmpty)) {
                  _fetchAndCacheExtraPickupData(
                    doctor.extraPickupId!,
                    doctor.id!,
                    notifController,
                    extraPickupRepository,
                  );
                }
              }
            }
          }
        }
        print('✅ Cached $cachedCount doctors from tours');
      }
    } catch (e) {
      print('⚠️ Could not cache doctor data: $e');
    }
  }

  /// Fetch and cache extra pickup details asynchronously
  void _fetchAndCacheExtraPickupData(
    int extraPickupId,
    int doctorId,
    NotificationsController notifController,
    ExtraPickupRepository repository,
  ) {
    // No longer needed - extra pickups are pre-cached in _fetchAllExtraPickups
  }
}
