import 'dart:convert';

import 'package:doctor_app/core/constants/network_paths.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

class PostWithResponse {
  String baseUrl = NetworkPaths.baseUrl;
  Future<Either<String, T>> postData<T>({
    required String url,
    required Map body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      print('📡 POST Request to: $baseUrl$url');
      print('📤 Request body: $body');

      var response = await http
          .post(
            Uri.parse(baseUrl + url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30), // 30 second timeout
            onTimeout: () {
              print('⏰ Request timeout after 30 seconds');
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('✅ Response parsed successfully');
          return Right(fromJson(jsonResponse));
        } catch (parseError) {
          print('❌ JSON Parse error: $parseError');
          return left('Failed to parse response: $parseError');
        }
      }

      // Handle error responses
      try {
        final errorResponse = jsonDecode(response.body);
        final errorMessage =
            errorResponse["error"] ??
            errorResponse["message"] ??
            'Unknown error occurred';
        print('❌ API Error: $errorMessage');
        return left(errorMessage.toString());
      } catch (e) {
        print('❌ Error parsing error response: ${response.body}');
        return left('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('💥 Network error: $error');
      return left('Network error: $error');
    }
  }
}
