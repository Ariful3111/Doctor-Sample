import 'package:get/get.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/local/storage_service.dart';
import '../../../data/networks/socket_service.dart';
import '../../features/dashboard/controllers/notifications_controller.dart';

/// Global service to keep socket connection alive and handle real-time notifications
/// This ensures notifications are received even when the user is not on notifications screen
class GlobalNotificationService extends GetxService {
  late SocketService _socketService;
  late StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _initializeGlobalSocket();
  }

  /// Initialize socket at app level (not dependent on screen)
  Future<void> _initializeGlobalSocket() async {
    try {
      // Check if services are available
      if (!Get.isRegistered<StorageService>()) {
        print('⚠️ [Global] StorageService not registered yet');
        return;
      }

      if (!Get.isRegistered<SocketService>()) {
        print('⚠️ [Global] SocketService not registered yet');
        return;
      }

      _storageService = Get.find<StorageService>();
      _socketService = Get.find<SocketService>();

      final driverId = await _storageService.read<int>(key: 'id');
      if (driverId != null && driverId > 0) {
        // Connect socket if not already connected
        if (!_socketService.isConnected) {
          await _socketService.connect(driverId: driverId);
          print(
            '🌍 [Global] Socket connected at app level for driver: $driverId',
          );
        }

        _setupGlobalEventListeners(driverId);
      } else {
        print('ℹ️ [Global] No valid driver ID found - user not logged in yet');
      }
    } catch (e) {
      print('❌ [Global] Error initializing global socket: $e');
    }
  }

  /// Setup event listeners at global level
  void _setupGlobalEventListeners(int driverId) {
    final socket = _socketService.socket;
    if (socket == null) return;

    // Handle extra_pickup_created - show notification immediately
    socket.off('extra_pickup_created'); // Remove old listeners
    socket.on('extra_pickup_created', (data) {
      print('🌍 [Global] extra_pickup_created received: $data');
      print('🌍 [Global] Data type: ${data.runtimeType}');

      // Show notification immediately
      SnackbarUtils.showSuccess(
        title: 'new_extra_pickup'.tr,
        message: 'new_extra_pickup_message'.tr,
      );

      // Update notifications list immediately
      if (Get.isRegistered<NotificationsController>()) {
        final controller = Get.find<NotificationsController>();

        // Try to add notification directly if data is proper format
        if (data is Map) {
          // Convert to Map<String, dynamic>
          final pickupMap = Map<String, dynamic>.from(data);
          controller.addNewNotification(pickupMap);
          print('🔔 [Global] Notification added directly from socket data');
        } else {
          print('⚠️ [Global] Data is not Map, fetching from backend');
          // Otherwise fetch fresh data from backend
          controller.fetchPendingPickups();
        }
      } else {
        print('⚠️ [Global] NotificationsController not registered');
      }
    });

    // Handle extra_pickup_accepted
    socket.off('extra_pickup_accepted');
    socket.on('extra_pickup_accepted', (data) {
      print('🌍 [Global] extra_pickup_accepted: $data');
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().fetchPendingPickups();
      }
    });

    // Handle extra_pickup_rejected
    socket.off('extra_pickup_rejected');
    socket.on('extra_pickup_rejected', (data) {
      print('🌍 [Global] extra_pickup_rejected: $data');
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().fetchPendingPickups();
      }
    });

    // Handle extra_pickup_expired
    socket.off('extra_pickup_expired');
    socket.on('extra_pickup_expired', (data) {
      print('🌍 [Global] extra_pickup_expired: $data');

      SnackbarUtils.showWarning(
        title: 'Extra Pickup Expired',
        message: 'An extra pickup has expired.',
      );

      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().fetchPendingPickups();
      }
    });

    print('📡 [Global] Event listeners setup complete');
  }

  /// Public method to attach listeners when socket connects.
  /// Call this from SocketService when a connection or reconnection happens.
  void attachListeners(int driverId) {
    try {
      // Ensure services are available
      if (!Get.isRegistered<StorageService>() ||
          !Get.isRegistered<SocketService>()) {
        print('⚠️ [Global] Services not registered yet for attachListeners');
        return;
      }

      _storageService = Get.find<StorageService>();
      _socketService = Get.find<SocketService>();

      // Only attach if socket is available
      if (_socketService.socket != null) {
        _setupGlobalEventListeners(driverId);
        print('🌍 [Global] attachListeners completed for driver: $driverId');
      } else {
        print('⚠️ [Global] Socket not available to attach listeners');
      }
    } catch (e) {
      print('❌ [Global] Error in attachListeners: $e');
    }
  }

  /// Reconnect socket if disconnected
  Future<void> ensureSocketConnected(int driverId) async {
    try {
      if (!_socketService.isConnected) {
        print('🔄 [Global] Reconnecting socket...');
        await _socketService.connect(driverId: driverId);
        _setupGlobalEventListeners(driverId);
      }
    } catch (e) {
      print('❌ [Global] Error reconnecting: $e');
    }
  }

  @override
  void onClose() {
    print('🔌 [Global] Global notification service closed');
    super.onClose();
  }
}
