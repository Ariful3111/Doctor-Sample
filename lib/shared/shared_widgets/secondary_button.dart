import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/themes/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Widget? icon;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled = isEnabled && !isLoading && onPressed != null;
    final Color effectiveBorderColor = isButtonEnabled
        ? (borderColor ?? AppColors.primary)
        : AppColors.textSecondary.withValues(alpha: 0.3);
    final Color effectiveTextColor = isButtonEnabled
        ? (textColor ?? AppColors.primary)
        : AppColors.textSecondary;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: OutlinedButton(
        onPressed: isButtonEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: effectiveBorderColor, width: borderWidth),
          foregroundColor: effectiveTextColor,
          padding: padding ?? EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  SizedBox(width: 8.w),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
