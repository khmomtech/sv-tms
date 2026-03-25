import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  dio.options.baseUrl = 'http://192.168.1.60:8080';
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);

  try {
    final res = await dio.get('/api/driver/dispatches/me/pending', queryParameters: {
      'sort': 'startTime,DESC',
      'page': 0,
      'size': 100,
    });
    print('status: ${res.statusCode}');
    print('data: ${res.data}');
  } on DioException catch (e) {
    print('DioException: ${e.message}');
    print('type: ${e.type}');
    print('osError: ${e.error}');
    print('response: ${e.response?.statusCode} ${e.response?.data}');
  }
}
