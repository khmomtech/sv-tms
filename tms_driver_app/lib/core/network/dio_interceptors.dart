import 'package:dio/dio.dart';
import 'api_constants.dart';

/// Provides a configured set of Dio interceptors:
///  - Auth header injection
///  - Automatic token refresh and single retry on 401
///  - Basic error mapping (HTTP status -> readable message)
class DioInterceptorFactory {
  static InterceptorsWrapper authAndError() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final headers = await ApiConstants.getHeaders();
        headers.forEach((k, v) => options.headers.putIfAbsent(k, () => v));
        handler.next(options);
      },
      onError: (error, handler) async {
        // Attempt silent refresh on 401 once
        if (error.response?.statusCode == 401) {
          final refreshed = await ApiConstants.refreshAccessToken();
            if (refreshed != null && refreshed.isNotEmpty) {
              final retry = error.requestOptions;
              // Inject new header
              retry.headers['Authorization'] = 'Bearer $refreshed';
              try {
                final cloneResponse = await Dio().fetch<dynamic>(retry);
                handler.resolve(cloneResponse);
                return;
              } catch (e) {
                // fall through to normal error mapping
              }
            }
        }

        // Map known status codes to user-friendly messages
        final status = error.response?.statusCode;
        String mappedMessage;
        switch (status) {
          case 400:
            mappedMessage = 'Bad request';
            break;
          case 401:
            mappedMessage = 'Unauthorized - please login again';
            break;
          case 403:
            mappedMessage = 'Forbidden - insufficient permissions';
            break;
          case 404:
            mappedMessage = 'Not found';
            break;
          case 500:
            mappedMessage = 'Server error - try later';
            break;
          default:
            mappedMessage = 'Network error';
        }
        handler.next(error.copyWith(message: mappedMessage));
      },
    );
  }
}
