import 'package:doctor_app/core/constants/network_paths.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pending_drop_date_model.dart';

class PendingDropDateRepository {
  static const String baseUrl = NetworkPaths.baseUrl;

  Future<PendingDropDateModel> getPendingDropDates(int driverId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/pendingDropDate?driverId=$driverId'))
          .timeout(const Duration(seconds: 30));

      print('📋 Pending Drop Date API Response Status: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PendingDropDateModel.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load pending drop dates: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching pending drop dates: $e');
      rethrow;
    }
  }
}
