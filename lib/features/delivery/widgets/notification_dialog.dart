import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import 'notification_icon_widget.dart';
import 'notification_content_widget.dart';
import 'notification_buttons_widget.dart';

class NotificationDialog extends StatelessWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmText;
  final String? cancelText;
  final Widget? customIcon;

  const NotificationDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.onConfirm,
    this.onCancel,
    this.confirmText,
    this.cancelText,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            NotificationIconWidget(type: type, customIcon: customIcon),
            SizedBox(height: 16.h),

            // Title and Message
            NotificationContentWidget(title: title, message: message),
            SizedBox(height: 24.h),

            // Action Buttons
            NotificationButtonsWidget(
              type: type,
              onConfirm: onConfirm,
              onCancel: onCancel,
              confirmText: confirmText,
              cancelText: cancelText,
            ),
          ],
        ),
      ),
    );
  }

  // Static helper methods for common dialogs
  static void showSuccess({
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? confirmText,
  }) {
    Get.dialog(
      NotificationDialog(
        title: title,
        message: message,
        type: NotificationType.success,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }

  static void showError({
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? confirmText,
  }) {
    Get.dialog(
      NotificationDialog(
        title: title,
        message: message,
        type: NotificationType.error,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }

  static void showWarning({
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String? confirmText,
    String? cancelText,
  }) {
    Get.dialog(
      NotificationDialog(
        title: title,
        message: message,
        type: NotificationType.warning,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  static void showInfo({
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? confirmText,
  }) {
    Get.dialog(
      NotificationDialog(
        title: title,
        message: message,
        type: NotificationType.info,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }

  static void showScanResult({
    required String barcode,
    required bool isSuccess,
    VoidCallback? onContinue,
  }) {
    if (isSuccess) {
      showSuccess(
        title: 'scan_successful'.tr,
        message: 'sample_scanned_success'.trParams({'id': barcode}),
        onConfirm: onContinue,
        confirmText: 'continue_scanning'.tr,
      );
    } else {
      showError(
        title: 'scan_failed'.tr,
        message: 'failed_to_scan_sample_try_again'.tr,
        onConfirm: onContinue,
        confirmText: 'retry'.tr,
      );
    }
  }

  static void showDuplicateScan({
    required String barcode,
    VoidCallback? onContinue,
  }) {
    showWarning(
      title: 'duplicate_scan'.tr,
      message: 'already_scanned'.tr,
      onConfirm: onContinue,
      confirmText: 'continue_scanning'.tr,
    );
  }

  static void showAllSamplesScanned({
    required int totalSamples,
    VoidCallback? onProceed,
    VoidCallback? onContinue,
  }) {
    showSuccess(
      title: 'all_samples_scanned'.tr,
      message: 'all_samples_scanned_count'.trParams({
        'count': totalSamples.toString(),
      }),
      onConfirm: onProceed,
      confirmText: 'proceed'.tr,
    );
  }

  static void showMissingSamples({
    required List<String> missingSamples,
    VoidCallback? onProceed,
    VoidCallback? onContinue,
  }) {
    final missingText = missingSamples.join(', ');
    showWarning(
      title: 'missing_samples'.tr,
      message: 'missing_samples_message'.trParams({'list': missingText}),
      onConfirm: onProceed,
      onCancel: onContinue,
      confirmText: 'proceed_anyway'.tr,
      cancelText: 'continue_scanning'.tr,
    );
  }
}
