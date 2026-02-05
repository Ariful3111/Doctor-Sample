import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/image_submission_controller.dart';

class ImageSelectionButtonsWidget extends GetView<ImageSubmissionController> {
  const ImageSelectionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton.icon(
        onPressed: () => controller.selectImage(context),
        icon: Icon(Icons.camera_alt, color: AppColors.textOnPrimary),
        label: Text(
          'take_photo'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
