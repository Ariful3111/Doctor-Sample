import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/local/storage_service.dart';

class DateHeaderWidget extends StatefulWidget {
  const DateHeaderWidget({super.key});

  @override
  State<DateHeaderWidget> createState() => _DateHeaderWidgetState();
}

class _DateHeaderWidgetState extends State<DateHeaderWidget> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() {
    try {
      final storage = Get.find<StorageService>();
      print('📦 Attempting to load username from storage...');

      final username = storage.read<String>(key: 'username');
      print('🔍 Raw storage read result: $username');
      print('🔍 Type: ${username.runtimeType}');
      print('🔍 Is null: ${username == null}');
      print('🔍 Is empty string: ${username?.isEmpty}');

      setState(() {
        _username = username;
      });
      print('✅ Username loaded: $username');
    } catch (e) {
      print('❌ Error loading username: $e');
    }
  }

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
          SizedBox(height: 4.h),
          // Driver info with username from API
          Row(
            children: [
              Icon(Icons.person_outline, size: 24.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                _username ?? 'Driver',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _formatDate(DateTime.now()),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final monthName = _getMonthName(date.month);
    return '${date.day} $monthName, ${date.year}';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'month_january'.tr;
      case 2:
        return 'month_february'.tr;
      case 3:
        return 'month_march'.tr;
      case 4:
        return 'month_april'.tr;
      case 5:
        return 'month_may'.tr;
      case 6:
        return 'month_june'.tr;
      case 7:
        return 'month_july'.tr;
      case 8:
        return 'month_august'.tr;
      case 9:
        return 'month_september'.tr;
      case 10:
        return 'month_october'.tr;
      case 11:
        return 'month_november'.tr;
      case 12:
        return 'month_december'.tr;
      default:
        return 'month_january'.tr;
    }
  }
}
