import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../dashboard/controllers/notifications_controller.dart';
import '../controllers/pickup_confirmation_controller.dart';
import '../widgets/pickup_doctor_info_widget.dart';
import '../widgets/pickup_samples_summary_widget.dart';
import '../widgets/pickup_samples_list_widget.dart';
import '../widgets/pickup_confirmation_buttons_widget.dart';

class PickupConfirmationScreen extends GetView<PickupConfirmationController> {
  const PickupConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('pickup_confirmation'.tr),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        toolbarHeight: 56.0,
        centerTitle: true,
        actions: [
          GetX<NotificationsController>(
            init: Get.find<NotificationsController>(),
            builder: (controller) {
              final pendingCount = controller.pendingPickups.length;
              final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.notifications);
                    },
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textOnPrimary,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: isTablet ? 8 : 6,
                      top: isTablet ? 8 : 6,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 3 : 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: isTablet ? 16 : 14,
                          minHeight: isTablet ? 16 : 14,
                        ),
                        child: Center(
                          child: Text(
                            pendingCount > 9 ? '9+' : pendingCount.toString(),
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: isTablet ? 9 : 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Information Card
            const PickupDoctorInfoWidget(),
            SizedBox(height: 16.h),

            // Scanned Samples Summary
            const PickupSamplesSummaryWidget(),
            SizedBox(height: 16.h),

            // Samples List
            const Expanded(child: PickupSamplesListWidget()),

            // Confirmation Buttons
            const PickupConfirmationButtonsWidget(),
          ],
        ),
      ),
    );
  }
}
