import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../data/local/storage_service.dart';
import '../constants/network_paths.dart';

class TourStateService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  // Storage keys
  static const _activeTourKey = 'active_tour_id';
  static const _activeTourStartTimeKey = 'active_tour_start_time';
  static const _tourStartDateKey = 'tour_start_date';
  static const _completedDoctorsKey = 'completed_doctors';
  static const _visitedDoctorsKey = 'visited_doctors';
  static const _samplesSubmittedKey = 'samples_submitted_count';
  static const _tourIntentionalExitKey = 'tour_intentional_exit';

  // Reactive state
  final RxString? activeTourId = RxString('');
  final Rx<DateTime?> tourStartTime = Rx<DateTime?>(null);
  final RxString tourStartDate = ''.obs;
  final RxSet<String> completedDoctorIds = <String>{}.obs;
  final RxSet<String> visitedDoctorIds = <String>{}.obs;
  final RxInt samplesSubmittedCount = 0.obs;
  final RxBool tourIntentionalExit = false.obs;

  bool _ending = false;

  @override
  void onInit() {
    super.onInit();
    _restoreState();
  }

  // ============================
  // STATE RESTORE
  // ============================
  void _restoreState() {
    final exited = _storage.read<bool>(key: _tourIntentionalExitKey) ?? false;
    if (exited) {
      _clearLocalState();
      return;
    }

    activeTourId!.value = _storage.read<String>(key: _activeTourKey) ?? '';
    tourStartDate.value = _storage.read<String>(key: _tourStartDateKey) ?? '';
    final startTime = _storage.read<String>(key: _activeTourStartTimeKey);

    if (startTime != null) {
      tourStartTime.value = DateTime.tryParse(startTime);
    }

    final completed = _storage.read<List>(key: _completedDoctorsKey) ?? [];
    completedDoctorIds.addAll(completed.map((e) => e.toString()));

    final visited = _storage.read<List>(key: _visitedDoctorsKey) ?? [];
    visitedDoctorIds.addAll(visited.map((e) => e.toString()));

    samplesSubmittedCount.value =
        _storage.read<int>(key: _samplesSubmittedKey) ?? 0;
  }

  // ============================
  // TOUR START
  // ============================
  Future<void> startTour(String tourId) async {
    if (hasActiveTour && activeTourId!.value == tourId) return;

    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _storage.write(key: _activeTourKey, value: tourId);
    await _storage.write(
      key: _activeTourStartTimeKey,
      value: now.toIso8601String(),
    );
    await _storage.write(key: _tourStartDateKey, value: date);
    await _storage.write(key: _tourIntentionalExitKey, value: false);

    activeTourId!.value = tourId;
    tourStartDate.value = date;
    tourStartTime.value = now;
    tourIntentionalExit.value = false;

    await _callStartTourAPI(tourId);
  }

  // ============================
  // TOUR END (SINGLE ENTRY)
  // ============================
  Future<void> endTour() async {
    if (_ending) return;
    _ending = true;

    try {
      if (activeTourId!.value.isNotEmpty) {
        await _callEndTourAPI(activeTourId!.value);
      }
    } catch (_) {}

    await _storage.write(key: _tourIntentionalExitKey, value: true);
    tourIntentionalExit.value = true;

    _clearLocalState();
    _ending = false;
  }

  void _clearLocalState() {
    _storage.remove(key: _activeTourKey);
    _storage.remove(key: _activeTourStartTimeKey);
    _storage.remove(key: _tourStartDateKey);
    _storage.remove(key: _completedDoctorsKey);
    _storage.remove(key: _visitedDoctorsKey);
    _storage.remove(key: _samplesSubmittedKey);

    activeTourId!.value = '';
    tourStartTime.value = null;
    tourStartDate.value = '';
    completedDoctorIds.clear();
    visitedDoctorIds.clear();
    samplesSubmittedCount.value = 0;
  }

  // ============================
  // DOCTOR STATE
  // ============================
  Future<void> markDoctorVisited(String id) async {
    visitedDoctorIds.add(id);
    await _storage.write(
      key: _visitedDoctorsKey,
      value: visitedDoctorIds.toList(),
    );
  }

  Future<void> markDoctorCompleted(String id, {String? appointmentId}) async {
    completedDoctorIds.add(id);
    await _storage.write(
      key: _completedDoctorsKey,
      value: completedDoctorIds.toList(),
    );
  }

  Future<void> incrementSamplesSubmitted() async {
    samplesSubmittedCount.value++;
    await _storage.write(
      key: _samplesSubmittedKey,
      value: samplesSubmittedCount.value,
    );
  }

  // ============================
  // API CALLS
  // ============================
  Future<void> _callStartTourAPI(String tourId) async {
    final driverId = _storage.read<int>(key: 'id');
    if (driverId == null) return;

    final now = DateTime.now();
    final body = {
      'driverId': driverId,
      'tourId': int.tryParse(tourId) ?? tourId,
      'date': tourStartDate.value,
      'startTime':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    };

    await http.post(
      Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.startTour}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<void> _callEndTourAPI(String tourId) async {
    final driverId = _storage.read<int>(key: 'id');
    if (driverId == null) return;

    final now = DateTime.now();
    final body = {
      'driverId': driverId,
      'tourId': int.tryParse(tourId) ?? tourId,
      'date': tourStartDate.value,
      'endTime':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'endedDoctors': completedDoctorIds.length,
      'samplesSubmitted': samplesSubmittedCount.value,
      'exit': 1,
    };

    await http.post(
      Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.endTour}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // ============================
  // GETTERS
  // ============================
  bool get hasActiveTour => activeTourId!.value.isNotEmpty;
  String? get currentTourId =>
      activeTourId!.value.isEmpty ? null : activeTourId!.value;

  // ============================
  // PUBLIC WRAPPER METHODS (for external calls)
  // ============================
  Future<void> callStartTourAPI(String tourId) async {
    await _callStartTourAPI(tourId);
  }

  Future<void> callFirstAppointmentStartAPI() async {
    await _callStartTourAPI(activeTourId!.value);
  }

  Future<void> deleteTourTime() async {
    if (activeTourId!.value.isNotEmpty) {
      await _callDeleteTourTimeAPI(activeTourId!.value);
    }
  }

  Future<bool> checkAndCompleteTour() async {
    return await _checkAndCompleteTourInternal();
  }

  // ============================
  // INTERNAL PRIVATE METHODS
  // ============================
  Future<void> _callDeleteTourTimeAPI(String tourId) async {
    final driverId = _storage.read<int>(key: 'id');
    if (driverId == null) return;

    try {
      final body = {
        'driverId': driverId,
        'tourId': int.tryParse(tourId) ?? tourId,
      };

      await http.post(
        Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.deleteTourTime}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      print('❌ Error deleting tour time: $e');
    }
  }

  Future<bool> _checkAndCompleteTourInternal() async {
    try {
      if (activeTourId!.value.isEmpty) return false;

      final driverId = _storage.read<int>(key: 'id');
      if (driverId == null) return false;

      final body = {
        'driverId': driverId,
        'tourId': int.tryParse(activeTourId!.value) ?? activeTourId!.value,
        'completedDoctors': completedDoctorIds.length,
        'samplesSubmitted': samplesSubmittedCount.value,
      };

      final response = await http.post(
        Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.endTour}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error checking tour completion: $e');
      return false;
    }
  }
}
