import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/themes/app_colors.dart';

/// Exit Tour Warning Dialog with 2 scenarios:
/// 1. No samples submitted → Simple exit (no tour end API)
/// 2. Samples submitted → Show progress, end tour on exit (with API call)
class ExitTourWarningDialog extends StatelessWidget {
  final int totalDoctors;
  final int completedDoctors;
  final int visitedDoctors;
  final int samplesSubmitted;
  final VoidCallback onConfirm; // For when work was done (tour end needed)
  final VoidCallback onSilentExit; // For when no work was done (just exit)

  const ExitTourWarningDialog({
    super.key,
    required this.totalDoctors,
    required this.completedDoctors,
    required this.visitedDoctors,
    required this.samplesSubmitted,
    required this.onConfirm,
    required this.onSilentExit,
  });

  @override
  Widget build(BuildContext context) {
    // Scenario 1: No samples submitted (no work OR just entered)
    // → Just exit screen, don't end tour officially
    if (samplesSubmitted == 0) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Exit Tour?',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit? No work has been saved yet.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              onSilentExit(); // Then execute callback
            },
            child: Text(
              'Exit',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    // Scenario 2: Samples already submitted - show progress summary
    final pendingScans = totalDoctors - samplesSubmitted;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        'Exit Tour?',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your progress will be saved as a pending tour.',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Completed: $samplesSubmitted',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Pending: $pendingScans',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Continue', style: TextStyle(color: AppColors.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog first
            onConfirm(); // Then execute callback
          },
          child: Text(
            'Exit',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
