import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/themes/app_colors.dart';

enum InfoCardType { info, success, warning, error }

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? child;
  final InfoCardType type;
  final Widget? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final bool showBorder;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.type = InfoCardType.info,
    this.icon,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType(type);

    return Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: 8.h),
      child: Material(
        color: colors['background'],
        borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          child: Container(
            padding: padding ?? EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
              border: showBorder
                  ? Border.all(color: colors['border']!, width: 1.w)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[icon!, SizedBox(width: 12.w)],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colors['text'],
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: colors['text']!.withValues(alpha: 0.6),
                      ),
                  ],
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colors['text']!.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
                if (child != null) ...[SizedBox(height: 12.h), child!],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getColorsForType(InfoCardType type) {
    switch (type) {
      case InfoCardType.success:
        return {
          'background': AppColors.success.withValues(alpha: 0.1),
          'border': AppColors.success.withValues(alpha: 0.3),
          'text': AppColors.success,
        };
      case InfoCardType.warning:
        return {
          'background': AppColors.warning.withValues(alpha: 0.1),
          'border': AppColors.warning.withValues(alpha: 0.3),
          'text': AppColors.warning,
        };
      case InfoCardType.error:
        return {
          'background': AppColors.error.withValues(alpha: 0.1),
          'border': AppColors.error.withValues(alpha: 0.3),
          'text': AppColors.error,
        };
      case InfoCardType.info:
        return {
          'background': AppColors.surface,
          'border': AppColors.border,
          'text': AppColors.textPrimary,
        };
    }
  }
}
