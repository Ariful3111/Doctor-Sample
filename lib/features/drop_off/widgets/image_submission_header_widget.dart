import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';

class ImageSubmissionHeaderWidget extends StatelessWidget {
  const ImageSubmissionHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'submit_proof_image'.tr,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          'image_proof_header'.tr,
          style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
