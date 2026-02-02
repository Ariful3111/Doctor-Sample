import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/network_paths.dart';
import '../../../data/local/storage_service.dart';
import '../../../core/services/tour_state_service.dart';
import '../repositories/submit_drop_off_repo.dart';

/// Controller for managing image submission functionality
/// Handles image selection from camera/gallery and submission logic
class ImageSubmissionController extends GetxController {
  // Constants
  static const String _storageKeyPrefix = 'saved_image_';

  // Services
  final ImagePicker _picker = ImagePicker();
  final StorageService _storage = Get.find<StorageService>();
  final SubmitDropOffRepository _repository = SubmitDropOffRepository();

  // Arguments from previous screens
  String dropLocationName = '';
  String dropLocationId = '';
  String dropLocationQRCode = '';
  int totalSamples = 0;
  int scannedCount = 0;
  List<String> scannedSampleIds = [];
  bool isFromDoctorReport = false; // Flag to check if coming from doctor report
  bool isDropPointReport =
      false; // Flag to check if coming from drop point report
  String doctorId = ''; // Doctor ID for marking completion
  String doctorName = '';
  String visitId = '';
  String appointmentId = '';
  String reportText = ''; // Report text for problem reports
  String tourId = ''; // Tour ID for problem reports
  bool isExtraPickup = false; // Flag to track if this is an extra pickup
  dynamic extraPickupId; // Extra pickup ID for marking incomplete

  // Reactive variables
  final RxString _selectedImagePath = ''.obs;
  final RxBool _canSubmit = false.obs;
  final RxBool _isSubmitting = false.obs;

  // Getters
  String get selectedImagePath => _selectedImagePath.value;
  bool get canSubmit => _canSubmit.value;
  bool get isSubmitting => _isSubmitting.value;

