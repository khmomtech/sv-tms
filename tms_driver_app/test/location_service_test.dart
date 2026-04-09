import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/io_client.dart' as http_io;
import 'package:http/http.dart' as http;
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/services/location_service.dart';
import 'package:tms_driver_app/services/location_service.dart' as svc;
// No custom HttpOverrides; allow real HTTP by clearing overrides in test.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocationService._send posts payload with auth header', () async {
    SharedPreferences.setMockInitialValues({});
    ApiConstants.skipSecureStorageForTests = true;
    await ApiConstants.init();

    // Allow real HTTP requests in this test (TestWidgetsFlutterBinding blocks them by default)
    // Allow real HTTP requests in this test (TestWidgetsFlutterBinding blocks them by default)
    HttpOverrides.global = null;

    // Start local HTTP server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    // Set Api base URL to our local server (include /api so final path matches)
    await ApiConstants.setBaseUrlOverride('http://localhost:$port/api');

    // Persist a JWT-like token with a far-future expiry so no refresh is attempted.
    // Seed both access and tracking tokens because location writes now prefer the
    // tracking session path.
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    final header = base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
    final payload = base64Url.encode(utf8.encode('{"exp": $exp}')).replaceAll('=', '');
    final token = '$header.$payload.';
    await ApiConstants.persistLoginResponse({'token': token, 'refresh_token': 'r'});
    await ApiConstants.saveTrackingSession(
      trackingToken: token,
      sessionId: 'sess-test',
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
    );

    // Configure LocationService identity providers
    final ls = LocationService();
    // Inject IOClient so `package:http` uses dart:io client and connects to our
    // local HTTP server reliably during tests.
    final io = HttpClient();
    final ioClientWrapper = http_io.IOClient(io);
    ls.setHttpClient(ioClientWrapper);
    ls.configure(
      getDriverId: () async => 42,
      getDriverName: () async => 'Test Driver',
      getVehiclePlate: () async => 'TST-1',
    );

    // Prepare a sample Position and LocationUpdate
    final now = DateTime.now().toUtc();
    final pos = Position(
      latitude: 1.23,
      longitude: 4.56,
      accuracy: 5.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 3.0,
      speedAccuracy: 0,
      timestamp: now,
      isMocked: false,
    );
    final upd = svc.LocationUpdate(position: pos, batteryLevel: 50, timestamp: now);

    // Accept a single incoming request; verify headers and body
    final futureReq = server.first.then((HttpRequest req) async {
      try {
        expect(req.method, 'POST');
        expect(req.uri.path, '/api/driver/location/update');
        final auth = req.headers.value(HttpHeaders.authorizationHeader);
        expect(auth, isNotNull);
        expect(auth, contains(token));
        final body = await utf8.decoder.bind(req).join();
        final jsonBody = json.decode(body) as Map<String, dynamic>;
        expect(jsonBody['driverId'], 42);
        expect(jsonBody['vehiclePlate'], 'TST-1');
        expect(jsonBody['sessionId'], 'sess-test');
        req.response.statusCode = 200;
        await req.response.close();
      } catch (e) {
        // propagate to test fail
        rethrow;
      }
    });

    // Call the public send API to send the update
    final ok = await ls.sendUpdate(upd);
    expect(ok, true);

    // Wait for server handling
    await futureReq.timeout(const Duration(seconds: 5));
    await server.close();
  });
}
