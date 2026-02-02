import 'dart:convert';

import 'package:doctor_app/core/constants/network_paths.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

class GetNetwork {
  String baseUrl = NetworkPaths.baseUrl;
  Future<Either<String, T>> getData<T>({
    required String url,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, String>? headers,
  }) async {
    try {
      var response = await http
          .get(Uri.parse(baseUrl + url), headers: headers ?? {})
          .timeout(
            const Duration(seconds: 30), // 30 second timeout
            onTimeout: () {
              debugPrint('⏰ GET request timeout after 30 seconds');
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );
      debugPrint("Response: ${response.body}");
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return Right(fromJson(jsonDecode(response.body)));
      }
      throw jsonDecode(response.body)["message"];
    } catch (error) {
      return left(error.toString());
    }
  }
}
