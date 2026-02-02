import 'dart:convert';

import 'package:doctor_app/core/constants/network_paths.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

class PostWithoutResponse {
  String baseUrl = NetworkPaths.baseUrl;
  Future<Either<String, bool>> postData({
    required String url,
    required Map body,
    Map<String, String>? headers,
  }) async {
    try {
      var response = await http
          .post(
            Uri.parse(baseUrl + url),
            headers: headers ?? {},
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30), // 30 second timeout
            onTimeout: () {
              debugPrint('⏰ POST request timeout after 30 seconds');
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );
      debugPrint(response.body);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return Right(true);
      }

      throw jsonDecode(response.body)["error"];
    } catch (error) {
      return Left(error.toString());
    }
  }
}
