import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/network_paths.dart';

/// Repository for Extra Pickup related APIs
/// Handles accept/reject operations for quick delivery notifications
class ExtraPickupRepository {
  final String baseUrl = NetworkPaths.baseUrl;

  /// Accept an extra pickup request
  ///
  /// [id] - The extra pickup ID to accept
  /// Returns Either<String, Map<String, dynamic>>
  /// Left: Error message, Right: Success response data
  Future<Either<String, Map<String, dynamic>>> acceptExtraPickup({
    required int id,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${NetworkPaths.acceptExtraPickup(id)}');

      print('📤 Accepting extra pickup: $id');
      print('🌐 URL: $url');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      }

      // Handle error response
      final errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['error'] ??
          errorData['message'] ??
          'Failed to accept extra pickup';
      return Left(errorMessage);
    } catch (error) {
      print('❌ Error accepting extra pickup: $error');
      return Left('Network error: ${error.toString()}');
    }
  }

  /// Reject an extra pickup request
  ///
  /// [id] - The extra pickup ID to reject
  /// Returns Either<String, Map<String, dynamic>>
  /// Left: Error message, Right: Success response data
  Future<Either<String, Map<String, dynamic>>> rejectExtraPickup({
    required int id,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${NetworkPaths.rejectExtraPickup(id)}');

      print('📤 Rejecting extra pickup: $id');
      print('🌐 URL: $url');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      }

      // Handle error response
      final errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['error'] ??
          errorData['message'] ??
          'Failed to reject extra pickup';
      return Left(errorMessage);
    } catch (error) {
      print('❌ Error rejecting extra pickup: $error');
      return Left('Network error: ${error.toString()}');
    }
  }

  /// Get pending pickups for a driver
  ///
  /// [driverId] - The driver ID to fetch pending pickups for
  /// Returns Either<String, List<Map<String, dynamic>>>
  /// Left: Error message, Right: List of pending pickups
  Future<Either<String, List<Map<String, dynamic>>>> getPendingPickups({
    required int driverId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl${NetworkPaths.getPendingPickupsByDriver(driverId)}',
      );

      print('📤 Fetching pending pickups for driver: $driverId');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        if (data is List) {
          return Right(List<Map<String, dynamic>>.from(data));
        } else if (data is Map && data.containsKey('data')) {
          final pickups = data['data'];
          if (pickups is List) {
            return Right(List<Map<String, dynamic>>.from(pickups));
          }
        } else if (data is Map && data.containsKey('extraPickups')) {
          final pickups = data['extraPickups'];
          if (pickups is List) {
            return Right(List<Map<String, dynamic>>.from(pickups));
          }
        }

        return Right([]);
      }

      // Handle error response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error'] ??
            errorData['message'] ??
            'Failed to fetch pending pickups';
        return Left(errorMessage);
      } catch (_) {
        return Left('Failed to fetch pending pickups');
      }
    } catch (error) {
      print('❌ Error fetching pending pickups: $error');
      return Left('Network error: ${error.toString()}');
    }
  }

  /// Get a specific extra pickup by ID
  ///
  /// [extraPickupId] - The extra pickup ID to fetch
  /// Returns Either<String, Map<String, dynamic>>
  /// Left: Error message, Right: Extra pickup data
  Future<Either<String, Map<String, dynamic>>> getExtraPickupById({
    required int extraPickupId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/extra-pickups/$extraPickupId');

      print('📤 Fetching extra pickup: $extraPickupId');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        if (data is Map) {
          // If response has 'data' key, use that
          if (data.containsKey('data') && data['data'] is Map) {
            return Right(Map<String, dynamic>.from(data['data']));
          } else {
            return Right(Map<String, dynamic>.from(data));
          }
        }

        return Left('Invalid response format');
      }

      // Handle error response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error'] ??
            errorData['message'] ??
            'Failed to fetch extra pickup';
        return Left(errorMessage);
      } catch (_) {
        return Left('Failed to fetch extra pickup');
      }
    } catch (error) {
      print('❌ Error fetching extra pickup: $error');
      return Left('Network error: ${error.toString()}');
    }
  }
}
