/// App Routes
/// This class contains all the route constants used in the application
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  /// Initial route - Login Screen
  static const String initial = '/login';

  /// Authentication Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  /// Main App Routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String todaysTask = '/todays-task';
  static const String notifications = '/notifications';
  static const String tourDrList = '/tour-dr-list';
  static const String drDetails = '/dr-details';
  static const String barcodeScanner = '/barcode-scanner';
  static const String pickupConfirmation = '/pickup-confirmation';
  static const String dropLocation = '/drop-location';
  static const String pendingDropDate = '/pending-drop-date';
  static const String locationCode = '/location-code';
  static const String imageSubmission = '/image-submission';
  static const String sampleScanning = '/sample-scanning';
  static const String dropConfirmation = '/drop-confirmation';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Doctor Related Routes
  static const String doctorList = '/doctors';
  static const String doctorDetails = '/doctor-details';
  static const String appointment = '/appointment';
  static const String appointmentHistory = '/appointment-history';

  /// Patient Related Routes
  static const String patientProfile = '/patient-profile';
  static const String medicalHistory = '/medical-history';
  static const String prescriptions = '/prescriptions';

  /// Other Routes
  static const String help = '/help';
  static const String about = '/about';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String privacyPolicy = '/privacy-policy';
  static const report = '/report';
}
