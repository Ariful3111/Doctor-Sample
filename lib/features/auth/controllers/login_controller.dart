import 'package:doctor_app/data/local/storage_service.dart';
import 'package:doctor_app/data/networks/socket_service.dart';
import 'package:doctor_app/features/auth/models/login_model.dart';
import 'package:doctor_app/features/auth/repositories/login_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/global_notification_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../dashboard/controllers/notifications_controller.dart';

class LoginController extends GetxController {
  final LoginRepository loginRepository;
  LoginController({required this.loginRepository});
  final formKey = GlobalKey<FormState>();
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();
  final _isLoading = false.obs;
  final _obscurePassword = true.obs;
  final loggedInUsername = Rxn<String>();

  bool get isLoading => _isLoading.value;
  bool get obscurePassword => _obscurePassword.value;
  String? get username => loggedInUsername.value;

  final allCategories = Rxn<LoginModel>();

  @override
  void onClose() {
    userIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  String? validateUserId(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_your_user_id'.tr;
    }
    return null;
  }

  /// Validate password field
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_your_password'.tr;
    }
    if (value.length < 6) {
      return 'password_min_length'.trParams({'min': '6'});
    }
    return null;
  }

  /// Handle login process
  void handleLogin() async {
    if (!formKey.currentState!.validate()) {
      print('⚠️ Form validation failed');
      return;
    }

    print('🚀 Login started');
    _isLoading.value = true;

    try {
      final userId = userIdController.text.trim();
      final password = passwordController.text.trim();

      print('🔑 Username: $userId, Password: ${'*' * password.length}');

      final response = await loginRepository.execute(
        userName: userId,
        password: password,
      );

      // Handle response
      if (response.isRight()) {
        final data = response.getRight().toNullable()!;
        print('✅ Login successful');
        print('👤 Driver: ${data.driver?.name} (ID: ${data.driver?.id})');
        print('📱 Driver Username: ${data.driver?.username}');
        print('🔍 Full driver object: ${data.driver.toString()}');

        // Get username from API response (not from form input)
        final username = data.driver?.username ?? '';
        print('👤 Username from API response: $username');
        print('🔍 Username is empty: ${username.isEmpty}');

        // Store username in controller (reactive variable)
        loggedInUsername.value = username;
        print('💾 Stored username in controller: $username');

        // Get storage service
        final storage = Get.find<StorageService>();

        // Save new user data
        final driverId = data.driver!.id!.toInt();
        final driverName = data.driver!.name;

        // Save all data
        await storage.write(key: 'id', value: driverId);
        await storage.write(key: 'username', value: username);
        await storage.write(key: 'name', value: driverName);

        print('✅ Saved driverId: $driverId');
        print('✅ Saved username: $username');
        print('✅ Saved driver name: $driverName');

        // Verify storage write
        final verifyUsername = storage.read<String>(key: 'username');
        print('🔍 Verification - Username in storage: $verifyUsername');

        print(
          '💾 Saved new user data: Driver ID=$driverId, Username=$username, Name=$driverName',
        );

        // Clear notification controller cache for new user login
        if (Get.isRegistered<NotificationsController>()) {
          Get.find<NotificationsController>().clearAllData();
          print('🧹 Notification cache cleared for new login');
        }

        // Disconnect old socket and connect new one (non-blocking)
        // Run socket connection in background without waiting
        _connectSocketInBackground(driverId);

        // Update state
        allCategories.value = data;

        // Clear form and navigate
        _clearForm();
        _showSuccessMessage(data.driver!.name.toString());

        print('🚀 Navigating to dashboard...');
        Get.offAllNamed(AppRoutes.todaysTask);
        print('✅ Navigation completed');
      } else {
        final error = response.getLeft().toNullable() ?? 'Unknown error';
        print('❌ Login failed: $error');
        // _showErrorMessage(error.toString());
        Get.snackbar(
          'error'.tr,
          error.toString(),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (error, stackTrace) {
      print('💥 Exception: $error');
      print('📍 Stack: $stackTrace');
      _showErrorMessage('Unexpected error: $error');
    } finally {
      _isLoading.value = false;
      print('🏁 Loading stopped');
    }
  }

  /// Clear form fields
  void _clearForm() {
    userIdController.clear();
    passwordController.clear();
  }

  /// Show success message
  void _showSuccessMessage(String userId) {
    SnackbarUtils.showSuccess(
      title: 'success'.tr,
      message: 'login_success_welcome'.trParams({'name': userId}),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    SnackbarUtils.showError(
      title: 'error'.tr,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  bool get hasFormData {
    return userIdController.text.isNotEmpty ||
        passwordController.text.isNotEmpty;
  }

  void resetForm() {
    formKey.currentState?.reset();
    _clearForm();
    _obscurePassword.value = true;
  }

  /// Connect socket in background without blocking UI
  void _connectSocketInBackground(int driverId) {
    Future.delayed(Duration.zero, () async {
      try {
        final socketService = Get.find<SocketService>();
        await socketService.disconnect();
        print('🔌 Old socket disconnected');

        await socketService.connect(driverId: driverId);
        print('🔌 New socket connected for driver: $driverId');

        // Ensure global notification service connects and attaches listeners
        if (Get.isRegistered<GlobalNotificationService>()) {
          await Get.find<GlobalNotificationService>().ensureSocketConnected(
            driverId,
          );
          print('🌍 GlobalNotificationService listeners attached');
        }

        // Fetch initial notifications after socket connects
        if (Get.isRegistered<NotificationsController>()) {
          await Get.find<NotificationsController>().fetchPendingPickups(
            silent: false,
          );
          print('📲 Initial notifications fetched after login');
        }
      } catch (socketError) {
        print('⚠️ Socket error (non-critical): $socketError');
        // Don't block login if socket fails
      }
    });
  }
}
