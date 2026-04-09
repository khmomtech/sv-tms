import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_response.dart';
import 'package:tms_driver_app/core/repositories/dispatch_repository.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';

class _FakeDispatchProvider extends DispatchProvider {
  _FakeDispatchProvider({
    required super.dispatchRepository,
    required this.response,
  });

  final ApiResponse<Map<String, dynamic>> response;
  String? lastDispatchId;
  Map<String, dynamic>? lastPayload;

  @override
  Future<ApiResponse<Map<String, dynamic>>> patchDispatchStatusRequest(
    String dispatchId,
    Map<String, dynamic> body,
  ) async {
    lastDispatchId = dispatchId;
    lastPayload = body;
    return response;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<DispatchRepository> buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    return DispatchRepository(dio: Dio(), prefs: prefs);
  }

  test('updateDispatchStatus propagates API failure for optimistic rollback', () async {
    final repo = await buildRepository();
    final provider = _FakeDispatchProvider(
      dispatchRepository: repo,
      response: ApiResponse.failure('Forbidden', statusCode: 403),
    );

    expect(
      () => provider.updateDispatchStatus('123', 'ARRIVED_LOADING'),
      throwsA(isA<Exception>()),
    );
  });

  test('updateDispatchStatus sends typed payload with optional reason and metadata', () async {
    final repo = await buildRepository();
    final provider = _FakeDispatchProvider(
      dispatchRepository: repo,
      response: ApiResponse.success(<String, dynamic>{'data': {}}),
    );

    await provider.updateDispatchStatus(
      '55',
      'ARRIVED_LOADING',
      reason: 'Driver arrived',
      metadata: {'source': 'mobile', 'lat': 11.5},
    );

    expect(provider.lastDispatchId, '55');
    expect(provider.lastPayload?['status'], 'ARRIVED_LOADING');
    expect(provider.lastPayload?['reason'], 'Driver arrived');
    expect(provider.lastPayload?['metadata'], {'source': 'mobile', 'lat': 11.5});
  });
}
