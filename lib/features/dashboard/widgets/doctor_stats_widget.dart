import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/themes/app_colors.dart';

class DoctorStatsWidget extends StatelessWidget {
  final int completed;
  final int inProgress;
  final int pending;

  const DoctorStatsWidget({
    super.key,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'doctor_visit_summary'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'completed'.tr,
                  completed.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'in_progress'.tr,
                  inProgress.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'pending'.tr,
                  pending.toString(),
                  Colors.grey,
                  Icons.pending,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),

        SizedBox(height: 8.h),

        Text(
          count,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 2.h),

        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
