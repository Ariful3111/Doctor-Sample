import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';

class AppLogoSection extends StatelessWidget {
  const AppLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Logo
        Image.asset('assets/icons/app_logo.png', height: 100, width: 100.w),

        SizedBox(height: 20.h),

        // App Title
        Text(
          'app_title'.tr,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 8.h),

        // App Subtitle
        Text(
          'welcome_back_message'.tr,
          style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
