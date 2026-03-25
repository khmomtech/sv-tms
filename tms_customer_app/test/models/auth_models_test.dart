import 'package:flutter_test/flutter_test.dart';
import 'package:tms_customer_app/models/auth_models.dart';

void main() {
  test('LoginResponse.fromJson handles null/missing fields safely', () {
    final json = {
      // intentionally omit 'code', 'message', 'token'
      'user': {
        // omit username/email
        'roles': null,
        'permissions': ['read']
      }
    };

    final resp = LoginResponse.fromJson(json);

    expect(resp.code, equals(''));
    expect(resp.message, equals(''));
    expect(resp.token, equals(''));
    expect(resp.user, isNotNull);
    expect(resp.user.username, equals(''));
    expect(resp.user.email, equals(''));
    expect(resp.user.roles, isA<List<String>>());
    expect(resp.user.permissions, contains('read'));
  });
}
