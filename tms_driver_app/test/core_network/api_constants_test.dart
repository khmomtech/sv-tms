import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.init();
  });

  test('setBaseUrlOverride appends /api when missing', () async {
    await ApiConstants.setBaseUrlOverride('http://example.com');
    expect(ApiConstants.baseUrl, 'http://example.com/api');
  });

  test('clearBaseUrlOverride reverts to some non-empty /api base', () async {
    await ApiConstants.setBaseUrlOverride('http://example.com');
    await ApiConstants.clearBaseUrlOverride();
    expect(ApiConstants.baseUrl.isNotEmpty, true);
    expect(ApiConstants.baseUrl.endsWith('/api'), true);
  });
}
