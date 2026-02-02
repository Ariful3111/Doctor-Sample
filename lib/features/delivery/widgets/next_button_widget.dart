import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/report_controller.dart';

class NextButtonWidget extends StatelessWidget {
  const NextButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.goToNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          'next'.tr,
          style: TextStyle(fontSize: 16.sp, color: Colors.white),
        ),
      ),
    );
  }
}
