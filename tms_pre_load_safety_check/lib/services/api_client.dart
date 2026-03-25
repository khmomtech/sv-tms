import 'package:dio/dio.dart';

import 'auth_service.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);
const enableHttpLogging =
    bool.fromEnvironment('HTTP_LOGGING', defaultValue: false);

class ApiClient {
  ApiClient(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 25),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    if (enableHttpLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          logPrint: (obj) => _debugLog(obj.toString()),
        ),
      );
    }
  }

  final AuthService _authService;
  late final Dio _dio;

  Dio get dio => _dio;

  void _debugLog(String message) {
    // Keep logging simple and scoped for optional HTTP logging.
    // You can pipe this to your own logger if needed.
    // ignore: avoid_print
    print('[API] $message');
  }
}
