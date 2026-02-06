import 'package:doctor_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/services/tour_state_service.dart';
import '../../dashboard/controllers/todays_task_controller.dart';
import '../controllers/drop_location_controller.dart';

class ScanQRButtonWidget extends GetView<DropLocationController> {
  const ScanQRButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Icon
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .3),
                  width: 2.w,
                ),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 60.sp,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 24.h),

            // Title
            Text(
              'scan_drop_point_qr_code'.tr,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8.h),

            // Subtitle (Excel may not include this; using scan label as placeholder)
            Text(
              'bar_code_scan'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            // Scan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isScanning.value
                    ? null
                    : controller.startQRScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                child: controller.isScanning.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'bar_code_scan'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'bar_code_scan'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 16.h),

            // Report Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  String? tourId = controller.tourId;
                  if (tourId.isEmpty) {
                    if (Get.isRegistered<TourStateService>()) {
                      tourId = Get.find<TourStateService>().currentTourId ?? '';
                    }
                  }

                  var isExtraPickup = false;
                  if (tourId.isNotEmpty &&
                      Get.isRegistered<TodaysTaskController>()) {
                    final todaysTaskController = Get.find<TodaysTaskController>();
                    final tours =
                        todaysTaskController.todaySchedule.value?.data?.tours ??
                        [];
                    final tour =
                        tours.firstWhereOrNull((t) => t.id?.toString() == tourId);
                    isExtraPickup =
                        tour?.allDoctors.any((d) => d.isExtraPickup) ?? false;
                  }

                  Get.toNamed(
                    AppRoutes.report,
                    arguments: {'isDropPoint': true, 'isExtraPickup': isExtraPickup},
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.surface, width: 1.5.w),
                  backgroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.report_outlined,
                      size: 20.sp,
                      color: AppColors.surface,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'report'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Location Status
            if (controller.isLocationValid.value) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.withValues(alpha: .3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'location_verified_with_name'.trParams({
                          'name': controller.dropLocationName.value,
                        }),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
