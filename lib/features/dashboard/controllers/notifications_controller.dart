import 'package:get/get.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/services/tour_state_service.dart';
import '../../../data/local/storage_service.dart';
import '../repositories/extra_pickup_repository.dart';
import 'todays_task_controller.dart';

class NotificationsController extends GetxController {
  final ExtraPickupRepository _repository = ExtraPickupRepository();
  final _storageService = Get.find<StorageService>();

  final RxList<Map<String, dynamic>> pendingPickups =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<int> processingIds = <int>{}.obs;
  final RxSet<int> acceptingIds = <int>{}.obs;
  final RxSet<int> rejectingIds = <int>{}.obs;

  /// Store complete doctor data from accepted pickups
  /// Map: doctorId -> complete doctor data (with street, area, zip)
  final RxMap<int, Map<String, dynamic>> acceptedDoctorsCache =
      <int, Map<String, dynamic>>{}.obs;

  /// Store pending extra pickup data by extraPickupId for later lookup
  /// Map: extraPickupId -> complete extra pickup data
  final RxMap<int, Map<String, dynamic>> extraPickupCacheById =
      <int, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔔 [Controller] NotificationsController initialized');
  }

  @override
  void onReady() {
    super.onReady();
    print(
      '🔔 [Controller] NotificationsScreen is now visible - auto-refreshing',
    );
    // Fetch notifications every time the page becomes visible (non-silent mode)
    fetchPendingPickups(silent: false);
  }

  @override
  void onClose() {
    print('🔔 [Controller] NotificationsController closed');
    super.onClose();
  }

  /// Clear all notification data (in-memory caches)
  /// This should be called on logout or when switching users
  void clearAllData() {
    print('🧹 [Controller] Clearing all notification data');
    pendingPickups.clear();
    acceptedDoctorsCache.clear();
    extraPickupCacheById.clear();
    processingIds.clear();
  }

  /// Fetch pending pickups from backend
  Future<void> fetchPendingPickups({bool silent = false}) async {
    try {
      isLoading.value = true;

      // Get driver ID from storage
      final driverId = await _storageService.read<int>(key: 'id');
      print('📲 [fetchPendingPickups] Driver ID: $driverId');
      if (driverId == null) {
        if (!silent) {
          _showError('driver_id_not_found'.tr);
        }
        return;
      }

      // Call backend API to get pending pickups
      final response = await _repository.getPendingPickups(driverId: driverId);

      response.fold(
        (error) {
          if (!silent) {
            _showError(error);
          } else {
            print('⚠️ [Silent] Fetch error: $error');
          }
        },
        (data) {
          // Filter to show only pending status
          final pendingOnly = data.where((pickup) {
            final status = pickup['status']?.toString().toLowerCase() ?? '';
            return status == 'pending' || status == 'expired';
          }).toList();

          // Cache extra pickups by ID for later lookup
          for (var pickup in pendingOnly) {
            final pickupId = pickup['id'] as int?;
            if (pickupId != null) {
              extraPickupCacheById[pickupId] = Map<String, dynamic>.from(
                pickup,
              );
              print('📦 Cached extra pickup: ID $pickupId');
            }
          }

          // Cache doctor data from pending pickups
          for (var pickup in pendingOnly) {
            if (pickup['doctors'] != null && pickup['doctors'] is List) {
              for (var doctor in pickup['doctors']) {
                final doctorId = doctor['id'] as int?;
                if (doctorId != null) {
                  acceptedDoctorsCache[doctorId] = Map<String, dynamic>.from(
                    doctor,
                  );
                  print(
                    '📦 Cached doctor from pending pickup: ${doctor['name']} (ID: $doctorId)',
                  );
                }
              }
            }
          }

          pendingPickups.value = pendingOnly;
          print(
            '✅ Fetched ${pendingOnly.length} pending pickups (filtered from ${data.length} total)',
          );
          print('🔔 Badge count updated: ${pendingOnly.length}');

          // Show success message with count if not silent
          if (!silent && pendingOnly.isNotEmpty) {
            _showSuccess('${pendingOnly.length} pending pickups found');
          } else if (!silent && pendingOnly.isEmpty) {
            _showSuccess('No pending pickups at the moment');
          }
        },
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new notification to pending list (called by socket event)
  void addNewNotification(Map<String, dynamic> pickupData) {
    print('🔔 [Controller] addNewNotification called');
    print('🔔 [Controller] Data: $pickupData');

    // Ensure we have required fields
    if (pickupData['id'] == null) {
      print('❌ [Controller] No ID in pickup data');
      // Fetch from backend as fallback
      fetchPendingPickups();
      return;
    }

    final id = pickupData['id'];
    final exists = pendingPickups.any((p) => p['id'] == id);

    print('🔔 [Controller] ID: $id, Exists: $exists');

    if (!exists) {
      // Ensure status is pending
      if (!pickupData.containsKey('status')) {
        pickupData['status'] = 'pending';
      }

      // Add to beginning of list - use .value assignment for proper reactivity
      final newList = [pickupData, ...pendingPickups];
      pendingPickups.value = newList;

      print('🔔 [Controller] ✅ Added! New count: ${pendingPickups.length}');
    } else {
      print('⚠️ [Controller] Already in list');
    }
  }

  /// Accept pickup - extract doctor data from notification response directly
  Future<void> acceptPickup(int pickupId, int index) async {
    try {
      processingIds.add(pickupId);
      acceptingIds.add(pickupId);

      final response = await _repository.acceptExtraPickup(id: pickupId);

      response.fold((error) => _showError(error), (data) {
        print('✅ Accept response received: $data');

        // Remove from pending list
        if (index < pendingPickups.length) {
          pendingPickups.removeAt(index);
        }

        _showSuccess('pickup_accepted_successfully'.tr);

        // Extract doctors from the accepted pickup response
        // This gives us the ORIGINAL doctor data before it was added to tour
        List<Map<String, dynamic>> acceptedDoctors = [];
        if (data['doctors'] != null && data['doctors'] is List) {
          acceptedDoctors = List<Map<String, dynamic>>.from(
            data['doctors'].map((d) => Map<String, dynamic>.from(d as Map)),
          );
          print(
            '✅ Extracted ${acceptedDoctors.length} doctors from acceptance response',
          );
          for (var doc in acceptedDoctors) {
            print(
              '   Doctor: ${doc['name']}, street: ${doc['street']}, area: ${doc['area']}, zip: ${doc['zip']}, email: ${doc['email']}, phone: ${doc['phone']}, pdfFile: ${doc['pdfFile']}',
            );

            // Store in cache so we can fill missing data when tour displays
            final doctorId = doc['id'];
            if (doctorId != null) {
              // Convert to int for consistent key matching
              final doctorIdInt = (doctorId is int)
                  ? doctorId
                  : int.tryParse(doctorId.toString()) ?? 0;

              if (doctorIdInt > 0) {
                acceptedDoctorsCache[doctorIdInt] = doc;
                print('📦 Cached complete doctor data for ID: $doctorIdInt');
                print('   Cached data: ${acceptedDoctorsCache[doctorIdInt]}');
              } else {
                print('❌ Invalid doctor ID for caching: $doctorId');
              }
            } else {
              print('❌ Doctor ID is null');
            }
          }
        } else {
          print('⚠️ No doctors in acceptance response');
        }

        // Now refresh tour list - the new doctors will already have complete data
        // because we extracted it from the response
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            print('🔄 Refreshing tour tasks to show accepted pickup...');
            Get.find<TodaysTaskController>().refreshTasks();

            // If tour screen is open, show info message
            if (Get.isRegistered<TourStateService>()) {
              final tourService = Get.find<TourStateService>();
              if (tourService.hasActiveTour) {
                SnackbarUtils.showInfo(
                  title: 'Tour Updated',
                  message: 'New doctors added to your tour. Check tour list!',
                  duration: const Duration(seconds: 3),
                );
              }
            }
          } catch (e) {
            print('⚠️ Could not refresh tasks: $e');
          }
        });
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      processingIds.remove(pickupId);
      acceptingIds.remove(pickupId);
    }
  }

  /// Reject pickup
  Future<void> rejectPickup(int pickupId, int index) async {
    try {
      processingIds.add(pickupId);
      rejectingIds.add(pickupId);

      final response = await _repository.rejectExtraPickup(id: pickupId);

      response.fold((error) => _showError(error), (data) {
        // Remove from pending list
        pendingPickups.removeAt(index);

        _showSuccess('pickup_rejected_successfully'.tr);

        // Refresh tour list to reflect changes
        try {
          Get.find<TodaysTaskController>().refreshTasks();
        } catch (e) {
          print('⚠️ Could not refresh tasks: $e');
        }
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      processingIds.remove(pickupId);
      rejectingIds.remove(pickupId);
    }
  }

  void _showSuccess(String message) {
    SnackbarUtils.showSuccess(
      title: 'success'.tr,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    SnackbarUtils.showError(
      title: 'error'.tr,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  /// Get cached doctor data if available
  Map<String, dynamic>? getCachedDoctorData(int doctorId) {
    return acceptedDoctorsCache[doctorId];
  }

  /// Get cached extra pickup data by extraPickupId
  /// This helps find doctor data for old extra pickups that were already accepted
  Map<String, dynamic>? getCachedExtraPickup(int extraPickupId) {
    return extraPickupCacheById[extraPickupId];
  }
}
