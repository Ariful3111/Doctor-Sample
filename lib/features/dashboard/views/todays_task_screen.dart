import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/themes/app_colors.dart';
import '../controllers/todays_task_controller.dart';
import '../widgets/custom_app_bar_widget.dart';
import '../widgets/date_header_widget.dart';
import '../widgets/task_card_widget.dart';

class TodaysTaskScreen extends StatefulWidget {
  const TodaysTaskScreen({super.key});

  @override
  State<TodaysTaskScreen> createState() => _TodaysTaskScreenState();
}

class _TodaysTaskScreenState extends State<TodaysTaskScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh tasks when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<TodaysTaskController>();
      controller.refreshTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TodaysTaskController controller = Get.find<TodaysTaskController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBarWidget(),
      floatingActionButton: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Today's Task Button
            FloatingActionButton.extended(
              onPressed: controller.currentScreenMode == 'today_task'
                  ? null
                  : controller.switchToTodayTask,
              backgroundColor: controller.currentScreenMode == 'today_task'
                  ? AppColors.primary
                  : AppColors.surface,
              foregroundColor: controller.currentScreenMode == 'today_task'
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
              icon: Icon(Icons.assignment, size: 20.sp),
              label: Text(
                'todo'.tr,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              heroTag: "todayTask",
            ),

            SizedBox(width: 16.w),

            // Drop Location Button
            FloatingActionButton.extended(
              onPressed: controller.currentScreenMode == 'drop_location'
                  ? null
                  : controller.switchToDropLocation,
              backgroundColor: controller.currentScreenMode == 'drop_location'
                  ? AppColors.primary
                  : AppColors.surface,
              foregroundColor: controller.currentScreenMode == 'drop_location'
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
              icon: Icon(Icons.location_on, size: 20.sp),
              label: Text(
                'drop_point'.tr,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              heroTag: "dropLocation",
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                const DateHeaderWidget(),
                SizedBox(height: 20.h),
                // Tasks List
                Obx(() {
                  final scheduleModel = controller.todaySchedule.value;
                  print(
                    '🔍 [TodaysTask] scheduleModel == null: ${scheduleModel == null}',
                  );
                  print(
                    '🔍 [TodaysTask] scheduleModel.data == null: ${scheduleModel?.data == null}',
                  );
                  print(
                    '🔍 [TodaysTask] tours count: ${scheduleModel?.data?.tours?.length ?? 0}',
                  );
                  print(
                    '🔍 [TodaysTask] appointments count: ${scheduleModel?.data?.appointments?.length ?? 0}',
                  );

                  // Get all tours and filter out completed ones
                  final allTours = scheduleModel?.data?.tours ?? [];
                  final appointments = scheduleModel?.data?.appointments ?? [];

                  // Filter out completed appointments and tours with all doctors completed
                  final activeTours = allTours.where((tour) {
                    final appointment = appointments.firstWhereOrNull(
                      (apt) => apt.tour?.id == tour.id,
                    );
                    if (appointment?.status?.toLowerCase() == 'completed') {
                      return false;
                    }
                    return true;
                  }).toList();

                  final tours = activeTours;

                  if (tours.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          SizedBox(height: 40.h),
                          Icon(
                            Icons.assignment_outlined,
                            size: 64.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'there_is_no_work_today'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tours.length,
                    itemBuilder: (context, index) {
                      final currentTime = DateTime.now();
                      final tour = tours[index];
                      final task = {
                        'id': tour.id?.toString() ?? '',
                        'tourName': tour.name ?? '',
                        'doctorCount': tour.allDoctors.length,
                        'completedCount': 0,
                        'status': 'Pending',
                        'startTime': currentTime,
                        'estimatedEnd': currentTime,
                      };
                      return TaskCardWidget(task: task, controller: controller);
                    },
                  );
                }),
                SizedBox(height: 50.h),
              ],
            ),
          ),
        );
      }),
    );
  }
}
