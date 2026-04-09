import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.statusCodes, required this.bodies});

  final List<int> statusCodes;
  final List<String> bodies;
  int attempt = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final index = (attempt < statusCodes.length) ? attempt : statusCodes.length - 1;
    final statusCode = statusCodes[index];
    final body = bodies[index];
    attempt += 1;

    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.clearBaseUrlOverride();
    ApiConstants.skipSecureStorageForTests = true;
  });

  test('DioClient retries transient 503 and succeeds on third attempt', () async {
    final adapter = _FakeHttpClientAdapter(
      statusCodes: [503, 503, 200],
      bodies: [
        jsonEncode({'message': 'Service unavailable'}),
        jsonEncode({'message': 'Service unavailable'}),
        jsonEncode({'data': {'ok': true}}),
      ],
    );
    final client = DioClient();

    // Use adapter directly so we are not dependent on flutter test HTTP interception.
    client.dio.httpClientAdapter = adapter;

    final result = await client.get<Map<String, dynamic>>(
      '/test',
      converter: (data) => (data as Map).cast<String, dynamic>(),
    );

    expect(result.success, true);
    expect(result.data, isNotNull);
    expect(result.data?['data'], isA<Map<String, dynamic>>());
    expect(adapter.attempt, 3);
  });

  test('DioClient does not retry on 400 request and returns failure once', () async {
    final adapter = _FakeHttpClientAdapter(
      statusCodes: [400],
      bodies: [jsonEncode({'message': 'Bad request'})],
    );
    final client = DioClient();
    client.dio.httpClientAdapter = adapter;

    final result = await client.get<Map<String, dynamic>>(
      '/test',
      converter: (data) => (data as Map).cast<String, dynamic>(),
    );

    expect(result.success, false);
    expect(result.statusCode, 400);
    expect(adapter.attempt, 1);
  });
}

