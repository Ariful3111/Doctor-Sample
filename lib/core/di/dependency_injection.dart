import 'package:doctor_app/data/local/storage_service.dart';
import 'package:doctor_app/data/networks/get_networks.dart';
import 'package:doctor_app/data/networks/post_with_response.dart';
import 'package:doctor_app/data/networks/post_without_response.dart';
import 'package:doctor_app/data/networks/socket_service.dart';
import 'package:doctor_app/data/services/global_notification_service.dart';
import 'package:doctor_app/features/dashboard/controllers/notifications_controller.dart';
import 'package:doctor_app/features/dashboard/controllers/todays_task_controller.dart';
import 'package:doctor_app/features/dashboard/repositories/get_tour_repo.dart';
import 'package:doctor_app/core/services/tour_state_service.dart';
import 'package:doctor_app/core/services/connectivity_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DependencyInjection {
  static Future<void> init() async {
    await GetStorage.init();
    Get.lazyPut(() => StorageService(), fenix: true);
    Get.lazyPut(() => PostWithoutResponse(), fenix: true);
    Get.lazyPut(() => PostWithResponse(), fenix: true);
    Get.lazyPut(() => GetNetwork(), fenix: true);
    Get.lazyPut(() => SocketService(), fenix: true);

    // Eagerly instantiate services
    Get.put(TourStateService(), permanent: true);
    await Get.putAsync(
      () => ConnectivityService().init(),
      permanent: true,
    );

    // Initialize GlobalNotificationService and NotificationsController early
    // These need to be permanent for caching to work properly
    Get.put(GlobalNotificationService(), permanent: true);
    Get.put(NotificationsController(), permanent: true);

    // Register tour-related dependencies permanently to avoid binding issues
    Get.put(
      GetTourRepository(getNetwork: Get.find<GetNetwork>()),
      permanent: true,
    );
    Get.put(
      TodaysTaskController(getTourRepository: Get.find()),
      permanent: true,
    );
  }
}
