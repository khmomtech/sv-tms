import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/services/location_service.dart';
import 'package:tms_driver_app/services/web_socket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'driverId': '30211',
    });
    ApiConstants.skipSecureStorageForTests = true;
    await ApiConstants.init();
    WebSocketService.instance.disconnect();
  });

  tearDown(() {
    WebSocketService.instance.disconnect();
  });

  test('sendLocationUpdate falls back to REST when WS is unavailable',
      () async {
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await ApiConstants.setBaseUrlOverride('http://localhost:$port/api');

    final received = Completer<Map<String, dynamic>>();
    unawaited(server.first.then((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response.statusCode = 200;
      await request.response.close();
      received.complete({
        'path': request.uri.path,
        'auth': request.headers.value(HttpHeaders.authorizationHeader),
        'body': jsonDecode(body) as Map<String, dynamic>,
      });
    }));

    final update = LocationUpdate(
      position: Position(
        latitude: 11.5,
        longitude: 104.9,
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 91.0,
        headingAccuracy: 0.0,
        speed: 7.0,
        speedAccuracy: 0.0,
        timestamp: DateTime.now().toUtc(),
        isMocked: false,
      ),
      timestamp: DateTime.now().toUtc(),
      batteryLevel: 80,
    );

    await WebSocketService.instance.sendLocationUpdate(
      update,
      tokenProvider: () async => 'token-abc',
    );

    final req =
        await received.future.timeout(const Duration(seconds: 5));
    expect(req['path'], '/api/driver/location');
    expect(req['auth'], 'Bearer token-abc');
    final body = req['body'] as Map<String, dynamic>;
    expect(body['driverId'], 30211);
    expect(body['source'], 'FLUTTER_ANDROID');
    expect(body['latitude'], 11.5);
    expect(body['longitude'], 104.9);

    await server.close();
  });
}
