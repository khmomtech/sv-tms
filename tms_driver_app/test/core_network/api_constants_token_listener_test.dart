import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiConstants.skipSecureStorageForTests = true;
    await ApiConstants.init();
  });

  test('saveTokens invokes token update listener with latest access token',
      () async {
    String? observedToken;
    ApiConstants.setTokenUpdateListener((token) async {
      observedToken = token;
    });

    await ApiConstants.saveTokens(
      accessToken: 'new-access-token-123',
      refreshToken: 'refresh-token-123',
    );

    expect(observedToken, 'new-access-token-123');
  });
}

