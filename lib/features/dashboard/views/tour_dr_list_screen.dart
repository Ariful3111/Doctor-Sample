import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/tour_state_service.dart';
import '../controllers/todays_task_controller.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/tour_header_widget.dart';
import '../widgets/doctor_stats_widget.dart';
import '../widgets/doctor_card_widget.dart';
import '../widgets/exit_tour_warning_dialog.dart';
import '../models/tour_model.dart';

class TourDrListScreen extends StatefulWidget {
  const TourDrListScreen({super.key});

  @override
  State<TourDrListScreen> createState() => _TourDrListScreenState();
}

class _TourDrListScreenState extends State<TourDrListScreen> {
  bool _exiting = false;
  bool _canPop = false;

  TodaysTaskController get _todaysController =>
      Get.find<TodaysTaskController>();
  TourStateService get _tourState => Get.find<TourStateService>();

  String? get _tourId {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) return args['taskId']?.toString();
    if (args is String) return args;
    return _tourState.currentTourId;
  }

  @override
  void initState() {
    super.initState();
    _initTour();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().fetchPendingPickups(silent: true);
      }
    });
  }

  Future<void> _initTour() async {
    final id = _tourId;
    if (id == null) return;

    final appointmentId = int.tryParse(
      _todaysController.todaySchedule.value?.data?.getAppointmentIdForTour(
            int.tryParse(id),
          ) ??
          '',
    );

    if (!_tourState.hasActiveTour || _tourState.currentTourId != id) {
      _tourState.startTour(id, appointmentId);
    } else {
      _tourState.callStartTourAPI(id, appointmentId: appointmentId);
    }
    _tourState.callFirstAppointmentStartAPI(appointmentId: appointmentId);
  }

  Future<void> _handleExit() async {
    if (_exiting) return;
    _exiting = true;

    try {
      final id = _tourId;
      final appointmentId = id == null
          ? null
          : int.tryParse(
              _todaysController.todaySchedule.value?.data
                      ?.getAppointmentIdForTour(int.tryParse(id)) ??
                  '',
            );
      final tours = _todaysController.todaySchedule.value?.data?.tours ?? [];
      final tour = tours.firstWhereOrNull((t) => t.id?.toString() == id);
      final totalDoctors = tour?.allDoctors.length ?? 0;
      final completed = _tourState.completedDoctorIds.length;
      await Get.dialog(
        ExitTourWarningDialog(
          totalDoctors: totalDoctors,
          completedDoctors: completed,
          visitedDoctors: _tourState.visitedDoctorIds.length,
          samplesSubmitted: _tourState.samplesSubmittedCount.value,
          onConfirm: () {
            // Future.microtask(() async {
            //   await _tourState.deleteTourTime(appointmentId: appointmentId);
            //   await _tourState.endTour(appointmentId: appointmentId);
            // });
            final navigator = Get.key.currentState;
            if (navigator != null) {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.todaysTask,
                (route) => false,
              );
            }
          },
          onSilentExit: () {
            Future.microtask(() async {
              await _tourState.deleteTourTime(appointmentId: appointmentId);
            });
            final navigator = Get.key.currentState;
            if (navigator != null) {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.todaysTask,
                (route) => false,
              );
            }
          },
        ),
        barrierDismissible: false,
      );
    } finally {
      _exiting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure NotificationsController is registered
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(NotificationsController());
    }

    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          centerTitle: true,
          automaticallyImplyLeading: true,
          title: Text(
            'details'.tr,
            style: TextStyle(
              fontSize: isTablet ? 14.sp : 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () async {
              // Manually trigger exit check
              await _handleExit();
            },
          ),
          actions: [
            GetX<NotificationsController>(
              builder: (c) {
                final count = c.pendingPickups.length;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.textOnPrimary,
                      onPressed: () => Get.toNamed(AppRoutes.notifications),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: CircleAvatar(
                          radius: 7,
                          backgroundColor: AppColors.error,
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Obx(() {
          if (_todaysController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tours =
              _todaysController.todaySchedule.value?.data?.tours ?? [];
          final tour = tours.firstWhere(
            (t) => t.id?.toString() == _tourId,
            orElse: () => tours.isNotEmpty
                ? tours.first
                : TourModel(
                    regularDoctors: [],
                    extraDoctors: [],
                    dropLocations: [],
                  ),
          );

          final doctors = tour.allDoctors.where((d) {
            final id = d.id?.toString() ?? '';
            return !_tourState.completedDoctorIds.contains(id);
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TourHeaderWidget(tourName: tour.name ?? ''),
                SizedBox(height: 20.h),
                DoctorStatsWidget(
                  completed: _tourState.completedDoctorIds.length,
                  inProgress: 0,
                  pending: doctors.length,
                ),
                SizedBox(height: 24.h),
                if (doctors.isEmpty)
                  Center(
                    child: Text(
                      'no_doctors_in_this_tour'.tr,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doctors.length,
                    itemBuilder: (_, i) {
                      final d = doctors[i];
                      return DoctorCardWidget(
                        doctor: {
                          'id': d.id?.toString() ?? '',
                          'name': d.name ?? 'Unknown Doctor',
                          'hospital': d.street ?? '',
                          'area': d.area ?? '',
                          'phone': d.phone ?? '',
                          'zip': d.zip ?? '',
                        },
                        onTap: () async {
                          await _tourState.markDoctorVisited(d.id.toString());
                          // Use microtask to defer navigation until next event loop
                          if (mounted) {
                            Future.microtask(() {
                              Get.toNamed(
                                AppRoutes.drDetails,
                                arguments: {
                                  'doctorId': d.id,
                                  'tourId': tour.id,
                                  'doctorData': {
                                    'name': d.name,
                                    'image': '',
                                    'pdfFile': d.pdfFile,
                                    'description': d.description,
                                    'locationLink': d.locationLink,
                                    'street': d.street,
                                    'area': d.area,
                                    'phone': d.phone,
                                    'email': d.email,
                                    'zip': d.zip,
                                  },
                                },
                              );
                            });
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
