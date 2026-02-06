/// ===============================
/// COMBINED SCHEDULE MODELS
/// ===============================

class CombinedScheduleModel {
  final bool? success;
  final String? message;
  final CombinedScheduleData? data;

  CombinedScheduleModel({this.success, this.message, this.data});

  factory CombinedScheduleModel.fromJson(Map<String, dynamic> json) {
    return CombinedScheduleModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? CombinedScheduleData.fromJson(json['data'])
          : null,
    );
  }
}

class CombinedScheduleData {
  final String? driverId;
  final String? date;
  final int? totalTours;
  final List<AppointmentModel>? appointments;
  final List<TourModel>? tours;
  final List<dynamic>? pendingNotifications;
  final ScheduleMetadata? metadata;

  CombinedScheduleData({
    this.driverId,
    this.date,
    this.totalTours,
    this.appointments,
    this.tours,
    this.pendingNotifications,
    this.metadata,
  });

  factory CombinedScheduleData.fromJson(Map<String, dynamic> json) {
    final appointments = json['appointments'] is List
        ? (json['appointments'] as List)
              .map((e) => AppointmentModel.fromJson(e))
              .toList()
        : null;

    // Extract tours either from appointments or from tours field
    List<TourModel>? tours;

    if (appointments != null && appointments.isNotEmpty) {
      // First try to get tours from appointments
      final toursFromAppointments = appointments
          .map((a) => a.tour)
          .whereType<TourModel>()
          .toList();
      // Use these if we found any, otherwise try json['tours']
      tours = toursFromAppointments.isNotEmpty
          ? toursFromAppointments
          : (json['tours'] is List
                ? (json['tours'] as List)
                      .map((e) => TourModel.fromJson(e))
                      .toList()
                : null);
    } else {
      // No appointments, check direct tours field
      tours = json['tours'] is List
          ? (json['tours'] as List).map((e) => TourModel.fromJson(e)).toList()
          : null;
    }

    return CombinedScheduleData(
      driverId: json['driverId']?.toString(),
      date: json['date'],
      totalTours: json['totalTours'],
      appointments: appointments,
      tours: tours ?? [], // Default to empty list instead of null
      pendingNotifications: json['pendingNotifications'] is List
          ? json['pendingNotifications']
          : [],
      metadata: json['metadata'] != null
          ? ScheduleMetadata.fromJson(json['metadata'])
          : null,
    );
  }

  String? getAppointmentIdForTour(int? tourId) {
    if (tourId == null || appointments == null) return null;
    try {
      return appointments!
          .firstWhere((a) => a.tour?.id == tourId)
          .appointmentId
          ?.toString();
    } catch (_) {
      return null;
    }
  }
}

/// ===============================
/// TOUR MODEL (PURE DATA)
/// ===============================

class TourModel {
  final int? id;
  final String? name;
  final List<Doctor>? regularDoctors;
  final List<Doctor>? extraDoctors;
  final List<dynamic>? dropLocations;
  final int? extraPickupId;
  final String? type;

  late final List<Doctor> allDoctors;

  TourModel({
    this.id,
    this.name,
    this.regularDoctors,
    this.extraDoctors,
    this.dropLocations,
    this.extraPickupId,
    this.type,
  }) {
    allDoctors = [...(regularDoctors ?? []), ...(extraDoctors ?? [])];
  }

  factory TourModel.fromJson(Map<String, dynamic> json) {
    final doctorsList =
        json['availableDoctors'] ?? json['regularDoctors'] ?? [];
    final regular = doctorsList is List
        ? (doctorsList).map((e) => Doctor.fromJson(e)).toList()
        : <Doctor>[];

    final extra = json['extraDoctors'] is List
        ? (json['extraDoctors'] as List).map((e) => Doctor.fromJson(e)).toList()
        : <Doctor>[];

    return TourModel(
      id: json['id'],
      name: json['name'],
      regularDoctors: regular,
      extraDoctors: extra,
      dropLocations: json['dropLocations'] is List ? json['dropLocations'] : [],
      extraPickupId: json['extraPickupId'],
      type: json['type'],
    );
  }
}

/// ===============================
/// DOCTOR MODEL (PURE DATA)
/// ===============================

class Doctor {
  final int? id;
  final String? name;
  final String? street;
  final String? area;
  final String? zip;
  final String? locationLink;
  final String? description;
  final String? pdfFile;
  final String? email;
  final String? phone;
  final int? extraPickupId;
  final bool isExtraPickup;

  Doctor({
    this.id,
    this.name,
    this.street,
    this.area,
    this.zip,
    this.locationLink,
    this.description,
    this.pdfFile,
    this.email,
    this.phone,
    this.extraPickupId,
    required this.isExtraPickup,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] is Map ? json['location'] as Map : null;

    return Doctor(
      id: json['id'],
      name: json['name'],
      street: loc?['street'] ?? json['street'],
      area: loc?['area'] ?? json['area'],
      zip: loc?['zip']?.toString() ?? json['zip']?.toString(),
      locationLink: _sanitize(loc?['link'] ?? json['locationLink']),
      description: json['description'],
      pdfFile: _sanitize(json['pdfFile']),
      email: json['email'],
      phone: json['phone'],
      extraPickupId: json['extraPickupId'],
      isExtraPickup:
          _parseBool(json['isExtraPickup']) ||
          _parseBool(json['isxtraPickup']) ||
          (json['extraPickupId'] != null),
    );
  }
}

/// ===============================
/// SUPPORT MODELS
/// ===============================

class AppointmentModel {
  final int? appointmentId;
  final String? status;
  final TourModel? tour;
  final List<dynamic>? dropLocations;

  AppointmentModel({
    this.appointmentId,
    this.status,
    this.tour,
    this.dropLocations,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId'],
      status: json['status'],
      tour: json['tour'] != null ? TourModel.fromJson(json['tour']) : null,
      dropLocations: json['dropLocations'] is List ? json['dropLocations'] : [],
    );
  }
}

class ScheduleMetadata {
  final int? regularDoctorsCount;
  final int? extraDoctorsCount;
  final int? totalTours;
  final int? pendingNotificationsCount;

  ScheduleMetadata({
    this.regularDoctorsCount,
    this.extraDoctorsCount,
    this.totalTours,
    this.pendingNotificationsCount,
  });

  factory ScheduleMetadata.fromJson(Map<String, dynamic> json) {
    return ScheduleMetadata(
      regularDoctorsCount: json['regularDoctorsCount'],
      extraDoctorsCount: json['extraDoctorsCount'],
      totalTours: json['totalTours'],
      pendingNotificationsCount: json['pendingNotificationsCount'],
    );
  }
}

/// ===============================
/// UTILS
/// ===============================

String? _sanitize(dynamic value) {
  if (value == null) return null;
  return value.toString().replaceAll('`', '').trim();
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value?.toString().trim().toLowerCase();
  if (s == null || s.isEmpty) return false;
  return s == 'true' || s == '1' || s == 'yes';
}
