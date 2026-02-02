import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../shared/shared_widgets/shared_widgets.dart';
import 'notification_icon_widget.dart';

class NotificationButtonsWidget extends StatelessWidget {
  final NotificationType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmText;
  final String? cancelText;

  const NotificationButtonsWidget({
    super.key,
    required this.type,
    this.onConfirm,
    this.onCancel,
    this.confirmText,
    this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    if (onConfirm == null && onCancel == null) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          text: confirmText ?? 'confirm'.tr,
          onPressed: () => Get.back(),
        ),
      );
    }

    if (onCancel == null) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          text: confirmText ?? 'confirm'.tr,
          onPressed: onConfirm ?? () => Get.back(),
          backgroundColor: _getConfirmButtonColor(),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: cancelText ?? 'cancel'.tr,
            onPressed: onCancel ?? () => Get.back(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: PrimaryButton(
            text: confirmText ?? 'confirm'.tr,
            onPressed: onConfirm ?? () => Get.back(),
            backgroundColor: _getConfirmButtonColor(),
          ),
        ),
      ],
    );
  }

  Color _getConfirmButtonColor() {
    switch (type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.info:
        return AppColors.primary;
    }
  }
}
