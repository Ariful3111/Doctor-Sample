import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/location_code_controller.dart';

class LocationCodeScreen extends GetView<LocationCodeController> {
  const LocationCodeScreen({super.key});

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
          title: Text('location_code'.tr),
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
              // Title
              Text(
                'enter_location_code'.tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 8.h),

              // Subtitle/Instructions
              Text(
                'enter_code_to_confirm_drop_location'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 24.h),

              // Location Code Input Field
              TextField(
                controller: controller.locationCodeController,
                decoration: InputDecoration(
                  labelText: 'location_code'.tr,
                  hintText: 'location_code_hint_example'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.pin_drop, color: AppColors.primary),
                ),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
              ),

              SizedBox(height: 8.h),

              // Error message
              Obx(
                () => controller.errorMessage$.value.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(left: 12.w, top: 4.h),
                        child: Text(
                          controller.errorMessage$.value,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const Spacer(),

              // Next Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: controller.isLocationCodeValid$.value
                        ? controller.onNextPressed
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.textSecondary
                          .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'next'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: controller.isLocationCodeValid$.value
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // Report Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton(
                  onPressed: controller.onReportPressed,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'report'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
