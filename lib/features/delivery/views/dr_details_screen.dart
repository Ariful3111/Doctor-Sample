import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../dashboard/controllers/notifications_controller.dart';
import '../controllers/dr_details_controller.dart';
import '../widgets/doctor_info_header_widget.dart';

class DrDetailsScreen extends StatelessWidget {
  const DrDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DrDetailsController>();
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          toolbarHeight: 56.0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.0),
            onPressed: controller.goBack,
          ),
          title: Text(
            controller.doctorName.value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 14.sp : 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            GetX<NotificationsController>(
              init: Get.find<NotificationsController>(),
              builder: (controller) {
                final pendingCount = controller.pendingPickups.length;
                final isTablet =
                    MediaQuery.of(context).size.shortestSide >= 600;
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
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [DoctorInfoHeaderWidget()],
        ),
      ),
    );
  }
}
