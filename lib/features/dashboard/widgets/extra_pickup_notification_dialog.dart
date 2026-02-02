import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../repositories/extra_pickup_repository.dart';
import '../controllers/todays_task_controller.dart';
import '../controllers/notifications_controller.dart';

/// Dialog for displaying extra pickup notification
/// Shows doctor details, sample count, and Accept/Reject buttons
class ExtraPickupNotificationDialog extends StatefulWidget {
  final Map<dynamic, dynamic> pickupData;

  const ExtraPickupNotificationDialog({super.key, required this.pickupData});

  @override
  State<ExtraPickupNotificationDialog> createState() =>
      _ExtraPickupNotificationDialogState();
}

class _ExtraPickupNotificationDialogState
    extends State<ExtraPickupNotificationDialog> {
  final ExtraPickupRepository _repository = ExtraPickupRepository();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    final pickup = widget.pickupData['pickup'] ?? {};
    final message = widget.pickupData['message'] ?? 'New pickup request';
    final pickupId = pickup['id'] ?? 0;
    final tour = pickup['tour'] ?? {};
    final doctors = pickup['doctors'] ?? [];
    final date = pickup['date'] ?? '';
    final expiresAt = widget.pickupData['expiresAt'];

    return PopScope(
      canPop: !_isProcessing,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: AppColors.primary,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'quick_delivery'.tr,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),

              // Tour Info
              if (tour.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.route,
                  label: 'tour'.tr,
                  value: tour['name'] ?? 'N/A',
                ),
                SizedBox(height: 8.h),
              ],

              // Date
              if (date.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'date'.tr,
                  value: date,
                ),
                SizedBox(height: 8.h),
              ],

              // Doctors list
              if (doctors.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.local_hospital,
                  label: 'doctors'.tr,
                  value:
                      '${doctors.length} ${doctors.length > 1 ? "doctors" : "doctor"}',
                ),
                SizedBox(height: 12.h),

                // Doctor details
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: doctors.map<Widget>((doctor) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                doctor['name'] ?? 'Unknown Doctor',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Expiry time if available
              if (expiresAt != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.sp,
                        color: Colors.orange.shade700,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'respond_before'.tr + ': $expiresAt',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange.shade700,
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
        actions: [
          // Reject Button
          TextButton(
            onPressed: _isProcessing ? null : () => _handleReject(pickupId),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: _isProcessing
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : Text(
                    'reject'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          // Accept Button
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _handleAccept(pickupId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'accept'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept(int pickupId) async {
    if (pickupId == 0) {
      SnackbarUtils.showError(title: 'error'.tr, message: 'Invalid pickup ID');
      return;
    }

    setState(() => _isProcessing = true);

    final result = await _repository.acceptExtraPickup(id: pickupId);

    setState(() => _isProcessing = false);

    result.fold(
      (error) {
        SnackbarUtils.showError(title: 'error'.tr, message: error);
      },
      (data) {
        SnackbarUtils.showSuccess(
          title: 'success'.tr,
          message: 'extra_pickup_accepted'.tr,
        );
        Get.back(); // Close dialog

        // Refresh dashboard/tour list
        try {
          if (Get.isRegistered<TodaysTaskController>()) {
            Get.find<TodaysTaskController>().loadTodaysTasks();
            print('🔄 Dashboard refreshed after accepting pickup');
          }
          if (Get.isRegistered<NotificationsController>()) {
            Get.find<NotificationsController>().fetchPendingPickups();
            print('🔄 Notifications refreshed after accepting pickup');
          }
        } catch (e) {
          print('⚠️ Error refreshing after accept: $e');
        }
      },
    );
  }

  Future<void> _handleReject(int pickupId) async {
    if (pickupId == 0) {
      SnackbarUtils.showError(title: 'error'.tr, message: 'Invalid pickup ID');
      return;
    }

    setState(() => _isProcessing = true);

    final result = await _repository.rejectExtraPickup(id: pickupId);

    setState(() => _isProcessing = false);

    result.fold(
      (error) {
        SnackbarUtils.showError(title: 'error'.tr, message: error);
      },
      (data) {
        SnackbarUtils.showInfo(
          title: 'rejected'.tr,
          message: 'extra_pickup_rejected'.tr,
        );
        Get.back(); // Close dialog

        // Refresh notifications list
        try {
          if (Get.isRegistered<NotificationsController>()) {
            Get.find<NotificationsController>().fetchPendingPickups();
            print('🔄 Notifications refreshed after rejecting pickup');
          }
        } catch (e) {
          print('⚠️ Error refreshing after reject: $e');
        }
      },
    );
  }
}
