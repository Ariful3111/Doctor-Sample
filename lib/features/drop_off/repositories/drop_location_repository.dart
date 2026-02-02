import 'dart:async';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/network_paths.dart';

/// Repository for Drop Location related APIs
/// Handles fetching drop location info and time validation
class DropLocationRepository {
  final String baseUrl = NetworkPaths.baseUrl;

  /// Get drop location information by name and floor
  ///
  /// [name] - The name of the drop location (e.g., "Second Floor")
  /// [floor] - The floor identifier (e.g., "2")
  /// Returns Either<String, Map<String, dynamic>>
  /// Left: Error message, Right: Drop location data
  Future<Either<String, Map<String, dynamic>>> getDropLocationInfo({
    required String name,
    required String floor,
  }) async {
    try {
      // Build candidate name variants to increase chance of matching backend records
      final candidates = <String>[name.trim()]
        ..addAll([
          name.replaceAll(' ', ''), // e.g. "Second Floor" -> "SecondFloor"
          name.replaceAll(' ', '-'), // e.g. "Second Floor" -> "Second-Floor"
          name.replaceAll(' ', '_'), // e.g. "Second Floor" -> "Second_Floor"
        ])
        ..removeWhere((s) => s.isEmpty);

      // Ensure uniqueness while preserving order
      final uniqueCandidates = <String>[];
      for (final c in candidates) {
        final lower = c.toLowerCase();
        if (!uniqueCandidates.map((e) => e.toLowerCase()).contains(lower)) {
          uniqueCandidates.add(c);
        }
      }

      print('📤 Trying candidate names: $uniqueCandidates for floor: $floor');

      for (final candidate in uniqueCandidates) {
        final encodedName = Uri.encodeComponent(candidate);
        final encodedFloor = Uri.encodeComponent(floor);
        final url = Uri.parse(
          '$baseUrl${NetworkPaths.getDropLocation(encodedName, encodedFloor)}',
        );

        // Retry on server-side 5xx errors up to 3 attempts with a small delay
        int attempts = 0;
        while (attempts < 3) {
          attempts++;
          try {
            print('🌐 GET $url (attempt $attempts)');
            final response = await http
                .get(url, headers: {"Accept": "application/json"})
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () =>
                      throw TimeoutException('Drop location request timed out'),
                );

            print('📥 Response status: ${response.statusCode}');

            if (response.statusCode == 200) {
              print('📥 Response body: ${response.body}');
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              return Right(data);
            }

            if (response.statusCode == 404) {
              print('🔍 Not found for candidate: $candidate');
              // try next candidate name
              break;
            }

            // Server error - retry
            if (response.statusCode >= 500) {
              print('⚠️ Server returned ${response.statusCode} - retrying');
              if (attempts < 3)
                await Future.delayed(const Duration(seconds: 1));
              continue;
            }

            // Handle other non-200 responses
            try {
              final errorData = jsonDecode(response.body);
              final errorMessage =
                  errorData['error'] ??
                  errorData['message'] ??
                  'Failed to fetch drop location info';
              return Left(errorMessage);
            } catch (_) {
              return Left(
                'Failed to fetch drop location: HTTP ${response.statusCode}',
              );
            }
          } catch (e) {
            print('❌ HTTP request failed for $url: $e');
            if (attempts < 3) await Future.delayed(const Duration(seconds: 1));
            continue;
          }
        }
      }

      // Fallback: if floor wasn't '1', try the same candidates with default floor '1'
      if (floor != '1') {
        print('🔁 Fallback: trying floor=1 for candidates');
        for (final candidate in uniqueCandidates) {
          final encodedName = Uri.encodeComponent(candidate);
          final encodedFloor = Uri.encodeComponent('1');
          final url = Uri.parse(
            '$baseUrl${NetworkPaths.getDropLocation(encodedName, encodedFloor)}',
          );

          int attempts = 0;
          while (attempts < 3) {
            attempts++;
            try {
              print('🌐 GET $url (fallback attempt $attempts)');
              final response = await http
                  .get(url, headers: {"Accept": "application/json"})
                  .timeout(
                    const Duration(seconds: 30),
                    onTimeout: () => throw TimeoutException(
                      'Drop location fallback request timed out',
                    ),
                  );

              print('📥 Response status: ${response.statusCode}');

              if (response.statusCode == 200) {
                print('📥 Response body: ${response.body}');
                final data = jsonDecode(response.body) as Map<String, dynamic>;
                return Right(data);
              }

              if (response.statusCode == 404) {
                print('🔍 Fallback not found for candidate: $candidate');
                break;
              }

              if (response.statusCode >= 500) {
                print(
                  '⚠️ Server returned ${response.statusCode} - retrying fallback',
                );
                if (attempts < 3)
                  await Future.delayed(const Duration(seconds: 1));
                continue;
              }

              try {
                final errorData = jsonDecode(response.body);
                final errorMessage =
                    errorData['error'] ??
                    errorData['message'] ??
                    'Failed to fetch drop location info';
                return Left(errorMessage);
              } catch (_) {
                return Left(
                  'Failed to fetch drop location: HTTP ${response.statusCode}',
                );
              }
            } catch (e) {
              print('❌ HTTP request failed for $url: $e');
              if (attempts < 3)
                await Future.delayed(const Duration(seconds: 1));
              continue;
            }
          }
        }
      }

      return Left('Drop location not found');
    } catch (error) {
      print('❌ Error fetching drop location: $error');
      return Left('Network error: ${error.toString()}');
    }
  }

  /// Get drop location by numeric id
  Future<Either<String, Map<String, dynamic>>> getDropLocationById({
    required int id,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${NetworkPaths.getDropLocationById(id)}');
      int attempts = 0;
      while (attempts < 3) {
        attempts++;
        try {
          print('🌐 GET $url (id lookup attempt $attempts)');
          final response = await http
              .get(url, headers: {"Accept": "application/json"})
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () =>
                    throw TimeoutException('Drop location id lookup timed out'),
              );
          print('📥 Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            print('📥 Response body: ${response.body}');
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            return Right(data);
          }

          if (response.statusCode == 404) {
            return Left('Drop location not found');
          }

          if (response.statusCode >= 500) {
            print(
              '⚠️ Server returned ${response.statusCode} - retrying id lookup',
            );
            if (attempts < 3) await Future.delayed(const Duration(seconds: 1));
            continue;
          }

          try {
            final errorData = jsonDecode(response.body);
            final errorMessage =
                errorData['error'] ??
                errorData['message'] ??
                'Failed to fetch drop location info';
            return Left(errorMessage);
          } catch (_) {
            return Left(
              'Failed to fetch drop location: HTTP ${response.statusCode}',
            );
          }
        } catch (e) {
          print('❌ HTTP request failed for $url: $e');
          if (attempts < 3) await Future.delayed(const Duration(seconds: 1));
          continue;
        }
      }

      return Left('Drop location not found');
    } catch (error) {
      print('❌ Error fetching drop location by id: $error');
      return Left('Network error: ${error.toString()}');
    }
  }

  /// Get drop location by name-only endpoint with driver authentication
  Future<Either<String, Map<String, dynamic>>> getDropLocationByName({
    required String name,
    required int driverId,
    required String date,
  }) async {
    try {
      final encodedName = Uri.encodeComponent(name);
      // Build URL with date parameter: /api/droplocations/name/{name}/driver/{id}/{date}
      final url = Uri.parse(
        '$baseUrl${NetworkPaths.getDropLocationByNameAndDriver(encodedName, driverId)}/$date',
      );

      int attempts = 0;
      while (attempts < 3) {
        attempts++;
        try {
          print('🌐 GET $url (name+driver lookup attempt $attempts)');
          final response = await http
              .get(url, headers: {"Accept": "application/json"})
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException(
                  'Drop location name lookup timed out',
                ),
              );
          print('📥 Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            print('📥 Response body: ${response.body}');
            final data = jsonDecode(response.body) as Map<String, dynamic>;

            // Log complete response structure for debugging pending samples
            print('🔍 API Response Structure:');
            print('   Top-level keys: ${data.keys.toList()}');

            // Check for pending samples
            if (data.containsKey('pendingSamples')) {
              print('   ✅ pendingSamples found');
              final pendingSamples = data['pendingSamples'];
              if (pendingSamples is Map) {
                print(
                  '   pendingSamples keys: ${pendingSamples.keys.toList()}',
                );
                print('   pendingSamples content: $pendingSamples');
              }
            } else {
              print('   ⚠️ pendingSamples NOT in response');
            }

            // Check for total samples
            if (data.containsKey('totalSamples')) {
              print('   ✅ totalSamples: ${data['totalSamples']}');
            }

            return Right(data);
          }

          if (response.statusCode == 404) {
            return Left('Drop location not found');
          }

          if (response.statusCode >= 500) {
            print(
              '⚠️ Server returned ${response.statusCode} - retrying name lookup',
            );
            if (attempts < 3) await Future.delayed(const Duration(seconds: 1));
            continue;
          }

          try {
            final errorData = jsonDecode(response.body);
            final errorMessage =
                errorData['error'] ??
                errorData['message'] ??
                'Failed to fetch drop location info';
            return Left(errorMessage);
          } catch (_) {
            return Left(
              'Failed to fetch drop location: HTTP ${response.statusCode}',
            );
          }
        } catch (e) {
          print('❌ HTTP request failed for $url: $e');
          if (attempts < 3) await Future.delayed(const Duration(seconds: 1));
          continue;
        }
      }

      return Left('Drop location not found');
    } catch (error) {
      print('❌ Error fetching drop location by name: $error');
      return Left('Network error: ${error.toString()}');
    }
  }

  /// Verify drop location by both ID and Name
  /// First tries to lookup by ID, then validates against the provided name
  /// This ensures both ID and Name match the backend records
  Future<Either<String, Map<String, dynamic>>> verifyDropLocationByIdAndName({
    required int id,
    required String name,
  }) async {
    try {
      print('🔐 Verifying drop location: ID=$id, Name="$name"');

      // Step 1: Lookup by ID
      final idResult = await getDropLocationById(id: id);

      return idResult.fold(
        (error) {
          print('❌ ID lookup failed: $error');
          return Left(error);
        },
        (data) {
          // Step 2: Validate the name matches
          final backendId = data['id'];
          final backendName = data['name'] ?? '';

          print('✅ ID lookup successful:');
          print('   Backend ID: $backendId, Backend Name: "$backendName"');
          print('   Provided Name: "$name"');

          // Case-insensitive name comparison (also trim whitespace)
          final providedNameLower = name.trim().toLowerCase();
          final backendNameLower = backendName.trim().toLowerCase();

          if (providedNameLower == backendNameLower) {
            print('✅ Name match confirmed!');
            return Right(data);
          } else {
            print(
              '❌ Name mismatch! Expected "$backendNameLower", got "$providedNameLower"',
            );
            return Left(
              'Location name mismatch. Expected "$backendName" but got "$name"',
            );
          }
        },
      );
    } catch (error) {
      print('❌ Error verifying drop location: $error');
      return Left('Verification error: ${error.toString()}');
    }
  }

  /// Check if current time is within drop location operating hours
  ///
  /// [startTime] - Opening time in "HH:mm" format (e.g., "09:00")
  /// [endTime] - Closing time in "HH:mm" format (e.g., "17:00")
  /// Returns true if within operating hours, false otherwise
  bool isWithinOperatingHours({
    required String startTime,
    required String endTime,
  }) {
    try {
      final now = DateTime.now();

      // Parse start time
      final startParts = startTime.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      );

      // Parse end time
      final endParts = endTime.split(':');
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      final end = DateTime(now.year, now.month, now.day, endHour, endMinute);

      // Check if current time is within range
      final isWithin = now.isAfter(start) && now.isBefore(end);

      print('⏰ Time check:');
      print('   Current: ${now.hour}:${now.minute}');
      print('   Start: $startTime, End: $endTime');
      print('   Within hours: $isWithin');

      return isWithin;
    } catch (e) {
      print('❌ Error checking time: $e');
      return false; // Default to false if error
    }
  }

  /// Get a user-friendly message about the operating hours status
  String getOperatingHoursMessage({
    required String startTime,
    required String endTime,
    required bool isWithin,
  }) {
    if (isWithin) {
      return 'Drop location is open (Operating hours: $startTime - $endTime)';
    } else {
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      return 'Drop location is currently closed. Operating hours: $startTime - $endTime (Current time: $currentTime)';
    }
  }
}
