import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../widgets/app_logo_section.dart';
import '../widgets/login_form_widget.dart';
import '../widgets/login_button_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),

              // App Logo Section
              const AppLogoSection(),

              SizedBox(height: 60.h),

              // Login Form
              const LoginFormWidget(),

              SizedBox(height: 32.h),

              // Login Button
              const LoginButtonWidget(),

              SizedBox(height: 24.h),

              // Forgot Password
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password functionality
                },
                child: Text(
                  'forgot_password_question'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
