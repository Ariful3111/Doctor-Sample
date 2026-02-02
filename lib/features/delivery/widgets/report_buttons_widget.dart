import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/report_controller.dart';

class ReportButtonsWidget extends StatelessWidget {
  const ReportButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();
    return Column(
      children: [
        ReportButton(
          text: 'without_bar_code'.tr,
          icon: Icons.barcode_reader,
          color: AppColors.warning,
          onTap: () => controller.toggleReportText('without_bar_code'.tr),
        ),
        SizedBox(height: 16.h),
        ReportButton(
          text: 'door_close'.tr,
          icon: Icons.qr_code,
          color: AppColors.info,
          onTap: () => controller.toggleReportText('door_close'.tr),
        ),
        SizedBox(height: 16.h),
        ReportButton(
          text: 'no_sample'.tr,
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          onTap: () => controller.toggleReportText('no_sample'.tr),
        ),
      ],
    );
  }
}

class ReportButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ReportButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();
    return Obx(() {
      final isSelected = controller.reportText.value.contains(text);
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.2),
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
              Icon(icon, color: isSelected ? Colors.white : color, size: 24.w),
              SizedBox(width: 12.w),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
