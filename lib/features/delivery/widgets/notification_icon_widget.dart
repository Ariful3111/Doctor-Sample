import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/themes/app_colors.dart';

enum NotificationType { success, error, warning, info }

class NotificationIconWidget extends StatelessWidget {
  final NotificationType type;
  final Widget? customIcon;

  const NotificationIconWidget({
    super.key,
    required this.type,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (customIcon != null) {
      return customIcon!;
    }

    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle;
        iconColor = AppColors.success;
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        break;
      case NotificationType.error:
        iconData = Icons.error;
        iconColor = AppColors.error;
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        break;
      case NotificationType.warning:
        iconData = Icons.warning;
        iconColor = AppColors.warning;
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case NotificationType.info:
        iconData = Icons.info;
        iconColor = AppColors.info;
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        break;
    }

    return Container(
      width: 64.w,
      height: 64.w,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(iconData, size: 32.w, color: iconColor),
    );
  }
}
