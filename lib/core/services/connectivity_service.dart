import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<ConnectivityService> init() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    await _updateStatus(results);

    _subscription = connectivity.onConnectivityChanged.listen(_updateStatus);
    return this;
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasNetwork = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasNetwork) {
      isOnline.value = false;
      return;
    }

    try {
      final lookupResult = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      final hasInternet =
          lookupResult.isNotEmpty && lookupResult.first.rawAddress.isNotEmpty;
      isOnline.value = hasInternet;
    } catch (_) {
      isOnline.value = false;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
