import 'package:doctor_app/features/delivery/bindings/report_binding.dart';
import 'package:doctor_app/features/delivery/views/report_screen.dart';
import 'package:get/get.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/bindings/login_binding.dart';
import '../../features/dashboard/views/todays_task_screen.dart';
import '../../features/dashboard/bindings/todays_task_binding.dart';
import '../../features/dashboard/views/notifications_screen.dart';
import '../../features/dashboard/bindings/notifications_binding.dart';
import '../../features/dashboard/views/tour_dr_list_screen.dart';
import '../../features/dashboard/bindings/tour_dr_list_binding.dart';
import '../../features/delivery/views/dr_details_screen.dart';
import '../../features/delivery/bindings/dr_details_binding.dart';
import '../../features/delivery/views/barcode_scanner_screen.dart';
import '../../features/delivery/bindings/barcode_scanner_binding.dart';
import '../../features/delivery/views/pickup_confirmation_screen.dart';
import '../../features/delivery/bindings/pickup_confirmation_binding.dart';
import '../../features/drop_off/views/drop_location_screen.dart';
import '../../features/drop_off/bindings/drop_location_binding.dart';
import '../../features/drop_off/views/pending_drop_date_screen.dart';
import '../../features/drop_off/controllers/pending_drop_date_controller.dart';
import '../../features/drop_off/views/location_code_screen.dart';
import '../../features/drop_off/bindings/location_code_binding.dart';
import '../../features/drop_off/views/image_submission_screen.dart';
import '../../features/drop_off/bindings/image_submission_binding.dart';
import '../../features/drop_off/views/sample_scanning_screen.dart';
import '../../features/drop_off/bindings/sample_scanning_binding.dart';
import '../../features/drop_off/views/drop_confirmation_screen.dart';
import '../../features/drop_off/bindings/drop_confirmation_binding.dart';
import 'app_routes.dart';

/// App Pages
/// This class contains all the GetX page configurations with their bindings
class AppPages {
  // Private constructor to prevent instantiation
  AppPages._();

  /// Initial route
  static const String initial = AppRoutes.initial;

  /// List of all app pages with their routes and bindings
  static final routes = [
    // Authentication Pages
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Dashboard Pages
    GetPage(
      name: AppRoutes.todaysTask,
      page: () => const TodaysTaskScreen(),
      binding: TodaysTaskBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.tourDrList,
      page: () => const TourDrListScreen(),
      binding: TourDrListBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Delivery Pages
    GetPage(
      name: AppRoutes.drDetails,
      page: () => const DrDetailsScreen(),
      binding: DrDetailsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.barcodeScanner,
      page: () => const BarcodeScannerScreen(),
      binding: BarcodeScannerBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.pickupConfirmation,
      page: () => const PickupConfirmationScreen(),
      binding: PickupConfirmationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.dropLocation,
      page: () => const DropLocationScreen(),
      binding: DropLocationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.pendingDropDate,
      page: () => const PendingDropDateScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PendingDropDateController>(
          () => PendingDropDateController(),
        );
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.locationCode,
      page: () => const LocationCodeScreen(),
      binding: LocationCodeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.imageSubmission,
      page: () => const ImageSubmissionScreen(),
      binding: ImageSubmissionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Sample Scanning Page
    GetPage(
      name: AppRoutes.sampleScanning,
      page: () => const SampleScanningScreen(),
      binding: SampleScanningBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Drop Confirmation Page
    GetPage(
      name: AppRoutes.dropConfirmation,
      page: () => const DropConfirmationScreen(),
      binding: DropConfirmationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.report,
      page: () => const ReportScreen(),
      binding: ReportBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // GetPage(
    //   name: AppRoutes.home,
    //   page: () => const HomeScreen(),
    //   binding: HomeBinding(),
    //   transition: Transition.fadeIn,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),

    // GetPage(
    //   name: AppRoutes.dashboard,
    //   page: () => const DashboardScreen(),
    //   binding: DashboardBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),

    // GetPage(
    //   name: AppRoutes.profile,
    //   page: () => const ProfileScreen(),
    //   binding: ProfileBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
  ];
}
