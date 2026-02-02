import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/network_paths.dart';

class SubmitDropOffRepository {
  final String baseUrl = NetworkPaths.baseUrl;

  /// Upload proof image to server
  Future<Either<String, Map<String, dynamic>>> uploadProofImage({
    required String imagePath,
  }) async {
    try {
      // TODO: Backend image upload endpoint not ready yet
      // For now, return local path as imageUrl
      // Once backend ready, uncomment below code and remove this mock response

      // Mock response with local path
      return Right({
        'success': true,
        'imageUrl': imagePath, // Using local path temporarily
        'message': 'Image saved locally',
      });

      /* REAL IMAGE UPLOAD - Uncomment when backend ready
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/drop-off/upload-image'),
      );

      // Add image file
      var imageFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(imageFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      }

      throw jsonDecode(response.body)["message"] ?? "Failed to upload image";
      */
    } catch (error) {
      return Left(error.toString());
    }
  }

  /// Submit complete drop-off data
  Future<Either<String, Map<String, dynamic>>> submitDropOff({
    required Map<String, dynamic> dropOffData,
  }) async {
    try {
      // REAL API CALL - Using /api/submit endpoint
      final url = Uri.parse(
        '${NetworkPaths.baseUrl}${NetworkPaths.dropPointSubmit}',
      );
      final body = jsonEncode(dropOffData);

      print('� [submitDropOff] Starting submission...');
      print('📤 API URL: $url');
      print(
        '📤 Request Headers: Content-Type: application/json, Accept: application/json',
      );
      print('📤 Request Body: $body');
      print('📤 Data keys: ${dropOffData.keys.toList()}');
      print('📤 Data values: ${dropOffData.values.toList()}');

      var response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('API request timeout after 30 seconds'),
          );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body: ${response.body}');
      print('🔍 [submitDropOff] Response received successfully');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          print('✅ Drop-off submitted successfully');
          return Right(data);
        } catch (e) {
          print('✅ Drop-off submitted successfully (empty response)');
          return Right({
            'success': true,
            'message': 'Drop-off submitted successfully',
          });
        }
      }

      // Handle error responses
      String errorMessage =
          'Failed to submit drop-off (HTTP ${response.statusCode})';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (_) {
        // Response is not JSON, use status code message
        errorMessage =
            'Server returned HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
      }

      print('❌ Error: $errorMessage');
      throw errorMessage;
    } catch (error) {
      print('❌ Exception during submission: $error');
      return Left(error.toString());
    }
  }
}
