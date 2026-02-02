import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../controllers/instructions_controller.dart';
import 'pdf_viewer_screen.dart';

class InstructionsPopup extends StatelessWidget {
  const InstructionsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InstructionsController());
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context, controller),
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    InstructionsController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20.h),

          // Address info - only show if exists
          if (controller.hasAddressInfo) ...[
            if (controller.streetName.value.isNotEmpty) ...[
              _buildInfoRow(
                icon: Icons.streetview,
                label: 'street_name'.tr,
                value: controller.streetName.value,
              ),
              SizedBox(height: 12.h),
            ],
            if (controller.areaName.value.isNotEmpty) ...[
              _buildInfoRow(
                icon: Icons.location_city,
                label: 'area_name'.tr,
                value: controller.areaName.value,
              ),
              SizedBox(height: 12.h),
            ],
          ],

          // Map location - only show if exists
          if (controller.hasMapLocation) ...[
            _buildClickableInfoRow(
              icon: Icons.location_on,
              label: 'location'.tr,
              value: 'open_in_maps'.tr,
              onTap: () => _openMap(controller.locationUrl.value),
            ),
            SizedBox(height: 20.h),
          ],

          // Details section - always show the section
          _buildDetailsSection(controller),
          SizedBox(height: 20.h),

          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'instructions'.tr,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Icon(Icons.close, color: AppColors.textSecondary, size: 28.w),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24.w),
        SizedBox(width: 12.w),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24.w),
            SizedBox(width: 12.w),
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 16.sp, color: AppColors.info),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.info, size: 16.w),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(InstructionsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show PDF button if PDF exists
        if (controller.hasPdf) ...[
          _buildClickableInfoRow(
            icon: Icons.picture_as_pdf,
            label: 'pdf_file'.tr,
            value: 'view_pdf'.tr,
            onTap: () => _openPdf(controller.pdfLink.value),
          ),
          SizedBox(height: 16.h),
        ],

        // Description label always shown
        Text(
          'description'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),

        // Show description content only if exists
        if (controller.hasDescription)
          Text(
            controller.detailsText.value,
            style: TextStyle(
              fontSize: 15.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
        ),
        child: Text(
          'close'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _openMap(String locationUrl) async {
    try {
      final Uri url = Uri.parse(locationUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        SnackbarUtils.showError(
          title: 'error'.tr,
          message: 'could_not_open_map'.tr,
        );
      }
    } catch (e) {
      SnackbarUtils.showError(
        title: 'error'.tr,
        message: 'error_opening_map'.trParams({'error': e.toString()}),
      );
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    try {
      // Navigate to PDF viewer screen
      Get.to(() => const PdfViewerScreen(), arguments: pdfUrl);
    } catch (e) {
      SnackbarUtils.showError(
        title: 'error'.tr,
        message: 'error_opening_pdf'.trParams({'error': e.toString()}),
      );
    }
  }
}
