import 'package:doctor_app/core/constants/network_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../controllers/notifications_controller.dart';

typedef VoidCallback = void Function();

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NotificationsController>();
    // Auto-refresh when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔔 [Screen] initState - triggering auto-refresh');
      controller.fetchPendingPickups();
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔔 [Screen] App resumed - refreshing notifications');
      controller.fetchPendingPickups();
    }
  }

  @override
  void dispose() {
    print('🔔 [Screen] NotificationsScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect if device is tablet/iPad
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double appBarHeight = isTablet ? 64.0 : 56.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          toolbarHeight: appBarHeight,
          title: Text(
            'notifications'.tr,
            style: TextStyle(
              fontSize: isTablet ? 22.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.textOnPrimary,
              size: isTablet ? 28 : 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: isTablet ? const EdgeInsets.all(12) : null,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.pendingPickups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 80.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  'no_pending_notifications'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchPendingPickups,
          color: AppColors.primary,
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.pendingPickups.length,
            itemBuilder: (context, index) {
              final pickup = controller.pendingPickups[index];
              return _buildNotificationCard(pickup, index);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> pickup, int index) {
    final pickupId = pickup['id'] ?? 0;
    final tour = pickup['tour'] ?? {};
    final doctors = pickup['doctors'] ?? [];
    final date = pickup['date'] ?? '';
    final createdAt = pickup['createdAt'] ?? '';
    final expiresAt = pickup['expiresAt'];

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quick_delivery_request'.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (createdAt.isNotEmpty)
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (expiresAt != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 14.sp, color: Colors.orange),
                        SizedBox(width: 4.w),
                        Text(
                          _formatExpiry(expiresAt),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

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

            // Doctors
            if (doctors.isNotEmpty) ...[
              _buildInfoRow(
                icon: Icons.person,
                label: 'doctors'.tr,
                value: '${doctors.length} ${'doctor'.tr}(s)',
              ),
              SizedBox(height: 4.h),
              ...doctors.map(
                (doctor) => GestureDetector(
                  onTap: () {
                    // Open doctor details popup when tapped
                    _showDoctorDetailsPopup(doctor);
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 32.w, bottom: 8.h),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            doctor['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12.sp,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // Action Buttons
            Obx(() {
              final isAccepting = controller.acceptingIds.contains(pickupId);
              final isRejecting = controller.rejectingIds.contains(pickupId);
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isRejecting
                          ? null
                          : () => controller.rejectPickup(pickupId, index),
                      icon: isRejecting
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.close, size: 18.sp),
                      label: Text(
                        'reject'.tr,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isAccepting
                          ? null
                          : () => controller.acceptPickup(pickupId, index),
                      icon: isAccepting
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.check, size: 18.sp),
                      label: Text(
                        'accept'.tr,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'just_now'.tr;
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} ${'minutes_ago'.tr}';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} ${'hours_ago'.tr}';
      } else {
        return '${difference.inDays} ${'days_ago'.tr}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatExpiry(String? expiresAt) {
    if (expiresAt == null) return '';

    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final difference = expiry.difference(now);

      if (difference.isNegative) {
        return 'expired'.tr;
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else {
        return '${difference.inHours}h';
      }
    } catch (e) {
      return '';
    }
  }

  /// Show doctor details popup when doctor card is tapped
  void _showDoctorDetailsPopup(Map<String, dynamic> doctor) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primary, size: 28.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        doctor['name'] ?? 'Unknown Doctor',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () {
                        final navigator = Get.key.currentState;
                        if (navigator != null && navigator.canPop()) {
                          navigator.pop();
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24.w),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                SizedBox(height: 12.h),
                // Doctor Info
                if ((doctor['street'] ?? '').toString().isNotEmpty)
                  _buildDoctorInfoRow(
                    Icons.location_on,
                    'street'.tr,
                    doctor['street'] ?? '',
                  ),
                if ((doctor['area'] ?? '').toString().isNotEmpty)
                  _buildDoctorInfoRow(
                    Icons.map,
                    'area'.tr,
                    doctor['area'] ?? '',
                  ),
                if ((doctor['phone'] ?? '').toString().isNotEmpty)
                  _buildDoctorInfoRow(
                    Icons.phone,
                    'phone'.tr,
                    doctor['phone'] ?? '',
                  ),
                if ((doctor['zip'] ?? '').toString().isNotEmpty)
                  _buildDoctorInfoRow(
                    Icons.pin_drop,
                    'zip'.tr,
                    doctor['zip'] ?? '',
                  ),
                // Description
                if ((doctor['description'] ?? '').toString().isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'description'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    doctor['description'] ?? '',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
                // Instructions button
                if ((doctor['pdfFile'] ?? '').toString().isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        var pdfFile = (doctor['pdfFile'] ?? '').toString();
                        if (pdfFile.isNotEmpty) {
                          // Clean PDF URL if it has duplicate prefix
                          pdfFile = _cleanPdfUrl(pdfFile);
                          // Open PDF in browser or PDF viewer
                          try {
                            if (await canLaunchUrl(Uri.parse(pdfFile))) {
                              await launchUrl(
                                Uri.parse(pdfFile),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              SnackbarUtils.showError(
                                title: 'error'.tr,
                                message: 'cannot_open_pdf'.tr,
                              );
                            }
                          } catch (e) {
                            SnackbarUtils.showError(
                              title: 'error'.tr,
                              message: 'failed_to_open_pdf'.tr,
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.file_download, size: 18.sp),
                      label: Text(
                        'instructions'.tr,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Build doctor info row in popup
  Widget _buildDoctorInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clean PDF URL if it has duplicate base URL prefix
  String _cleanPdfUrl(String pdfUrl) {
    if (pdfUrl.isEmpty) return pdfUrl;

    // Check if URL has duplicate /uploads/ prefix
    final uploadsPattern = RegExp(r'uploads/.*uploads/');
    if (uploadsPattern.hasMatch(pdfUrl)) {
      // Extract just the filename and remove duplicates
      final match = RegExp(r'uploads/([^/]*\.\w+)$').firstMatch(pdfUrl);
      if (match != null) {
        final filename = match.group(1);
        return '${NetworkPaths.baseUrl}/uploads/$filename';
      }
    }

    return pdfUrl;
  }
}