  // Reactive getters for UI
  RxString get selectedImagePath$ => _selectedImagePath;
  RxBool get canSubmit$ => _canSubmit;
  RxBool get isSubmitting$ => _isSubmitting;

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _initializeListeners();
  }

  /// Load arguments from previous screens
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      dropLocationName = args['dropLocationName'] ?? '';
      dropLocationId = args['dropLocationId'] ?? '';
      dropLocationQRCode = args['dropLocationQRCode'] ?? '';
      totalSamples = args['totalSamples'] ?? 0;
      scannedCount = args['scannedCount'] ?? 0;
      scannedSampleIds = List<String>.from(args['scannedSampleIds'] ?? []);
      isFromDoctorReport = args['isFromDoctorReport'] ?? false;
      isDropPointReport = args['isDropPointReport'] ?? false;
      doctorId = args['doctorId']?.toString() ?? '';
      doctorName = args['doctorName']?.toString() ?? '';
      visitId = args['visitId']?.toString() ?? '';
      appointmentId = args['appointmentId']?.toString() ?? '';
      reportText =
          args['reportText']?.toString() ??
          ''; // Report text for problem reports
      tourId = args['tourId']?.toString() ?? ''; // Tour ID for problem reports
      isExtraPickup = args['isExtraPickup'] ?? false; // Load extra pickup flag
      extraPickupId = args['extraPickupId']; // Load extra pickup ID

      print('🔍 _loadArguments DEBUG:');
      print('   isFromDoctorReport: $isFromDoctorReport');
      print('   isDropPointReport: $isDropPointReport');
      print('   reportText: "$reportText"');
      print('   tourId: "$tourId"');
      print('   doctorId: "$doctorId"');
      print('   isExtraPickup: $isExtraPickup');
      print('   extraPickupId: $extraPickupId');
      print('   ⚠️ ExtraTour WILL BE: ${isExtraPickup ? 1 : 0}');
    }
  }

  /// Initialize reactive listeners
  void _initializeListeners() {
    // Listen to image selection changes to update submit button state
    _selectedImagePath.listen((path) {
      _canSubmit.value = path.isNotEmpty && !_isSubmitting.value;
    });

    // Listen to submission state changes
    _isSubmitting.listen((submitting) {
      _canSubmit.value = _selectedImagePath.value.isNotEmpty && !submitting;
    });
  }

  /// Show image selection dialog with camera and gallery options
  void selectImage() {
    if (_isSubmitting.value) {
      SnackbarUtils.showWarning(
        title: 'please_wait'.tr,
        message: 'image_submission_in_progress'.tr,
      );
      return;
    }

    _showImageSourceDialog();
  }

  /// Show dialog for selecting image source
  void _showImageSourceDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('select_image'.tr),
        content: Text('choose_image_source'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _selectFromCamera();
            },
            child: Text('camera'.tr),
          ),
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }

  /// Compress image using flutter_image_compress
  Future<File?> _compressImage(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 70, // 0-100
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        final compressedFileIO = File(compressedXFile.path);
        final originalSize = imageFile.lengthSync() / 1024; // KB
        final compressedSize = compressedFileIO.lengthSync() / 1024; // KB
        print('📦 Image Compression:');
        print('   Original: ${originalSize.toStringAsFixed(2)} KB');
        print('   Compressed: ${compressedSize.toStringAsFixed(2)} KB');
        print(
          '   Saved: ${(originalSize - compressedSize).toStringAsFixed(2)} KB',
        );
        return compressedFileIO;
      }

      return null;
    } catch (e) {
      print('❌ Compression error: $e');
      return null;
    }
  }

  /// Select image from camera
  void _selectFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        SnackbarUtils.showWarning(
          title: 'no_image'.tr,
          message: 'camera_cancelled'.tr,
        );
        return;
      }

      print('📸 Photo captured from camera: ${photo.path}');

      // Compress the image
      final File? compressedFile = await _compressImage(File(photo.path));
      if (compressedFile == null) {
        print('⚠️ Failed to compress image, using original');
        // Fallback to original if compression fails
        final String? permanentPath = await _saveImagePermanently(photo.path);
        if (permanentPath != null) {
          _selectedImagePath.value = permanentPath;
          SnackbarUtils.showSuccess(
            title: 'image_captured'.tr,
            message: 'image_captured_success'.tr,
          );
        }
        return;
      }

      // Save compressed image permanently to app directory
      final String? permanentPath = await _saveImagePermanently(
        compressedFile.path,
      );

      if (permanentPath != null) {
        print('✅ Compressed image saved permanently to: $permanentPath');
        _selectedImagePath.value = permanentPath;

        SnackbarUtils.showSuccess(
          title: 'image_captured'.tr,
          message: 'image_captured_success'.tr,
        );
      } else {
        print('⚠️ Failed to save compressed image');
        SnackbarUtils.showError(
          title: 'save_error'.tr,
          message: 'failed_to_save_image'.tr,
        );
      }
    } catch (e) {
      print('❌ Camera error: $e');
      SnackbarUtils.showError(
        title: 'camera_error'.tr,
        message: 'failed_to_capture_image_from_camera'.tr,
      );
    }
  }

  /// Save image permanently to app directory
  Future<String?> _saveImagePermanently(String tempPath) async {
    try {
      // Get app's document directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/images';

      // Create images directory if it doesn't exist
      final Directory imagesDirPath = Directory(imagesDir);
      if (!await imagesDirPath.exists()) {
        await imagesDirPath.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(tempPath);
      final String fileName = 'proof_image_$timestamp$extension';
      final String permanentPath = '$imagesDir/$fileName';

      // Copy file from cache to permanent location
      final File tempFile = File(tempPath);
      await tempFile.copy(permanentPath);

      return permanentPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  /// Handle Submit button press
  /// Validates image selection and submits the proof image
  Future<void> onSubmitPressed() async {
    if (!_canSubmit.value) {
      SnackbarUtils.showWarning(
        title: 'no_image'.tr,
        message: 'please_select_image_before_submitting'.tr,
      );
      return;
    }

    if (_isSubmitting.value) {
      return; // Prevent double submission
    }

    await _submitImage();
  }

  /// Submit the selected image and drop-off data to API
  Future<void> _submitImage() async {
    try {
      _isSubmitting.value = true;

      print(
        '🚀 _submitImage START - isFromDoctorReport: $isFromDoctorReport, isDropPointReport: $isDropPointReport',
      );
      print('   reportText: $reportText');
      print('   image path: ${_selectedImagePath.value}');

      // Show loading
      SnackbarUtils.showInfo(
        title: 'submitting'.tr,
        message: 'submitting_proof_image'.tr,
      );

      // 1. Upload proof image to server
      String? imageUrl;
      if (_selectedImagePath.value.isNotEmpty) {
        final uploadResult = await _repository.uploadProofImage(
          imagePath: _selectedImagePath.value,
        );

        uploadResult.fold(
          (error) {
            throw Exception('Image upload failed: $error');
          },
          (data) {
            imageUrl = data['imageUrl'] ?? data['url'] ?? '';
            // Save locally as backup
            final String storageKey =
                '$_storageKeyPrefix${DateTime.now().millisecondsSinceEpoch}';
            _storage.write(key: storageKey, value: _selectedImagePath.value);
          },
        );
      }

      // 2. Prepare complete drop-off data
      final driverId = await _storage.read<int>(key: 'id');

      print('📍 Got driverId: $driverId');

      if (driverId == null) {
        throw Exception('Driver ID not found');
      }

      // If coming from doctor report, call doctor image submit API
      if (isFromDoctorReport) {
        print('📋 Calling _submitDoctorImage with driverId: $driverId');
        await _submitDoctorImage(imageUrl ?? '', driverId);
        return;
      }

      // If coming from drop point report, submit to lab problem report API with image
      if (isDropPointReport) {
        print('📋 Calling _submitLabProblemReport with driverId: $driverId');
        await _submitLabProblemReport(imageUrl ?? '', driverId);
        return;
      }

      final now = DateTime.now();
      final dateString = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'; // HH:MM

      final dropOffData = {
        'driverId': driverId,
        'dropLocation': {
          'qrCode': dropLocationQRCode,
          'name': dropLocationName,
          'id': dropLocationId,
        },
        'samples': {
          'total': totalSamples,
          'scanned': scannedCount,
          'sampleIds': scannedSampleIds,
        },
        'proofImageUrl': imageUrl ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'date': dateString,
        'dropTime': timeString,
      };

      // 3. Submit drop-off data to API
      final submitResult = await _repository.submitDropOff(
        dropOffData: dropOffData,
      );

      submitResult.fold(
        (error) {
          throw Exception('Drop-off submission failed: $error');
        },
        (data) {
          // Show success message
          SnackbarUtils.showSuccess(
            title: 'submitted_successfully'.tr,
            message: 'proof_image_submitted_successfully'.tr,
          );

          // Navigate back to tour doctor list, clearing the drop-off flow screens
          final tourStateService = Get.find<TourStateService>();
          Get.offNamedUntil(
            AppRoutes.tourDrList,
            (route) => false,
            arguments: {'taskId': tourStateService.currentTourId},
          );
        },
      );
    } catch (e) {
      SnackbarUtils.showError(
        title: 'submission_failed'.tr,
        message: e.toString(),
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  /// Handle Others button press
  /// Shows additional options like skip image or report issue
  void onOthersPressed() {
    if (_isSubmitting.value) {
      SnackbarUtils.showWarning(
        title: 'please_wait'.tr,
        message: 'image_submission_in_progress'.tr,
      );
      return;
    }

    _showOtherOptionsDialog();
  }

  /// Show dialog with other available options
  void _showOtherOptionsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('other_options'.tr),
        content: Text('what_would_you_like_to_do'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _skipImage();
            },
            child: Text('skip_image'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _reportIssue();
            },
            child: Text('report_issue'.tr),
          ),
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }

  /// Skip image submission and proceed
  void _skipImage() {
    SnackbarUtils.showInfo(
      title: 'skip_image'.tr,
      message: 'proceeding_without_image'.tr,
    );
    // Navigate back to doctor details screen
    Get.offNamed(AppRoutes.tourDrList);
  }

  /// Report an issue with image submission
  void _reportIssue() {
    SnackbarUtils.showInfo(
      title: 'report_issue'.tr,
      message: 'reporting_image_submission_issue'.tr,
    );
    // TODO: Implement report issue functionality
  }

  /// Clear selected image
  void clearImage() {
    if (_isSubmitting.value) {
      return; // Don't allow clearing during submission
    }

    _selectedImagePath.value = '';

    SnackbarUtils.showInfo(
      title: 'success'.tr,
      message: 'selected_image_cleared'.tr,
    );
  }

  /// Get all saved images from app directory
  Future<List<File>> getAllSavedImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/images';
      final Directory imagesDirPath = Directory(imagesDir);

      if (!await imagesDirPath.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = imagesDirPath.listSync();
      return files.whereType<File>().toList();
    } catch (e) {
      print('Error getting saved images: $e');
      return [];
    }
  }

  /// Delete a saved image
  Future<bool> deleteSavedImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get total size of saved images in MB
  Future<double> getSavedImagesSize() async {
    try {
      final List<File> images = await getAllSavedImages();
      int totalBytes = 0;

      for (File image in images) {
        totalBytes += await image.length();
      }

      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      print('Error calculating images size: $e');
      return 0.0;
    }
  }

  /// Submit doctor report image to backend
  Future<void> _submitDoctorImage(String imageUrl, int driverId) async {
    try {
      // If this is a problem report, submit to problem report API with image
      print(
        '🔍 _submitDoctorImage called - reportText: "$reportText" (isEmpty: ${reportText.isEmpty})',
      );
      if (reportText.isNotEmpty) {
        print('📤 Routing to _submitProblemReport...');
        await _submitProblemReport(imageUrl, driverId);
        return;
      }

      print('📤 Submitting as regular doctor image');
      // Otherwise, submit as regular doctor image
      final url = Uri.parse(
        '${NetworkPaths.baseUrl}${NetworkPaths.doctorImageSubmit}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': driverId,
          'imageUrl': imageUrl,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Doctor report image submitted successfully');
      } else {
        print(
          '⚠️ Doctor report image submission failed: ${response.statusCode}',
        );
      }

      // Mark doctor as completed
      final tourStateService = Get.find<TourStateService>();
      if (doctorId.isNotEmpty) {
        await tourStateService.markDoctorCompleted(
          doctorId,
          appointmentId: appointmentId,
        );
      }

      // Show success message regardless (image saved locally)
      SnackbarUtils.showSuccess(
        title: 'submitted_successfully'.tr,
        message: 'proof_image_submitted_successfully'.tr,
      );

      // Check if tour is complete
      final isTourComplete = await tourStateService.checkAndCompleteTour();

      // Wait a bit for snackbar to be seen, then navigate
      await Future.delayed(const Duration(milliseconds: 800), () {
        if (isTourComplete) {
          // Navigate back to today's task screen
          Get.offAllNamed(AppRoutes.todaysTask);
        } else {
          // Navigate back to tour details
          Get.offNamedUntil(
            AppRoutes.tourDrList,
            (route) => false,
            arguments: {'taskId': tourStateService.currentTourId},
          );
        }
      });
    } catch (e) {
      print('❌ Error submitting doctor report image: $e');

      // Mark doctor as completed even on error (image saved locally)
      final tourStateService = Get.find<TourStateService>();
      if (doctorId.isNotEmpty) {
        await tourStateService.markDoctorCompleted(
          doctorId,
          appointmentId: appointmentId,
        );
      }

      // Show success message anyway (image saved locally)
      SnackbarUtils.showSuccess(
        title: 'submitted_successfully'.tr,
        message: 'proof_image_submitted_successfully'.tr,
      );

      // Check if tour is complete
      final isTourComplete = await tourStateService.checkAndCompleteTour();

      // Wait a bit for snackbar to be seen, then navigate
      await Future.delayed(const Duration(milliseconds: 800), () {
        if (isTourComplete) {
          // Show tour completion message
          SnackbarUtils.showSuccess(
            title: 'tour_completed'.tr,
            message: 'tour_completed_message'.tr,
          );

          // Navigate back to today's task screen
          Get.offAllNamed(AppRoutes.todaysTask);
        } else {
          // Navigate back to tour details
          Get.offNamedUntil(
            AppRoutes.tourDrList,
            (route) => false,
            arguments: {'taskId': tourStateService.currentTourId},
          );
        }
      });
    }
  }

  /// Submit problem report with image to backend
  Future<void> _submitProblemReport(String imageUrl, int driverId) async {
    try {
      // Create multipart request for file upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.problemReportDr}'),
      );

      // Debug: Log what we're about to send
      print('📤 Doctor Report Data:');
      print('   driverId: $driverId');
      print('   doctorId: $doctorId');
      print('   tourId: $tourId');
      print('   text: $reportText');
      print('   image path: ${_selectedImagePath.value}');
      print('   ⚠️ isExtraPickup (member variable): $isExtraPickup');
      print('   ⚠️ ExtraTour should be: ${isExtraPickup ? 1 : 0}');

      // Add form fields
      request.fields['driverId'] = driverId.toString();
      request.fields['doctorId'] = doctorId;
      request.fields['tourId'] = tourId.isEmpty ? '0' : tourId;
      request.fields['text'] = reportText;
      request.fields['ExtraTour'] = isExtraPickup ? '1' : '0';

      // Add date and pickupTime fields (some backend endpoints expect these)
      // Try to read tour start date from storage; fall back to today's date
      final storedDate =
          _storage.read<String>(key: 'appointmentStartDate') ??
          _storage.read<String>(key: 'appointment_start_date');
      final now = DateTime.now();
      final dateToSend = (storedDate != null && storedDate.isNotEmpty)
          ? storedDate
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Determine pickupTime similar to other controllers
      String pickupTimeToSend;
      if (storedDate != null && storedDate.isNotEmpty) {
        try {
          final tourDate = DateTime.parse(storedDate);
          if (tourDate.year == now.year &&
              tourDate.month == now.month &&
              tourDate.day == now.day) {
            pickupTimeToSend =
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          } else {
            pickupTimeToSend = '23:59';
          }
        } catch (e) {
          pickupTimeToSend =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        }
      } else {
        pickupTimeToSend =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      }

      request.fields['date'] = dateToSend;
      request.fields['pickupTime'] = pickupTimeToSend;

      print('📋 Doctor Report Request fields: ${request.fields}');
      print(
        '📋 Doctor Report Request fields keys: ${request.fields.keys.toList()}',
      );
      print(
        '📋 ExtraTour field value (BEING SENT): "${request.fields['ExtraTour']}"',
      );

      // Add image file if path is available for doctor report
      if (_selectedImagePath.value.isNotEmpty) {
        final file = File(_selectedImagePath.value);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              file.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
          print('📸 Doctor report image file added: ${file.path}');
        } else {
          print(
            '⚠️ Doctor report image file does not exist: ${_selectedImagePath.value}',
          );
        }
      } else {
        print('⚠️ No image path provided for doctor report');
      }

      print('📋 Doctor Report Request fields: ${request.fields}');
      print('📁 Doctor Report Request files count: ${request.files.length}');

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📤 Doctor Report Response Status: ${response.statusCode}');
      print('📤 Doctor Report Response Body: $responseBody');
      print('📤 Doctor Report Headers: ${response.headers}');

      final tourStateService = Get.find<TourStateService>();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Problem report submitted successfully');
        // Track that samples were submitted
        await tourStateService.incrementSamplesSubmitted();

        // If ExtraTour: 1, mark it as incomplete
        if (isExtraPickup) {
          print('📍 ExtraTour: 1 detected - calling incomplete API');
          await _markExtraPickupIncomplete();
        }
      } else {
        print('⚠️ Problem report submission failed: ${response.statusCode}');
      }

      // Mark doctor as completed
      if (doctorId.isNotEmpty) {
        await tourStateService.markDoctorCompleted(
          doctorId,
          appointmentId: appointmentId,
        );
      }

      // Show success message
      SnackbarUtils.showSuccess(
        title: 'submitted_successfully'.tr,
        message: 'proof_image_submitted_successfully'.tr,
      );

      // Check if tour is complete
      final isTourComplete = await tourStateService.checkAndCompleteTour();

      // Wait a bit for snackbar to be seen, then navigate
      await Future.delayed(const Duration(milliseconds: 800), () {
        if (isTourComplete) {
          // Show tour completion message
          SnackbarUtils.showSuccess(
            title: 'tour_completed'.tr,
            message: 'tour_completed_message'.tr,
          );

          // Navigate back to today's task screen
          Get.offAllNamed(AppRoutes.todaysTask);
        } else {
          // Navigate back to tour details
          Get.offNamedUntil(
            AppRoutes.tourDrList,
            (route) => false,
            arguments: {'taskId': tourStateService.currentTourId},
          );
        }
      });
    } catch (e) {
      print('❌ Error submitting problem report: $e');

      // Mark doctor as completed even on error
      final tourStateService = Get.find<TourStateService>();
      if (doctorId.isNotEmpty) {
        await tourStateService.markDoctorCompleted(
          doctorId,
          appointmentId: appointmentId,
        );
      }

      // Show success message anyway
      SnackbarUtils.showSuccess(
        title: 'submitted_successfully'.tr,
        message: 'proof_image_submitted_successfully'.tr,
      );

      // Check if tour is complete
      final isTourComplete = await tourStateService.checkAndCompleteTour();

      // Wait a bit for snackbar to be seen, then navigate
      await Future.delayed(const Duration(milliseconds: 800), () {
        if (isTourComplete) {
          Get.offAllNamed(AppRoutes.todaysTask);
        } else {
          Get.offNamedUntil(
            AppRoutes.tourDrList,
            (route) => false,
            arguments: {'taskId': tourStateService.currentTourId},
          );
        }
      });
    }
  }

  /// Submit lab (drop point) problem report with image to backend
  Future<void> _submitLabProblemReport(String imageUrl, int driverId) async {
    try {
      // Create multipart request for file upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${NetworkPaths.baseUrl}${NetworkPaths.problemReportLab}'),
      );

      final reportTextToSend = reportText.isNotEmpty
          ? reportText
          : 'Drop point location issue';

      // Get current date and time
      final now = DateTime.now();
      final dateString = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'; // HH:MM

      // Debug: Log what we're about to send
      print('📤 Lab Report Data:');
      print('   driverId: $driverId');
      print('   text: $reportTextToSend');
      print('   image path: ${_selectedImagePath.value}');
      print('   date: $dateString');
      print('   dropTime: $timeString');
      print('   ⚠️ isExtraPickup (member variable): $isExtraPickup');
      print('   ⚠️ ExtraTour should be: ${isExtraPickup ? 1 : 0}');

      // Add form fields
      request.fields['driverId'] = driverId.toString();
      request.fields['text'] = reportTextToSend;
      request.fields['ExtraTour'] = isExtraPickup ? '1' : '0';
      request.fields['date'] = dateString;
      request.fields['dropTime'] = timeString;

      print('📋 Lab Report Request fields: ${request.fields}');
      print(
        '📋 Lab Report Request fields keys: ${request.fields.keys.toList()}',
      );
      print(
        '📋 ExtraTour field value (BEING SENT): "${request.fields['ExtraTour']}"',
      );

      // Add image file if path is available for lab report
      if (_selectedImagePath.value.isNotEmpty) {
        final file = File(_selectedImagePath.value);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              file.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
          print('📸 Lab report image file added: ${file.path}');
        } else {
          print(
            '⚠️ Lab report image file does not exist: ${_selectedImagePath.value}',
          );
        }
      } else {
        print('⚠️ No image path provided for lab report');
      }

      print('📋 Lab Report Request fields: ${request.fields}');
      print('📁 Lab Report Request files count: ${request.files.length}');

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📤 Lab Problem Report Response Status: ${response.statusCode}');
      print('📤 Lab Problem Report Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Lab problem report submitted successfully');
      } else {
        print(
          '⚠️ Lab problem report submission failed: ${response.statusCode}',
        );
      }

      // Show success message
      SnackbarUtils.showSuccess(
        title: 'submitted_successfully'.tr,
        message: 'proof_image_submitted_successfully'.tr,
      );

      // Navigate back to today's task screen with delay
      await Future.delayed(const Duration(milliseconds: 800), () {
        Get.offAllNamed(AppRoutes.todaysTask);
      });
    } catch (e) {
      print('❌ Error submitting lab problem report: $e');

      // Show success message anyway (image saved locally)
      SnackbarUtils.showSuccess(
        title: 'submitted_successfully'.tr,
        message: 'proof_image_submitted_successfully'.tr,
      );

      // Navigate back to today's task screen with delay
      await Future.delayed(const Duration(milliseconds: 800), () {
        Get.offAllNamed(AppRoutes.todaysTask);
      });
    }
  }

  /// Mark extra pickup as incomplete when problem report is submitted
  Future<void> _markExtraPickupIncomplete() async {
    try {
      print('========================================');
      print('MARK EXTRA PICKUP INCOMPLETE API STARTING');
      print('========================================');

      // Get extraPickupId from member variable (should be set from navigation)
      if (extraPickupId == null) {
        print('❌ No extraPickupId found - skipping incomplete API');
        return;
      }

      print('✅ extraPickupId: $extraPickupId');

      // Call extra-pickups incomplete API
      final incompleteUrl = Uri.parse(
        '${NetworkPaths.baseUrl}/api/extra-pickups/$extraPickupId/incomplete',
      );

      print('Incomplete Extra Pickup URL: $incompleteUrl');

      // Get current date
      final now = DateTime.now();
      final currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final body = jsonEncode({
        'status': 'incomplete',
        'incompletedDate': currentDate,
        'reason': reportText, // Use the problem report text as reason
      });

      print('Incomplete Request Body: $body');

      final incompleteResponse = await http.put(
        incompleteUrl,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Incomplete Response Status: ${incompleteResponse.statusCode}');
      print('Incomplete Response Body: ${incompleteResponse.body}');
      print('Incomplete Response Headers: ${incompleteResponse.headers}');

      if (incompleteResponse.statusCode == 200 ||
          incompleteResponse.statusCode == 201) {
        print('✅ EXTRA PICKUP MARKED AS INCOMPLETE SUCCESSFULLY');
        // Try to parse response and verify status
        try {
          final responseData = jsonDecode(incompleteResponse.body);
          print('✅ Incomplete Response Data: $responseData');
          if (responseData['data']?['status'] != null) {
            print('✅ Status from response: ${responseData['data']['status']}');
          }
        } catch (e) {
          print('⚠️ Could not parse incomplete response as JSON: $e');
        }
      } else {
        print('❌ MARK INCOMPLETE API FAILED: ${incompleteResponse.statusCode}');
        // Try to parse error response
        try {
          final errorData = jsonDecode(incompleteResponse.body);
          print('❌ Error Response Data: $errorData');
        } catch (e) {
          print('⚠️ Could not parse error response as JSON: $e');
        }
      }
    } catch (e) {
      print('❌ EXCEPTION IN MARK INCOMPLETE');
      print('Error: $e');
    }
  }
}
