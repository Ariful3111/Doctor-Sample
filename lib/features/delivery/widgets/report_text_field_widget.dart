import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/report_controller.dart';

class ReportTextFieldWidget extends StatelessWidget {
  const ReportTextFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();
    return Obx(
      () => TextFormField(
        controller: TextEditingController(text: controller.reportText.value),
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Enter report details...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
