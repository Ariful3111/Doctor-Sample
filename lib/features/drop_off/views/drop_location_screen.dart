import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/drop_location_controller.dart';
import '../../dashboard/controllers/todays_task_controller.dart';
import '../widgets/scan_qr_button_widget.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/drop_location_header_widget.dart';
import '../widgets/drop_location_instructions_widget.dart';

class DropLocationScreen extends GetView<DropLocationController> {
  const DropLocationScreen({super.key});

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
            title: Text('drop_point'.tr),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            toolbarHeight: appBarHeight,
            automaticallyImplyLeading: false,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DropLocationHeaderWidget(),
                    SizedBox(height: 32.h),
                    const ScanQRButtonWidget(),
                    SizedBox(height: 32.h),
                    const DropLocationInstructionsWidget(),
                  ],
                ),
              ),
            ),
            // Pass isTablet to BottomNavigationWidget
            BottomNavigationWidget(isTablet: isTablet),
          ],
        ),
      ),
    );
  }
}
