class NetworkPaths {
  static const String baseUrl =
      'https://now-back-similer-server-backend.onrender.com';

  // Extra Pickup APIs
  static const String extraPickupAccept = '/api/extra-pickups';
  static const String extraPickupReject = '/api/extra-pickups';
  static const String extraPickups = '/api/extra-pickups';

  // Drop Location APIs
  static const String dropLocations = '/api/droplocations';

  // Tour APIs
  static const String startTour = '/api/startTour';
  static const String endTour = '/api/endTour';
  static const String deleteTourTime = '/api/deleteTourtime';

  // Doctor APIs
  static const String startReport = '/api/startReport';
  static const String problemReportDr = '/api/problemReportDr';
  static const String doctorImageSubmit = '/api/doctor-report-image';

  // Appointment APIs
  static String appointmentStart(String appointmentId) =>
      '/api/startTour/$appointmentId';
  static String appointmentsByDriver(String driverId, String date) =>
      '/api/appointments/driver/$driverId/$date';

  // Drop Point APIs
  static const String dropPointSubmit = '/api/submit';
  static const String problemReportLab = '/api/problemReportLab';

  // Helper methods
  static String acceptExtraPickup(int id) => '$extraPickupAccept/$id/accept';
  static String rejectExtraPickup(int id) => '$extraPickupReject/$id/reject';
  static String getPendingPickupsByDriver(int driverId) =>
      '$extraPickups/driver/$driverId';
  static String getDropLocation(String name, String floor) =>
      '$dropLocations/$name/$floor';

  static String getDropLocationByName(String name) =>
      '$dropLocations/name/$name';

  static String getDropLocationByNameAndDriver(String name, int driverId) =>
      '$dropLocations/name/$name/driver/$driverId';

  static String getDropLocationById(int id) => '$dropLocations/$id';
}
