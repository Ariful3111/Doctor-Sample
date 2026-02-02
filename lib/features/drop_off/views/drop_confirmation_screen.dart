import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/drop_confirmation_controller.dart';
import '../widgets/drop_confirmation_status_widget.dart';
import '../widgets/drop_confirmation_action_buttons_widget.dart';

class DropConfirmationScreen extends GetView<DropConfirmationController> {
  const DropConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.onBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('confirm'.tr),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.onBackPressed,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Status message area
                Expanded(child: Center(child: DropConfirmationStatusWidget())),

                // Action buttons
                DropConfirmationActionButtonsWidget(),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
