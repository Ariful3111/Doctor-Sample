import 'package:get/get.dart';
import 'package:doctor_app/data/networks/get_networks.dart';
import '../controllers/todays_task_controller.dart';
import '../controllers/notifications_controller.dart';
import '../repositories/get_tour_repo.dart';
import '../repositories/extra_pickup_repository.dart';

class TodaysTaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetTourRepository>(
      () => GetTourRepository(getNetwork: Get.find<GetNetwork>()),
    );
    Get.lazyPut<TodaysTaskController>(
      () => TodaysTaskController(getTourRepository: Get.find()),
      fenix: true,
    );

    // Bind NotificationsController if not already bound
    if (!Get.isRegistered<NotificationsController>()) {
      Get.lazyPut<ExtraPickupRepository>(() => ExtraPickupRepository());
      Get.lazyPut<NotificationsController>(
        () => NotificationsController(),
        fenix: true,
      );
    }
  }
}
