import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../data/local/storage_service.dart';
import '../constants/network_paths.dart';

class TourStateService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _formatHHmm(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  // Storage keys
  static const _activeTourKey = 'active_tour_id';
  static const _activeTourStartTimeKey = 'active_tour_start_time';
  static const _tourStartDateKey = 'tour_start_date';
  static const _completedDoctorsKey = 'completed_doctors';
  static const _visitedDoctorsKey = 'visited_doctors';
  static const _samplesSubmittedKey = 'samples_submitted_count';
  static const _tourIntentionalExitKey = 'tour_intentional_exit';
  static const _activeAppointmentIdKey = 'active_appointment_id';

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
  Future<void> startTour(String tourId, int? appointmentId) async {
    if (hasActiveTour && activeTourId!.value == tourId) return;

    if (activeTourId!.value.isNotEmpty && activeTourId!.value != tourId) {
      completedDoctorIds.clear();
      visitedDoctorIds.clear();
      samplesSubmittedCount.value = 0;
      await _storage.write(key: _completedDoctorsKey, value: <String>[]);
      await _storage.write(key: _visitedDoctorsKey, value: <String>[]);
      await _storage.write(key: _samplesSubmittedKey, value: 0);
    }

    final now = DateTime.now();
    final date = _formatDate(now);

    await _storage.write(key: _activeTourKey, value: tourId);
    await _storage.write(key: 'tourId', value: int.tryParse(tourId) ?? tourId);
    await _storage.write(
      key: _activeTourStartTimeKey,
      value: now.toIso8601String(),
    );
    await _storage.write(key: _tourStartDateKey, value: date);
    await _storage.write(key: 'appointment_start_date', value: date);
    if (appointmentId != null) {
      await _storage.write(key: _activeAppointmentIdKey, value: appointmentId);
    }
    await _storage.write(key: _tourIntentionalExitKey, value: false);
    print('Tour started: $tourId, Date: $date, Time: ${_formatHHmm(now)}');
    activeTourId!.value = tourId;
    tourStartDate.value = date;
    tourStartTime.value = now;
    tourIntentionalExit.value = false;

    await _callStartTourAPI(
      tourId,
      date: date,
      timestamp: now,
      appointmentId: appointmentId,
    );
  }

  // ============================
  // TOUR END (SINGLE ENTRY)
  // ============================
  Future<bool> endTour({int? appointmentId, String? tourId}) async {
    if (_ending) return false;
    _ending = true;

    try {
      final idFromArg = (tourId ?? '').trim();
      final idFromState = activeTourId!.value.trim();
      final idFromStorage = (_storage.read<dynamic>(key: _activeTourKey) ?? '')
          .toString()
          .trim();
      final effectiveTourId = idFromArg.isNotEmpty
          ? idFromArg
          : (idFromState.isNotEmpty ? idFromState : idFromStorage);

      if (effectiveTourId.isEmpty || appointmentId == null) {
        return false;
      }

      final ok = await _callEndTourAPI(
        effectiveTourId,
        appointmentId: appointmentId,
      );
      if (!ok) {
        return false;
      }

      await _storage.write(key: _tourIntentionalExitKey, value: true);
      tourIntentionalExit.value = true;
      _clearLocalState();
      return true;
    } finally {
      _ending = false;
    }
  }

  Future<void> clearTourState() async {
    await _storage.write(key: _tourIntentionalExitKey, value: true);
    tourIntentionalExit.value = true;
    _clearLocalState();
  }

  void _clearLocalState() {
    _storage.remove(key: _activeTourKey);
    _storage.remove(key: _activeTourStartTimeKey);
    _storage.remove(key: _tourStartDateKey);
    _storage.remove(key: _completedDoctorsKey);
    _storage.remove(key: _visitedDoctorsKey);
    _storage.remove(key: _samplesSubmittedKey);
    _storage.remove(key: _activeAppointmentIdKey);

    activeTourId!.value = '';
    tourStartTime.value = null;
    tourStartDate.value = '';
    completedDoctorIds.clear();
    visitedDoctorIds.clear();
    samplesSubmittedCount.value = 0;
  }

  int? get currentAppointmentId =>
      _storage.read<int>(key: _activeAppointmentIdKey);

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
  Future<void> _callStartTourAPI(
    String tourId, {
    String? date,
    DateTime? timestamp,
    int? appointmentId,
  }) async {
    final driverId = _storage.read<int>(key: 'id');
    if (driverId == null) return;

    final now = timestamp ?? DateTime.now();
    final dateCandidate = (date ?? tourStartDate.value).trim();
    final effectiveDate = dateCandidate.isNotEmpty
        ? dateCandidate
        : _formatDate(now);
    if (tourStartDate.value != effectiveDate) {
      tourStartDate.value = effectiveDate;
      await _storage.write(key: _tourStartDateKey, value: effectiveDate);
      await _storage.write(key: 'appointment_start_date', value: effectiveDate);
    }
    print(
      'Starting tour: $tourId, Date: $effectiveDate, Start Time: ${_formatHHmm(now)}, Appointment ID: $appointmentId',
    );
    final body = {
      'tourId': int.tryParse(tourId) ?? tourId,
      'date': effectiveDate,
      'startTime': _formatHHmm(now),
      'appointmentId': appointmentId,
    };

    await http.post(
      Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.startTour}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<bool> _callEndTourAPI(
    String tourId, {
    required int appointmentId,
  }) async {
    final driverId = _storage.read<int>(key: 'id');
    if (driverId == null) return false;
    final now = DateTime.now();
    final storedStartDate = tourStartDate.value.trim();
    final persistedStartDate =
        (_storage.read<String>(key: _tourStartDateKey) ?? '').trim();
    final appointmentStartDate =
        (_storage.read<String>(key: 'appointment_start_date') ?? '').trim();
    final effectiveStartDate = storedStartDate.isNotEmpty
        ? storedStartDate
        : (persistedStartDate.isNotEmpty
              ? persistedStartDate
              : (appointmentStartDate.isNotEmpty
                    ? appointmentStartDate
                    : _formatDate(now)));
    final todayDate = _formatDate(now);
    final isSameDay = effectiveStartDate == todayDate;
    final endTimeToSend = isSameDay ? _formatHHmm(now) : '23:59';
    final lateFlag = isSameDay ? 0 : 1;

    if (tourStartDate.value != effectiveStartDate) {
      tourStartDate.value = effectiveStartDate;
      await _storage.write(key: _tourStartDateKey, value: effectiveStartDate);
      await _storage.write(
        key: 'appointment_start_date',
        value: effectiveStartDate,
      );
    }
    print(
      'Ending tour: $tourId, Date: $effectiveStartDate, End Time: $endTimeToSend, Late Flag: $lateFlag, Appointment ID: $appointmentId',
    );
    final body = {
      'tourId': int.tryParse(tourId) ?? tourId,
      'date': effectiveStartDate,
      'endTime': endTimeToSend,
      'late': lateFlag,
      'appointmentId': appointmentId,
    };
    print(
      'Ending tour: $tourId, Date: $effectiveStartDate, End Time: $endTimeToSend, Late Flag: $lateFlag, Appointment ID: $appointmentId',
    );
    final response = await http.post(
      Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.endTour}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    debugPrint('End tour response: ${response.statusCode} ${response.body}');
    return response.statusCode == 200 || response.statusCode == 201;
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
  Future<void> callStartTourAPI(String tourId, {int? appointmentId}) async {
    await _callStartTourAPI(tourId, appointmentId: appointmentId);
  }

  Future<void> callFirstAppointmentStartAPI({int? appointmentId}) async {
    await _callStartTourAPI(activeTourId!.value, appointmentId: appointmentId);
  }

  Future<void> deleteTourTime({int? appointmentId}) async {
    if (activeTourId!.value.isNotEmpty) {
      await _callDeleteTourTimeAPI(
        activeTourId!.value,
        appointmentId: appointmentId,
      );
    }
  }

  Future<bool> checkAndCompleteTour() async {
    return await _checkAndCompleteTourInternal();
  }

  // ============================
  // INTERNAL PRIVATE METHODS
  // ============================
  Future<void> _callDeleteTourTimeAPI(
    String tourId, {
    int? appointmentId,
  }) async {
    final driverId = _storage.read<int>(key: 'id');
    if (driverId == null) return;
    final now = DateTime.now();
    final storedStartDate = tourStartDate.value.trim();
    final effectiveStartDate = storedStartDate.isNotEmpty
        ? storedStartDate
        : _formatDate(now);
    final exitFlag = samplesSubmittedCount.value > 0 ? 1 : 0;
    if (tourStartDate.value != effectiveStartDate) {
      tourStartDate.value = effectiveStartDate;
      await _storage.write(key: _tourStartDateKey, value: effectiveStartDate);
      await _storage.write(
        key: 'appointment_start_date',
        value: effectiveStartDate,
      );
    }

    try {
      final body = {
        'driverId': driverId,
        'tourId': int.tryParse(tourId) ?? tourId,
        'date': effectiveStartDate,
        'time': _formatHHmm(now),
        'appointmentId': appointmentId,
        'exit': exitFlag,
      };
      print('--------Exit: $exitFlag--------');
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

      final completed = response.statusCode == 200;
      if (completed) {
        await clearTourState();
      }
      return completed;
    } catch (e) {
      print('❌ Error checking tour completion: $e');
      return false;
    }
  }
}
