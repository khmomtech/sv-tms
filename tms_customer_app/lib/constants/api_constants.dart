class ApiConstants {
  // Base URL — production default points to the live API gateway.
  // Override for local dev via: --dart-define=API_BASE_URL=http://10.0.2.2:8086/api
  // Android emulator: 10.0.2.2:PORT, iOS simulator: localhost:PORT
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://svtms.svtrucking.biz/api');

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String changePasswordEndpoint = '/api/auth/change-password';
  // Optional endpoints (may not be implemented on all backends)
  static const String passwordResetEndpoint = '/api/auth/forgot-password';

  // Customer endpoints
  // Note: backend controller is mapped to /api/customer (singular).
  static String customerOrders(int customerId) =>
      '/api/customer/$customerId/orders';
  static String customerOrder(int customerId, int orderId) =>
      '/api/customer/$customerId/orders/$orderId';
  static String customerAddresses(int customerId) =>
      '/api/customer/$customerId/addresses';

  // Headers
  static const String contentTypeJson = 'application/json';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
