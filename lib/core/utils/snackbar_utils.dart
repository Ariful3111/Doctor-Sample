import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';

class SnackbarUtils {
  /// Safely show a snackbar with error handling
  static void showSafe({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    Widget? icon,
    EdgeInsets? margin,
    double? borderRadius,
  }) {
    try {
      final overlayContext = Get.overlayContext;
      final overlayState = Get.key.currentState?.overlay;
      if (overlayContext == null && overlayState == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final delayedOverlayContext = Get.overlayContext;
            final delayedOverlayState = Get.key.currentState?.overlay;
            if (delayedOverlayContext == null && delayedOverlayState == null) {
              return;
            }
            showSafe(
              title: title,
              message: message,
              position: position,
              backgroundColor: backgroundColor,
              colorText: colorText,
              duration: duration,
              icon: icon,
              margin: margin,
              borderRadius: borderRadius,
            );
          } catch (_) {}
        });
        return;
      }

      // Close any existing snackbar safely
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      // Show snackbar immediately
      // Get.snackbar automatically handles context and overlay
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: backgroundColor,
        colorText: colorText,
        duration: duration ?? const Duration(seconds: 3),
        icon: icon,
        margin: margin ?? const EdgeInsets.all(10),
        borderRadius: borderRadius ?? 8,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
      );
    } catch (e) {
      debugPrint('Snackbar error: $e - Title: $title, Message: $message');
    }
  }

  /// Show success snackbar
  static void showSuccess({
    required String title,
    required String message,
    Duration? duration,
  }) {
    showSafe(
      title: title,
      message: message,
      backgroundColor: AppColors.primary,
      colorText: AppColors.surface,
      duration: duration,
      icon: Icon(Icons.check_circle, color: AppColors.surface),
    );
  }

  /// Show error snackbar
  static void showError({
    required String title,
    required String message,
    Duration? duration,
  }) {
    showSafe(
      title: title,
      message: message,
      backgroundColor: AppColors.error.withValues(alpha: 0.1),
      colorText: AppColors.error,
      duration: duration,
      icon: Icon(Icons.error, color: AppColors.error),
    );
  }

  /// Show warning snackbar
  static void showWarning({
    required String title,
    required String message,
    Duration? duration,
  }) {
    showSafe(
      title: title,
      message: message,
      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
      colorText: AppColors.warning,
      duration: duration,
      icon: Icon(Icons.warning, color: AppColors.warning),
    );
  }

  /// Show info snackbar
  static void showInfo({
    required String title,
    required String message,
    Duration? duration,
  }) {
    showSafe(
      title: title,
      message: message,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      colorText: AppColors.primary,
      duration: duration,
      icon: Icon(Icons.info, color: AppColors.primary),
    );
  }

  /// Close current snackbar safely
  static void closeCurrent() {
    try {
      if (Get.context != null && Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    } catch (e) {
      debugPrint('Error closing snackbar: $e');
    }
  }
}
