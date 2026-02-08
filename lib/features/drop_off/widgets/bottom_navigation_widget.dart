import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/drop_location_controller.dart';
import '../../dashboard/controllers/todays_task_controller.dart';

class BottomNavigationWidget extends GetView<DropLocationController> {
  final bool isTablet;
  const BottomNavigationWidget({super.key, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.blue,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Back Button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    // Reset to today_task mode when going back
                    try {
                      final todaysTaskController =
                          Get.find<TodaysTaskController>();
                      todaysTaskController.switchToTodayTask();
                    } catch (e) {
                      // Controller not found
                    }
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: isTablet
                        ? EdgeInsets.symmetric(vertical: 22.h)
                        : EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: isTablet ? 28.sp : 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'back'.tr,
                        style: TextStyle(fontSize: isTablet ? 18.sp : 14.sp,color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // Confirm Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: controller.isLocationValid.value
                      ? controller.confirmDropLocation
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isLocationValid.value
                        ? Colors.green
                        : AppColors.textHint,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: isTablet
                        ? EdgeInsets.symmetric(vertical: 22.h)
                        : EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: controller.isLocationValid.value ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isLocationValid.value
                            ? Icons.check_circle
                            : Icons.location_off,
                        size: isTablet ? 28.sp : 18.sp,color: Colors.white,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        controller.isLocationValid.value
                            ? 'confirm'.tr
                            : 'scan_location_first'.tr,
                        style: TextStyle(
                          fontSize: isTablet ? 18.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
