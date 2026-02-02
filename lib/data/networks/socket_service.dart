import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'dart:async';
import '../../core/constants/network_paths.dart';
import '../services/global_notification_service.dart';

/// Socket.IO service for real-time notifications
/// Handles connection, events, and room management for driver notifications
class SocketService extends GetxService {
  IO.Socket? _socket;
  final RxBool _isConnected = false.obs;
  Timer? _keepAliveTimer;

  // Getters
  bool get isConnected => _isConnected.value;
  IO.Socket? get socket => _socket;

  /// Initialize and connect to socket server
  Future<void> connect({required int driverId}) async {
    try {
      // Disconnect if already connected
      if (_socket != null) {
        await disconnect();
      }

      // Create socket connection with auto-reconnect
      _socket = IO.io(
        NetworkPaths.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Use WebSocket transport
            .enableAutoConnect() // Enable automatic reconnection
            .enableReconnection() // Enable reconnection on disconnect
            .setReconnectionAttempts(
              999999,
            ) // Virtually unlimited reconnection attempts
            .setReconnectionDelay(1000) // 1 second delay between attempts
            .setReconnectionDelayMax(5000) // Max 5 seconds delay
            .setTimeout(20000) // 20 second connection timeout (increased)
            .enableForceNew() // Force new connection
            .disableMultiplex() // Disable multiplexing for better stability
            .setExtraHeaders({
              'driver-id': driverId.toString(),
            }) // Send driver ID
            .build(),
      );

      // Setup event listeners
      _setupEventListeners(driverId);

      // Connect to server
      _socket!.connect();

      print('🔌 Socket connecting to ${NetworkPaths.baseUrl}...');
      print('🔄 Auto-reconnect enabled with unlimited attempts');
    } catch (e) {
      print('❌ Socket connection error: $e');
    }
  }

  /// Setup socket event listeners
  void _setupEventListeners(int driverId) {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected.value = true;
      print('✅ Socket connected successfully');
      print('🚪 Driver room: driver-$driverId');

      // Explicitly join the driver-specific room
      _socket!.emit('join-driver', driverId);
      print('📡 Emitted join-driver event with driverId: $driverId');

      // Start keep-alive timer to prevent connection timeout
      _startKeepAliveTimer();

      // Attach global notification listeners if registered
      try {
        if (Get.isRegistered<GlobalNotificationService>()) {
          Get.find<GlobalNotificationService>().attachListeners(driverId);
        }
      } catch (e) {
        print('⚠️ Error attaching global listeners: $e');
      }
      print(
        '🎯 Listening for events: extra_pickup_created, accepted, rejected, expired',
      );
      print('🔔 Real-time notifications are now active for driver-$driverId');
    });

    _socket!.onDisconnect((_) {
      _isConnected.value = false;
      _stopKeepAliveTimer(); // Stop keep-alive timer on disconnect
      print('❌ Socket disconnected');
      print('🔄 Auto-reconnecting...');
    });

    _socket!.onReconnect((attempt) {
      print('🔄 Socket reconnected after $attempt attempts');
      _isConnected.value = true;
      _startKeepAliveTimer(); // Restart keep-alive timer on reconnect
      // Re-join room on reconnection
      _socket!.emit('join-driver', driverId);
      print('📡 Re-emitted join-driver event with driverId: $driverId');
      // Re-attach global listeners on reconnect
      try {
        if (Get.isRegistered<GlobalNotificationService>()) {
          Get.find<GlobalNotificationService>().attachListeners(driverId);
        }
      } catch (e) {
        print('⚠️ Error re-attaching global listeners: $e');
      }
    });

    _socket!.onReconnectAttempt((attempt) {
      print('🔄 Reconnection attempt #$attempt');
    });

    _socket!.onReconnectError((error) {
      print('❌ Reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ Reconnection failed after all attempts');
    });

    _socket!.onConnectError((error) {
      print('❌ Socket connection error: $error');
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
    });

    // Note: Extra pickup events are handled by GlobalNotificationService
    // Do not handle them here to avoid duplicate listeners
  }

  /// Emit event to server
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected.value) {
      _socket!.emit(event, data);
      print('📤 Emitted event: $event');
    } else {
      print('⚠️ Cannot emit, socket not connected');
    }
  }

  /// Start keep-alive timer to prevent connection timeout
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel(); // Cancel any existing timer
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_socket != null && _isConnected.value) {
        _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
        print('💓 Keep-alive ping sent');
      }
    });
    print('⏰ Keep-alive timer started (25s interval)');
  }

  /// Stop keep-alive timer
  void _stopKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    print('⏰ Keep-alive timer stopped');
  }

  /// Disconnect socket
  Future<void> disconnect() async {
    _stopKeepAliveTimer(); // Stop keep-alive timer
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected.value = false;
      print('🔌 Socket disconnected and disposed');
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
