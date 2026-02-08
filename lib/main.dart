import 'package:doctor_app/core/di/dependency_injection.dart';
import 'package:doctor_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/themes/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/utils/app_translations.dart';
import 'core/utils/locale_utils.dart';
import 'data/local/storage_service.dart';
import 'data/networks/socket_service.dart';
import 'data/services/global_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  final storage = Get.find<StorageService>();
  //final tourStateService = Get.find<TourStateService>();
  final dynamic storedId = await storage.read(key: "id");
  final int userID = (storedId is int)
      ? storedId
      : int.tryParse('$storedId') ?? 0;

  // Check if user has active tour
  String initialRoute;
  Map<String, dynamic>? initialArguments;

  if (userID == 0) {
    initialRoute = AppPages.initial;
  } else {
    final activeTourId = (await storage.read(key: 'active_tour_id'))?.toString();
    final exited =
        (await storage.read(key: 'tour_intentional_exit')) == true;
    if (!exited && activeTourId != null && activeTourId.trim().isNotEmpty) {
      initialRoute = AppRoutes.tourDrList;
      initialArguments = {'taskId': activeTourId.trim()};
    } else {
      initialRoute = AppRoutes.todaysTask;
    }
  }

  runApp(MyApp(initialRoute: initialRoute, initialArguments: initialArguments));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  final Map<String, dynamic>? initialArguments;

  const MyApp({super.key, required this.initialRoute, this.initialArguments});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - ensure socket is connected
        print('🔄 App resumed - checking socket connection...');
        _ensureSocketConnected();
        break;
      case AppLifecycleState.paused:
        // App went to background
        print('⏸️ App paused - socket will auto-reconnect when resumed');
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call)
        break;
      case AppLifecycleState.detached:
        // App is detached
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  Future<void> _ensureSocketConnected() async {
    try {
      if (!Get.isRegistered<SocketService>() ||
          !Get.isRegistered<StorageService>()) {
        return;
      }

      final storage = Get.find<StorageService>();
      final driverId = await storage.read<int>(key: 'id');

      if (driverId != null) {
        final socketService = Get.find<SocketService>();

        // Reconnect if disconnected
        if (!socketService.isConnected) {
          print('🔌 Socket disconnected - reconnecting...');
          await socketService.connect(driverId: driverId);

          // Ensure global listeners are attached
          if (Get.isRegistered<GlobalNotificationService>()) {
            await Get.find<GlobalNotificationService>().ensureSocketConnected(
              driverId,
            );
          }
        } else {
          print('✅ Socket already connected');
        }
      }
    } catch (e) {
      print('❌ Error ensuring socket connection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final storage = Get.find<StorageService>();
        return GetMaterialApp(
          title: 'app_title'.tr,
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: getSavedLocale(storage),
          fallbackLocale: const Locale('en'),
          initialRoute: widget.initialRoute,
          getPages: AppPages.routes,
          debugShowCheckedModeBanner: false,
          // Global transition settings
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
          // Navigate to active tour after first frame if needed
          onReady: () {
            if (widget.initialArguments != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed(
                  widget.initialRoute,
                  arguments: widget.initialArguments,
                );
              });
            }
          },
        );
      },
    );
  }
}
