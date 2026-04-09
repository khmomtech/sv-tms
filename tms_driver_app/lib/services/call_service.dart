import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Network quality levels mirroring Agora's QualityType enum.
enum CallNetworkQuality { unknown, excellent, good, poor, bad, veryBad, down }

/// Callback bundle passed to [CallService] consumers.
class CallServiceCallbacks {
  final VoidCallback? onJoinSuccess;
  final void Function(int uid)? onRemoteUserJoined;
  final void Function(int uid)? onRemoteUserLeft;
  final VoidCallback? onConnectionLost;
  final void Function(CallNetworkQuality q)? onNetworkQuality;
  final void Function(String message)? onError;

  const CallServiceCallbacks({
    this.onJoinSuccess,
    this.onRemoteUserJoined,
    this.onRemoteUserLeft,
    this.onConnectionLost,
    this.onNetworkQuality,
    this.onError,
  });
}

/// Singleton wrapper around the Agora RTC engine.
///
/// Usage:
///   await CallService.instance.initialize(appId: 'xxx');
///   await CallService.instance.joinChannel(token: t, channelName: c, uid: 0);
///   await CallService.instance.leaveChannel();
///   await CallService.instance.dispose();
class CallService {
  CallService._();
  static final CallService instance = CallService._();

  RtcEngine? _engine;
  bool _initialized = false;
  bool _inChannel = false;
  CallServiceCallbacks _callbacks = const CallServiceCallbacks();

  // ─── State accessors ───────────────────────────────────────────────────────

  bool get isInitialized => _initialized;
  bool get isInChannel => _inChannel;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialise the Agora engine once per app launch.
  /// Safe to call multiple times – subsequent calls are no-ops.
  Future<void> initialize({required String appId}) async {
    if (_initialized) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
      logConfig: const LogConfig(
        level: LogLevel.logLevelWarn,
        filePath: '',
        fileSizeInKB: 512,
      ),
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
          debugPrint('[Agora] Joined channel: ${conn.channelId} uid=${conn.localUid}');
          _inChannel = true;
          _callbacks.onJoinSuccess?.call();
        },
        onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
          debugPrint('[Agora] Remote user joined: $remoteUid');
          _callbacks.onRemoteUserJoined?.call(remoteUid);
        },
        onUserOffline: (RtcConnection conn, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('[Agora] Remote user left: $remoteUid reason=$reason');
          _callbacks.onRemoteUserLeft?.call(remoteUid);
        },
        onConnectionStateChanged: (RtcConnection conn,
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          if (state == ConnectionStateType.connectionStateDisconnected ||
              state == ConnectionStateType.connectionStateFailed) {
            debugPrint('[Agora] Connection lost: $reason');
            _inChannel = false;
            _callbacks.onConnectionLost?.call();
          }
        },
        onNetworkQuality: (RtcConnection conn, int uid, QualityType txQ,
            QualityType rxQ) {
          final q = _mapQuality(rxQ);
          _callbacks.onNetworkQuality?.call(q);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[Agora] Error $err: $msg');
          _callbacks.onError?.call('[$err] $msg');
        },
      ),
    );

    _initialized = true;
    debugPrint('[CallService] Agora engine initialized');
  }

  /// Register callbacks BEFORE joining a channel.
  void setCallbacks(CallServiceCallbacks callbacks) {
    _callbacks = callbacks;
  }

  /// Request microphone (and camera for video) permissions.
  Future<bool> requestPermissions({bool withCamera = false}) async {
    final mic = await Permission.microphone.request();
    final cam = withCamera ? await Permission.camera.request() : PermissionStatus.granted;
    final granted = mic.isGranted && cam.isGranted;
    if (!granted) {
      debugPrint('[CallService] Permissions denied: mic=${mic.name} cam=${cam.name}');
    }
    return granted;
  }

  // ─── Channel control ───────────────────────────────────────────────────────

  /// Join an Agora channel.
  ///
  /// [uid] = 0 → Agora assigns a random UID.
  /// [enableVideo] = false for voice-only call.
  Future<void> joinChannel({
    required String token,
    required String channelName,
    int uid = 0,
    bool enableVideo = false,
  }) async {
    _assertInitialized();
    if (_inChannel) {
      await leaveChannel();
    }

    // Enable audio (and optional video) before joining
    await _engine!.enableAudio();
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQualityStereo,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    if (enableVideo) {
      await _engine!.enableVideo();
    }

    // Default to earpiece for privacy; caller can switch to speaker after join.
    await _engine!.setEnableSpeakerphone(false);

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        publishCameraTrack: enableVideo,
        autoSubscribeAudio: true,
        autoSubscribeVideo: enableVideo,
      ),
    );
  }

  /// Leave the current channel gracefully.
  Future<void> leaveChannel() async {
    if (_engine == null || !_inChannel) return;
    await _engine!.leaveChannel();
    _inChannel = false;
    debugPrint('[CallService] Left channel');
  }

  // ─── In-call controls ──────────────────────────────────────────────────────

  /// Mute or unmute local microphone.
  Future<void> setLocalAudioMuted(bool muted) async {
    _assertInitialized();
    await _engine!.muteLocalAudioStream(muted);
    debugPrint('[CallService] Local audio muted=$muted');
  }

  /// Route audio to speaker (true) or earpiece (false).
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    _assertInitialized();
    await _engine!.setEnableSpeakerphone(enabled);
    debugPrint('[CallService] Speakerphone=$enabled');
  }

  /// Adjust local playback volume (0–400, default 100).
  Future<void> setPlaybackVolume(int volume) async {
    _assertInitialized();
    await _engine!.adjustPlaybackSignalVolume(volume.clamp(0, 400));
  }

  // ─── Teardown ──────────────────────────────────────────────────────────────

  /// Release Agora engine resources. Call when user logs out.
  Future<void> dispose() async {
    if (_engine == null) return;
    if (_inChannel) await leaveChannel();
    _engine!.unregisterEventHandler(RtcEngineEventHandler());
    await _engine!.release();
    _engine = null;
    _initialized = false;
    _callbacks = const CallServiceCallbacks();
    debugPrint('[CallService] Engine released');
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _assertInitialized() {
    if (!_initialized || _engine == null) {
      throw StateError(
          '[CallService] Not initialized. Call initialize() first.');
    }
  }

  static CallNetworkQuality _mapQuality(QualityType q) {
    switch (q) {
      case QualityType.qualityExcellent:
        return CallNetworkQuality.excellent;
      case QualityType.qualityGood:
        return CallNetworkQuality.good;
      case QualityType.qualityPoor:
        return CallNetworkQuality.poor;
      case QualityType.qualityBad:
        return CallNetworkQuality.bad;
      case QualityType.qualityVbad:
        return CallNetworkQuality.veryBad;
      case QualityType.qualityDown:
        return CallNetworkQuality.down;
      default:
        return CallNetworkQuality.unknown;
    }
  }
}
