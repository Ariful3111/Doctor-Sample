import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/dr_details_controller.dart';

class DoctorInfoHeaderWidget extends StatelessWidget {
  const DoctorInfoHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DrDetailsController>();

    return Obx(() {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Doctor Avatar and Basic Info
            Row(
              children: [
                // Doctor Avatar
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.w),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      controller.doctorImage.value,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: 40.w,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(width: 16.w),
                Text(
                  controller.doctorName.value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildPrimaryButton(
              icon: Icons.barcode_reader,
              label: 'bar_code_scan'.tr,
              color: AppColors.success,
              onTap: controller.startVisit,
            ),
            SizedBox(height: 20.h),
            _buildPrimaryButton(
              icon: Icons.report,
              label: 'report'.tr,
              color: AppColors.error,
              onTap: () => Get.toNamed(
                AppRoutes.report,
                arguments: {
                  'doctorId': controller.doctorId.value,
                  'doctorName': controller.doctorName.value,
                  'appointmentId': controller.appointmentId.value,
                  'tourId': controller.tourId.value, // Pass tourId
                  'isExtraPickup':
                      controller.isExtraPickup, // Pass extra pickup flag
                  'extraPickupId':
                      controller.extraPickupId, // Pass extra pickup ID
                },
              ),
            ),
            // Always show instruction button - popup handles empty state
            SizedBox(height: 20.h),
            _buildPrimaryButton(
              icon: Icons.integration_instructions,
              label: 'instructions'.tr,
              color: AppColors.info,
              onTap: controller.showInstructions,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24.w),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
