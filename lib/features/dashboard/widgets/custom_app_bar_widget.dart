import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/local/storage_service.dart';
import '../../../data/networks/socket_service.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../controllers/notifications_controller.dart';

class CustomAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBarWidget({super.key});

  // Helper to get AppBar height based on screen size
  static double getAppBarHeight(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return isTablet ? 64.0 : 60.0;
  }

  @override
  Widget build(BuildContext context) {
    // Initialize notifications controller if not already initialized
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(NotificationsController());
    }

    // Detect if device is tablet/iPad
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final appBarHeight = getAppBarHeight(context);

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      toolbarHeight: appBarHeight,
      centerTitle: true,
      leading: Builder(
        builder: (context) {
          final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
          return IconButton(
            onPressed: () => _handleLogout(context),
            icon: Icon(
              Icons.logout,
              color: AppColors.textOnPrimary,
              size: isTablet ? 28.0 : 24.0,
            ),
            tooltip: 'Logout',
          );
        },
      ),
      title: Text(
        'todo'.tr,
        style: TextStyle(
          fontSize: isTablet ? 26.0 : 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
      ),
      actions: [
        // Notification icon with badge
        GetX<NotificationsController>(
          init: Get.find<NotificationsController>(),
          builder: (controller) {
            final pendingCount = controller.pendingPickups.length;
            final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.notifications);
                  },
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textOnPrimary,
                    size: isTablet ? 32.0 : 24.0,
                  ),
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: isTablet ? 8 : 6,
                    top: isTablet ? 8 : 6,
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 3 : 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: isTablet ? 16 : 14,
                        minHeight: isTablet ? 16 : 14,
                      ),
                      child: Center(
                        child: Text(
                          pendingCount > 9 ? '9+' : pendingCount.toString(),
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: isTablet ? 9 : 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Builder(
          builder: (context) {
            final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
            return TextButton.icon(
              onPressed: () {
                final storage = Get.find<StorageService>();
                final currentCode = Get.locale?.languageCode ?? 'en';
                final next = toggleLanguageCode(currentCode);
                saveLanguageCode(storage, next);
                Get.updateLocale(Locale(next));
              },
              icon: Icon(
                Icons.language_outlined,
                color: AppColors.textOnPrimary,
                size: isTablet ? 26.0 : 24.0,
              ),
              label: Text(
                (Get.locale?.languageCode == 'de' ? 'DE' : 'EN'),
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: isTablet ? 11.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textOnPrimary,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Handle logout functionality
  void _handleLogout(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr),
        content: Text('logout_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            child: Text(
              'logout'.tr,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform logout operations
  Future<void> _performLogout() async {
    try {
      // Clear notification controller cache
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().clearAllData();
        print('🧹 Notification controller cache cleared');
      }

      // Disconnect socket
      final socketService = Get.find<SocketService>();
      await socketService.disconnect();
      print('🔌 Socket disconnected');

      // Clear all storage
      final storage = Get.find<StorageService>();
      await storage.clear();
      print('🧹 Storage cleared');

      // Show success message
      SnackbarUtils.showSuccess(
        title: 'success'.tr,
        message: 'logout_success'.tr,
      );

      // Navigate to login and clear navigation stack
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      print('❌ Logout error: $e');
      SnackbarUtils.showError(title: 'error'.tr, message: 'logout_failed'.tr);
    }
  }

  @override
  Size get preferredSize {
    // Use the maximum height (tablet) as preferred size
    // The actual height is controlled by toolbarHeight in build method
    return const Size.fromHeight(64.0);
  }
}
