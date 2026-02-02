import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/image_submission_controller.dart';

class ImagePreviewWidget extends GetView<ImageSubmissionController> {
  const ImagePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Section Title
        Text(
          'submit_proof_image'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 16.h),

        // Image Preview and Selection
        Obx(
          () => Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: AppColors.surface,
            ),
            child: controller.selectedImagePath$.value.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64.sp,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        controller.selectedImagePath$.value.isEmpty
                            ? 'no_image_selected'.tr
                            : 'image_selected'.trParams({
                                'file': controller.selectedImagePath$.value
                                    .split('/')
                                    .last,
                              }),
                        style: TextStyle(
                          fontSize: 14,
                          color: controller.selectedImagePath$.value.isEmpty
                              ? Colors.grey[600]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: _buildImage(controller.selectedImagePath$.value),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imagePath) {
    // Check if the path is from the device (file path) or asset
    final isFilePath =
        imagePath.startsWith('/') ||
        imagePath.contains(':') ||
        File(imagePath).existsSync();

    if (isFilePath) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 64.sp,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        SizedBox(height: 16.h),
        Text(
          'image_preview_not_available'.tr,
          style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
