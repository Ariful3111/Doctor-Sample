import 'package:get/get.dart';
import '../../../data/networks/get_networks.dart';
import '../repositories/get_tour_repo.dart';
import '../controllers/todays_task_controller.dart';
import '../controllers/notifications_controller.dart';

class TourDrListBinding extends Bindings {
  @override
  void dependencies() {
    // Repository (screen scoped)
    Get.lazyPut<GetTourRepository>(
      () => GetTourRepository(
        getNetwork: Get.find<GetNetwork>(),
      ),
      fenix: true,
    );

    // Controller (screen scoped)
    Get.lazyPut<TodaysTaskController>(
      () => TodaysTaskController(
        getTourRepository: Get.find<GetTourRepository>(),
      ),
      fenix: true,
    );

    // Notifications Controller
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(),
      fenix: true,
    );
  }
}