import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/services/call_service.dart';
import 'package:tms_driver_app/utils/notification_helper.dart';

// ─── State machine ────────────────────────────────────────────────────────────

/// Full lifecycle of a call.
enum CallState {
  /// No active or pending call.
  idle,

  /// Driver placed a call request; waiting for support to accept.
  outgoing,

  /// An incoming CALL_REQUEST arrived from support; ring timer running.
  incoming,

  /// Both sides accepted; Agora channel is being joined.
  connecting,

  /// Both parties are in the Agora channel and audio is live.
  connected,

  /// Call ended normally (either side hung up).
  ended,

  /// Remote user declined or ring timed out.
  declined,

  /// Agora or network error mid-call.
  error,
}

// ─── Token response ───────────────────────────────────────────────────────────

class CallTokenResponse {
  final String agoraToken;
  final String channelName;
  final int uid;
  final String appId;

  const CallTokenResponse({
    required this.agoraToken,
    required this.channelName,
    required this.uid,
    required this.appId,
  });

  factory CallTokenResponse.fromJson(Map<String, dynamic> json) =>
      CallTokenResponse(
        agoraToken: json['agoraToken'] as String,
        channelName: json['channelName'] as String,
        uid: (json['uid'] as num).toInt(),
        appId: json['appId'] as String,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Manages the complete voice-call lifecycle.
///
/// Flow (incoming):
///   STOMP CALL_REQUEST → [handleIncomingCall] → state=incoming
///   Driver taps Answer → [acceptCall] → fetches Agora token → joins channel → state=connected
///   Either party taps End → [endCall] → leaves channel → state=ended
///
/// Flow (outgoing):
///   Driver taps Call button → [startOutgoingCall] → POST /start-call → state=outgoing
///   Support accepts → STOMP CALL_ACCEPTED arrives → [handleCallAccepted] → joins channel → state=connected
///
/// Ring timeout: 45 s with no answer → [_autoDecline] → state=declined
class CallProvider with ChangeNotifier {
  final Dio _http;
  final String Function(String) _resolvePath;
  final Future<int?> Function() _resolveDriverIdFn;
  final CallService _callService;

  CallProvider({
    DioClient? dioClient,
    Dio? dio,
    String Function(String)? pathResolver,
    Future<int?> Function()? driverIdResolver,
    CallService? callService,
  })  : _http = dio ?? (dioClient ?? DioClient()).dio,
        _resolvePath =
            pathResolver ?? (dioClient ?? DioClient()).resolvePath,
        _resolveDriverIdFn =
            driverIdResolver ?? _defaultDriverIdResolver,
        _callService = callService ?? CallService.instance;

  // ─── State ─────────────────────────────────────────────────────────────────

  CallState _state = CallState.idle;
  String? _channelName;
  String? _callerName;
  String? _errorMessage;
  int _remoteUid = 0;
  bool _isLocalMuted = false;
  bool _isSpeakerOn = true;
  int _elapsedSeconds = 0;
  CallNetworkQuality _networkQuality = CallNetworkQuality.unknown;

  Timer? _elapsedTimer;
  Timer? _ringTimeoutTimer;

  // ─── Getters ───────────────────────────────────────────────────────────────

  CallState get state => _state;
  String? get channelName => _channelName;
  String get callerName => _callerName ?? 'Support Team';
  String? get errorMessage => _errorMessage;
  bool get isLocalMuted => _isLocalMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  int get elapsedSeconds => _elapsedSeconds;
  int get remoteUid => _remoteUid;
  CallNetworkQuality get networkQuality => _networkQuality;

  bool get isActive =>
      _state == CallState.connecting || _state == CallState.connected;
  bool get hasActiveOrPendingCall =>
      _state != CallState.idle &&
      _state != CallState.ended &&
      _state != CallState.declined &&
      _state != CallState.error;

  String get elapsedFormatted {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Incoming call ─────────────────────────────────────────────────────────

  /// Called by ChatProvider when a CALL_REQUEST frame arrives.
  void handleIncomingCall({
    required String channelName,
    String callerName = 'Support Team',
  }) {
    if (hasActiveOrPendingCall) {
      debugPrint('[CallProvider] Ignoring CALL_REQUEST — already in call');
      return;
    }

    _channelName = channelName;
    _callerName = callerName;
    _setState(CallState.incoming);

    // Auto-decline after 45 s if driver does not answer.
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(const Duration(seconds: 45), _autoDecline);
    debugPrint('[CallProvider] Incoming call on channel=$channelName, auto-decline in 45s');
  }

  /// Driver taps "Answer" on IncomingCallScreen.
  Future<void> acceptCall() async {
    if (_state != CallState.incoming) return;
    _ringTimeoutTimer?.cancel();
    _setState(CallState.connecting);
    // Dismiss the heads-up call notification (shown when app was backgrounded/killed).
    NotificationHelper.cancelCallNotification();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');

      // Fetch Agora token from backend.
      final tokenResp = await _fetchCallToken(driverId);

      // Initialize Agora if needed.
      await _callService.initialize(appId: tokenResp.appId);

      // Request mic permission.
      final hasPermission = await _callService.requestPermissions();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      // Register callbacks.
      _callService.setCallbacks(CallServiceCallbacks(
        onJoinSuccess: _onJoinSuccess,
        onRemoteUserJoined: _onRemoteUserJoined,
        onRemoteUserLeft: _onRemoteUserLeft,
        onConnectionLost: _onConnectionLost,
        onNetworkQuality: (q) {
          _networkQuality = q;
          notifyListeners();
        },
        onError: (msg) {
          _errorMessage = msg;
          _setState(CallState.error);
        },
      ));

      // Join channel.
      await _callService.joinChannel(
        token: tokenResp.agoraToken,
        channelName: tokenResp.channelName,
        uid: tokenResp.uid,
      );

      // Set speakerphone on for calls.
      await _callService.setSpeakerphoneEnabled(true);
    } catch (e) {
      debugPrint('[CallProvider] acceptCall failed: $e');
      _errorMessage = e.toString();
      _setState(CallState.error);
    }
  }

  // ─── Outgoing call ─────────────────────────────────────────────────────────

  /// Driver-initiated call request (from chat screen).
  ///
  /// The HTTP POST to /start-call is already made by [ChatProvider.requestCall].
  /// This method only transitions state and starts the ring timeout so we do
  /// not create a duplicate call session.
  void startOutgoingCall() {
    if (hasActiveOrPendingCall) return;
    _setState(CallState.outgoing);

    // Ring timeout: auto-decline if support does not answer within 45 s.
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(const Duration(seconds: 45), _autoDecline);
    debugPrint('[CallProvider] Outgoing call placed, waiting 45s for answer');
  }

  /// Called when support sends CALL_ACCEPTED via STOMP.
  Future<void> handleCallAccepted({required String channelName}) async {
    if (_state != CallState.outgoing) return;
    _ringTimeoutTimer?.cancel();
    _channelName = channelName;
    _setState(CallState.connecting);

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');

      final tokenResp = await _fetchCallToken(driverId);
      await _callService.initialize(appId: tokenResp.appId);
      final hasPermission = await _callService.requestPermissions();
      if (!hasPermission) throw Exception('Microphone permission denied');

      _callService.setCallbacks(CallServiceCallbacks(
        onJoinSuccess: _onJoinSuccess,
        onRemoteUserJoined: _onRemoteUserJoined,
        onRemoteUserLeft: _onRemoteUserLeft,
        onConnectionLost: _onConnectionLost,
        onNetworkQuality: (q) {
          _networkQuality = q;
          notifyListeners();
        },
        onError: (msg) {
          _errorMessage = msg;
          _setState(CallState.error);
        },
      ));

      await _callService.joinChannel(
        token: tokenResp.agoraToken,
        channelName: channelName,
        uid: tokenResp.uid,
      );
      await _callService.setSpeakerphoneEnabled(true);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(CallState.error);
    }
  }

  // ─── In-call controls ──────────────────────────────────────────────────────

  Future<void> toggleMute() async {
    _isLocalMuted = !_isLocalMuted;
    await _callService.setLocalAudioMuted(_isLocalMuted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _callService.setSpeakerphoneEnabled(_isSpeakerOn);
    notifyListeners();
  }

  // ─── End call ──────────────────────────────────────────────────────────────

  /// Either party hangs up.
  Future<void> endCall() async {
    if (_state == CallState.idle) return;

    _ringTimeoutTimer?.cancel();
    _elapsedTimer?.cancel();

    try {
      await _callService.leaveChannel();

      final driverId = await _resolveDriverIdFn();
      if (driverId != null) {
        final path = _resolvePath('/driver/chat/$driverId/end-call');
        await _http.post(path).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('[CallProvider] endCall cleanup error (ignored): $e');
    } finally {
      _reset(CallState.ended);
    }
  }

  /// Driver declines an incoming call.
  Future<void> declineCall() async {
    _ringTimeoutTimer?.cancel();
    // Dismiss the heads-up call notification.
    NotificationHelper.cancelCallNotification();
    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId != null) {
        final path = _resolvePath('/driver/chat/$driverId/decline-call');
        await _http.post(path).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Best-effort.
    } finally {
      _reset(CallState.declined);
    }
  }

  // ─── Agora callbacks ───────────────────────────────────────────────────────

  void _onJoinSuccess() {
    _setState(CallState.connected);
    _startElapsedTimer();
    debugPrint('[CallProvider] Call connected');
  }

  void _onRemoteUserJoined(int uid) {
    _remoteUid = uid;
    if (_state == CallState.connecting) {
      _setState(CallState.connected);
      _startElapsedTimer();
    }
    notifyListeners();
  }

  void _onRemoteUserLeft(int uid) {
    debugPrint('[CallProvider] Remote user $uid left → ending call');
    endCall();
  }

  void _onConnectionLost() {
    debugPrint('[CallProvider] Agora connection lost');
    _errorMessage = 'Connection lost';
    _setState(CallState.error);
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  void _autoDecline() {
    debugPrint('[CallProvider] Ring timeout — auto decline');
    _reset(CallState.declined);
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedSeconds = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void _setState(CallState next) {
    _state = next;
    notifyListeners();
  }

  void _reset(CallState finalState) {
    _ringTimeoutTimer?.cancel();
    _elapsedTimer?.cancel();
    _state = finalState;
    _channelName = null;
    _remoteUid = 0;
    _isLocalMuted = false;
    _isSpeakerOn = true;
    _elapsedSeconds = 0;
    _networkQuality = CallNetworkQuality.unknown;
    notifyListeners();

    // Transition back to idle after 2 seconds so UI can show end state briefly.
    Timer(const Duration(seconds: 2), () {
      if (_state == finalState) {
        _state = CallState.idle;
        _errorMessage = null;
        _callerName = null;
        notifyListeners();
      }
    });
  }

  /// POST /driver/chat/{id}/call-token — backend creates session + returns Agora token.
  Future<CallTokenResponse> _fetchCallToken(int driverId) async {
    final path = _resolvePath('/driver/chat/$driverId/call-token');
    final resp = await _http.post(path);
    if (resp.statusCode != 200 || resp.data == null) {
      throw Exception('Failed to fetch call token (${resp.statusCode})');
    }
    final data = resp.data as Map<String, dynamic>;
    return CallTokenResponse.fromJson(data);
  }

  // ─── Defaults ──────────────────────────────────────────────────────────────

  static Future<int?> _defaultDriverIdResolver() async {
    final id = await ApiConstants.getDriverId();
    if (id != null) return id;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('driverId');
    return str != null ? int.tryParse(str) : null;
  }

  @override
  void dispose() {
    _ringTimeoutTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }
}
