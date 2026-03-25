import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sv_loading_app/core/api/api_client.dart';
import 'package:sv_loading_app/core/api/api_data.dart';
import 'package:sv_loading_app/state/g_management_context_provider.dart';
import 'package:sv_loading_app/state/g_management_provider.dart';
import 'package:sv_loading_app/state/loading_provider.dart';
import 'package:sv_loading_app/core/auth/jwt_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('api_data helpers', () {
    test('unwrapData returns inner data map when wrapped', () {
      final result = unwrapData({
        'success': true,
        'data': {'id': 10, 'name': 'x'}
      });
      expect(result['id'], 10);
      expect(result['name'], 'x');
    });

    test('unwrapDataList supports wrapped list and raw list', () {
      final wrapped = unwrapDataList({
        'data': [
          {'id': 1}
        ]
      });
      final raw = unwrapDataList([
        {'id': 2}
      ]);
      expect(wrapped.length, 1);
      expect(wrapped.first['id'], 1);
      expect(raw.length, 1);
      expect(raw.first['id'], 2);
    });
  });

  group('jwt role extraction', () {
    test('normalizes role list strings to ROLE_ prefix', () {
      final roles = extractRoleClaims({
        'roles': ['LOADING', 'ROLE_SAFETY']
      });
      expect(roles.contains('ROLE_LOADING'), true);
      expect(roles.contains('ROLE_SAFETY'), true);
    });
  });

  group('GManagementProvider canonical status', () {
    test('normalizes pending/empty to NOT_STARTED', () async {
      SharedPreferences.setMockInitialValues({});
      final api = await ApiClient.create('http://localhost');
      final provider = GManagementProvider(api, GManagementContextProvider());
      expect(provider.canonicalSafetyStatus('pending'), 'NOT_STARTED');
      expect(provider.canonicalSafetyStatus(''), 'NOT_STARTED');
      expect(provider.canonicalSafetyStatus(null), 'NOT_STARTED');
      expect(provider.canonicalSafetyStatus('passed'), 'PASSED');
    });
  });

  group('LoadingProvider guards', () {
    test('blocks queue registration without dispatch', () async {
      SharedPreferences.setMockInitialValues({});
      final api = await ApiClient.create('http://localhost');
      final provider = LoadingProvider(api);
      await provider.registerQueue({'warehouseCode': 'KHB'}, online: false);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Dispatch ID'));
    });

    test('blocks start loading without queue context', () async {
      SharedPreferences.setMockInitialValues({});
      final api = await ApiClient.create('http://localhost');
      final provider = LoadingProvider(api);
      await provider.startLoading({
        'dispatchId': 1001,
        'warehouseCode': 'KHB',
      }, online: false);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Queue context'));
    });

    test('blocks end loading without session context', () async {
      SharedPreferences.setMockInitialValues({});
      final api = await ApiClient.create('http://localhost');
      final provider = LoadingProvider(api);
      await provider.endLoading({'remarks': 'done'}, online: false);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Session ID'));
    });
  });
}
