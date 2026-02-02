import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/pending_drop_date_controller.dart';
import '../../dashboard/controllers/todays_task_controller.dart';

class PendingDropDateScreen extends GetView<PendingDropDateController> {
  const PendingDropDateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect if device is tablet/iPad
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double appBarHeight = isTablet ? 70.0 : 56.0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Reset to today_task mode when going back
          try {
            final todaysTaskController = Get.find<TodaysTaskController>();
            todaysTaskController.switchToTodayTask();
          } catch (e) {
            // Controller not found, just go back
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: AppBar(
            title: Text('pending_drop_date'.tr),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Reset to today_task mode when going back
                try {
                  final todaysTaskController = Get.find<TodaysTaskController>();
                  todaysTaskController.switchToTodayTask();
                } catch (e) {
                  // Controller not found
                }
                Navigator.pop(context);
              },
              iconSize: isTablet ? 36 : 24,
              padding: isTablet ? const EdgeInsets.all(12) : null,
            ),
            toolbarHeight: appBarHeight,
          ),
        ),
        body: Obx(() {
          // Loading state
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (controller.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'error_loading_dates'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    controller.errorMessage.value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: controller.refreshPendingDates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (controller.pendingDates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'no_pending_dates'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Pending dates list
          return RefreshIndicator(
            onRefresh: controller.refreshPendingDates,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info text
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'select_date_to_continue'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Pending dates list
                  ...List.generate(controller.pendingDates.length, (index) {
                    final date = controller.pendingDates[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: ElevatedButton(
                        onPressed: () => controller.selectDate(date),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: isTablet ? 24.h : 16.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: isTablet ? 28.sp : 20.sp,
                            ),
                            SizedBox(width: 16.w),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: isTablet ? 18.sp : 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward,
                              size: isTablet ? 24.sp : 18.sp,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
