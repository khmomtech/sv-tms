import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/providers/chat_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('sendMessage uses the photo endpoint when an attachment is present', () async {
    late RequestOptions captured;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 7,
                'driverId': 99,
                'senderRole': 'DRIVER',
                'sender': 'driver',
                'message': 'Photo sent',
                'createdAt': '2026-03-19T10:30:00',
                'read': false,
              },
            ),
          );
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final ok = await provider.sendMessage(
      'Photo sent',
      photo: XFile.fromData(
        Uint8List.fromList(const [1, 2, 3]),
        name: 'delivery.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    expect(ok, isTrue);
    expect(captured.path, '/api/driver/chat/99/send-photo');
    expect(captured.data, isA<FormData>());
    expect(provider.messages.single.message, 'Photo sent');
  });

  test('loadMessages sorts server messages and realtime payloads are de-duplicated', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 2,
                    'driverId': 99,
                    'senderRole': 'ADMIN',
                    'sender': 'Dispatch',
                    'message': 'Second',
                    'createdAt': '2026-03-19T10:02:00',
                    'read': true,
                  },
                  <String, dynamic>{
                    'id': 1,
                    'driverId': 99,
                    'senderRole': 'DRIVER',
                    'sender': 'Driver',
                    'message': 'First',
                    'createdAt': '2026-03-19T10:01:00',
                    'read': false,
                  },
                ],
              ),
            );
            return;
          }
          handler.next(options);
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => null,
    );

    await provider.loadMessages();

    expect(provider.messages.map((m) => m.message).toList(), ['First', 'Second']);

    provider.applyRealtimePayload(<String, dynamic>{
      'message': <String, dynamic>{
        'id': 2,
        'driverId': 99,
        'senderRole': 'ADMIN',
        'sender': 'Dispatch',
        'message': 'Second updated',
        'createdAt': '2026-03-19T10:02:00',
        'read': true,
      },
    });
    provider.applyRealtimePayload(<String, dynamic>{
      'message': <String, dynamic>{
        'id': 2,
        'driverId': 99,
        'senderRole': 'ADMIN',
        'sender': 'Dispatch',
        'message': 'Second updated',
        'createdAt': '2026-03-19T10:02:00',
        'read': true,
      },
    });

    expect(provider.messages.length, 2);
    expect(provider.messages.last.message, 'Second updated');
  });

  test('sendVoice uses the voice endpoint and uploads audio', () async {
    late RequestOptions captured;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 10,
                'driverId': 99,
                'senderRole': 'DRIVER',
                'sender': 'driver',
                'message': 'Audio sent',
                'createdAt': '2026-03-19T10:40:00',
                'read': false,
              },
            ),
          );
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final tmpFile = await File('${Directory.systemTemp.path}/test_audio.m4a').writeAsBytes([0, 1, 2, 3]);

    final ok = await provider.sendVoice(tmpFile.path, message: 'Please listen');

    expect(ok, isTrue);
    expect(captured.path, '/api/driver/chat/99/send-voice');
    expect(captured.data, isA<FormData>());
    expect(provider.messages.single.message, 'Audio sent');
  });

  test('requestCall sends a call request to support', () async {
    late RequestOptions captured;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 11,
                'driverId': 99,
                'senderRole': 'DRIVER',
                'sender': 'driver',
                'message': '📞 Call request from driver',
                'createdAt': '2026-03-19T10:42:00',
                'read': false,
              },
            ),
          );
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final ok = await provider.requestCall();

    expect(ok, isTrue);
    expect(captured.path, '/api/driver/chat/99/start-call');
    expect(provider.messages.single.message, '📞 Call request from driver');
  });

  // ── Voice send e2e ──────────────────────────────────────────────────────────

  test('sendVoice returns false and sets errorMessage when server returns 500', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 500,
              data: <String, dynamic>{'message': 'Internal server error'},
            ),
          );
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final tmpFile = await File('${Directory.systemTemp.path}/test_err.m4a').writeAsBytes([0, 1]);
    final ok = await provider.sendVoice(tmpFile.path);

    expect(ok, isFalse);
    expect(provider.errorMessage, 'Failed to upload voice note');
    expect(provider.messages, isEmpty);
  });

  test('sendVoice returns false immediately when path is empty', () async {
    final dio = Dio();
    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final ok = await provider.sendVoice('');
    expect(ok, isFalse);
    expect(provider.messages, isEmpty);
  });

  test('sendVoice appends message to list after successful upload', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 20,
                'driverId': 99,
                'senderRole': 'DRIVER',
                'sender': 'driver',
                'message': '🎤 Voice note',
                'createdAt': '2026-03-19T11:00:00',
                'read': false,
              },
            ),
          );
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final tmpFile = await File('${Directory.systemTemp.path}/test_voice2.m4a').writeAsBytes([0, 1, 2]);
    final ok = await provider.sendVoice(tmpFile.path);

    expect(ok, isTrue);
    expect(provider.messages.length, 1);
    expect(provider.messages.single.message, '🎤 Voice note');
    expect(provider.isSending, isFalse);
  });

  // ── Call request e2e ────────────────────────────────────────────────────────

  test('requestCall falls back to /call-request when /start-call returns 404', () async {
    final paths = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          if (options.path.endsWith('/start-call')) {
            handler.resolve(Response<dynamic>(requestOptions: options, statusCode: 404, data: null));
          } else {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'id': 12,
                  'driverId': 99,
                  'senderRole': 'DRIVER',
                  'sender': 'driver',
                  'message': '📞 Call request from driver',
                  'createdAt': '2026-03-19T11:01:00',
                  'read': false,
                },
              ),
            );
          }
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final ok = await provider.requestCall();

    expect(ok, isTrue);
    expect(paths.first, '/api/driver/chat/99/start-call');
    expect(paths[1], '/api/driver/chat/99/call-request');
    expect(provider.messages.single.message, '📞 Call request from driver');
  });

  test('requestCall returns false and sets errorMessage on persistent failure', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response<dynamic>(requestOptions: options, statusCode: 503, data: null));
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final ok = await provider.requestCall();

    expect(ok, isFalse);
    expect(provider.errorMessage, contains('503'));
    expect(provider.messages, isEmpty);
    expect(provider.isSending, isFalse);
  });

  test('concurrent sendVoice calls are serialised — second returns false immediately', () async {
    final dio = Dio();
    final completer = Completer<void>();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await completer.future; // stall first request
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 30,
                'driverId': 99,
                'senderRole': 'DRIVER',
                'sender': 'driver',
                'message': '🎤 Voice note',
                'createdAt': '2026-03-19T11:05:00',
                'read': false,
              },
            ),
          );
        },
      ),
    );

    final provider = ChatProvider(
      dio: dio,
      pathResolver: (path) => '/api$path',
      driverIdResolver: () async => 99,
      accessTokenResolver: () async => 'token-abc',
    );

    final tmpFile = await File('${Directory.systemTemp.path}/test_conc.m4a').writeAsBytes([0]);
    final first = provider.sendVoice(tmpFile.path);
    final second = await provider.sendVoice(tmpFile.path); // fires while first is pending

    expect(second, isFalse); // rejected because isSending == true
    completer.complete();
    expect(await first, isTrue);
  });
}
