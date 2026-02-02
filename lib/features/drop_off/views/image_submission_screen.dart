import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/image_submission_controller.dart';
import '../widgets/image_submission_header_widget.dart';
import '../widgets/image_preview_widget.dart';
import '../widgets/image_selection_buttons_widget.dart';
import '../widgets/image_submission_action_buttons_widget.dart';

class ImageSubmissionScreen extends GetView<ImageSubmissionController> {
  const ImageSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('submit'.tr),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const ImageSubmissionHeaderWidget(),

              SizedBox(height: 32.h),

              // Image Preview Section
              const ImagePreviewWidget(),

              SizedBox(height: 32.h),

              // Image Selection Buttons
              const ImageSelectionButtonsWidget(),

              const Spacer(),

              // Action Buttons
              const ImageSubmissionActionButtonsWidget(),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
