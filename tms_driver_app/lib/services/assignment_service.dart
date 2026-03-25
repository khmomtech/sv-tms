import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/network/api_constants.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  static Future<AssignmentModel?> getDriverAssignment(int driverId) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final token = await ApiConstants.getAccessToken();
        if (token == null) {
          print('No access token available');
          return null;
        }

        http.Response? response;
        final headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-Request-ID': 'driver-app-${DateTime.now().millisecondsSinceEpoch}',
        };
        final uris = <Uri>[
          Uri.parse('${ApiConstants.baseUrl}/driver/current-assignment'),
          Uri.parse(
              '${ApiConstants.baseUrl}/driver/$driverId/current-assignment'),
        ];
        for (final uri in uris) {
          final res = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          if (res.statusCode == 200 || res.statusCode == 404) {
            response = res;
            break;
          }
          if (res.statusCode == 401 || res.statusCode == 403) {
            response = res;
            break;
          }
        }
        if (response == null) {
          throw Exception('No reachable assignment endpoint');
        }

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['data'] != null) {
            return AssignmentModel.fromJson(data['data']);
          }
          print('Assignment API returned success=false or null data');
          return null;
        } else if (response.statusCode == 404) {
          // No assignment found - valid state
          return null;
        } else if (response.statusCode >= 500) {
          // Server error - retry
          throw Exception('Server error: ${response.statusCode}');
        } else {
          // Client error - don't retry
          print('Client error fetching assignment: ${response.statusCode}');
          return null;
        }
      } on TimeoutException catch (e) {
        print('Request timeout (attempt ${retryCount + 1}/$maxRetries): $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(
              initialDelay * (1 << retryCount)); // Exponential backoff
        }
      } on SocketException catch (e) {
        print('Network error (attempt ${retryCount + 1}/$maxRetries): $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(initialDelay * (1 << retryCount));
        }
      } catch (e) {
        print('Error fetching driver assignment: $e');
        return null;
      }
    }

    print('Failed to fetch assignment after $maxRetries attempts');
    return null;
  }
}
