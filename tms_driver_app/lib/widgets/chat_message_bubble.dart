import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tms_driver_app/core/constants/app_colors.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/chat_message_model.dart';
import 'package:tms_driver_app/screens/shipment/fullscreen_image_viewer1.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final String? time;
  final bool? isRead;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.time,
    this.isRead,
  });

  @override
  _ChatMessageBubbleState createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  // ── Inline audio player state ────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _doneSub;

  @override
  void initState() {
    super.initState();
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    _doneSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _doneSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(String url) async {
    if (_isLoadingAudio) return;
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    if (mounted) setState(() => _isLoadingAudio = true);
    await _player.play(UrlSource(url));
    if (mounted) setState(() { _isLoadingAudio = false; _isPlaying = true; });
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isDriver => widget.message.senderRole.toUpperCase() == 'DRIVER';

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final photoUrl = _extractPhotoUrl(message.message);
    final voiceUrl = _extractVoiceUrl(message.message);
    final videoUrl = _extractVideoUrl(message.message);
    final locationParts = _extractLocation(message.message);
    final isCallRequest = _isCallRequest(message.message);
    final messageText = _stripMediaUrl(message.message);
    final hasImage = message.localImageBytes != null || photoUrl != null;
    final bubbleTextColor = _isDriver ? Colors.white : const Color(0xFF20304A);
    final bubbleColor = _isDriver ? AppColors.primary : const Color(0xFFFFFFFF);

    return Row(
      mainAxisAlignment:
          _isDriver ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!_isDriver) ...[
          _SupportAvatar(icon: photoUrl != null ? Icons.photo_camera_rounded : Icons.headset_mic_rounded),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                _isDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(_isDriver ? 18 : 4),
                    bottomRight: Radius.circular(_isDriver ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF20304A).withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (messageText.isNotEmpty)
                        Text(
                          messageText,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.35,
                            color: bubbleTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      if (hasImage) ...[
                        if (messageText.isNotEmpty) const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showPreview(context, photoUrl),
                          child: Container(
                            width: 220,
                            decoration: BoxDecoration(
                              color: _isDriver
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFF2F5F8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isDriver
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFD8E1EA),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.bottomLeft,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: _buildPreviewImage(photoUrl),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Tap to preview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (voiceUrl != null) ...[
                const SizedBox(height: 6),
                _VoicePlayerWidget(
                  url: voiceUrl,
                  isDriver: _isDriver,
                  isPlaying: _isPlaying,
                  isLoading: _isLoadingAudio,
                  position: _position,
                  total: _total,
                  onToggle: () => _togglePlayback(voiceUrl),
                  fmtDur: _fmtDur,
                ),
              ],
              if (videoUrl != null) ...[
                const SizedBox(height: 6),
                _VideoPreviewCard(url: videoUrl, isDriver: _isDriver),
              ],
              if (locationParts != null) ...[
                const SizedBox(height: 6),
                _LocationCard(
                  lat: double.tryParse(locationParts[0]) ?? 0,
                  lng: double.tryParse(locationParts[1]) ?? 0,
                  address: locationParts[2],
                  isDriver: _isDriver,
                ),
              ],
              if (isCallRequest) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDriver ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFF8E9DF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '📞 Call request',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isDriver ? Colors.white : const Color(0xFFB04E25),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.time ?? '',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8B99AA),
                    ),
                  ),
                  if (_isDriver && widget.isRead != null) ...[
                    const SizedBox(width: 3),
                    if (message.isPending) ...[
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          valueColor: AlwaysStoppedAnimation(Color(0xFFBCC5D8)),
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: widget.isRead == true
                          ? AppColors.primary
                          : const Color(0xFFBCC5D8),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_isDriver) ...[
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFF9D0B5),
            child: Icon(Icons.person, color: Color(0xFF2B335D), size: 20),
          ),
        ],
      ],
    );
  }

  String? _extractPhotoUrl(String message) {
    final marker = '📷 ';
    final start = message.indexOf(marker);
    if (start < 0) return null;
    final raw = message.substring(start + marker.length);
    final end = raw.indexOf('\n');
    var url = (end >= 0 ? raw.substring(0, end) : raw).trim();
    if (url.startsWith('/')) url = '${ApiConstants.imageUrl}$url';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return null;
  }

  String? _extractVoiceUrl(String message) {
    final marker = '🔊 ';
    final start = message.indexOf(marker);
    if (start < 0) return null;
    final raw = message.substring(start + marker.length);
    final end = raw.indexOf('\n');
    var url = (end >= 0 ? raw.substring(0, end) : raw).trim();
    if (url.startsWith('/')) url = '${ApiConstants.imageUrl}$url';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return null;
  }

  String? _extractVideoUrl(String message) {
    final marker = '🎬 ';
    final start = message.indexOf(marker);
    if (start < 0) return null;
    final raw = message.substring(start + marker.length);
    final end = raw.indexOf('\n');
    var url = (end >= 0 ? raw.substring(0, end) : raw).trim();
    if (url.startsWith('/')) url = '${ApiConstants.imageUrl}$url';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return null;
  }

  /// Returns [lat, lng, address] or null.
  List<String>? _extractLocation(String message) {
    const marker = '📍 ';
    final start = message.indexOf(marker);
    if (start < 0) return null;
    final raw = message.substring(start + marker.length).trim();
    final pipeIdx = raw.indexOf('|');
    if (pipeIdx < 0) return null;
    final coords = raw.substring(0, pipeIdx).trim();
    final address = raw.substring(pipeIdx + 1).trim();
    final parts = coords.split(',');
    if (parts.length < 2) return null;
    return [parts[0].trim(), parts[1].trim(), address];
  }

  bool _isCallRequest(String message) {
    return message.toLowerCase().contains('📞 call request');
  }

  String _stripMediaUrl(String message) {
    // Strip each media marker + everything after it on that "token" (up to newline or end).
    // We strip based on the raw marker segment, not the resolved URL, so relative paths
    // (/uploads/...) are also removed correctly.
    String stripped = message;
    for (final marker in ['📷 ', '🔊 ', '🎬 ']) {
      final idx = stripped.indexOf(marker);
      if (idx >= 0) {
        // Remove from marker to end of that segment (newline or string end)
        final after = stripped.indexOf('\n', idx);
        stripped = (stripped.substring(0, idx) +
                (after >= 0 ? stripped.substring(after) : ''))
            .trim();
      }
    }
    // Location: remove entire 📍 … segment
    final locIdx = stripped.indexOf('📍 ');
    if (locIdx >= 0) {
      final after = stripped.indexOf('\n', locIdx);
      stripped = (stripped.substring(0, locIdx) +
              (after >= 0 ? stripped.substring(after) : ''))
          .trim();
    }
    if (_isCallRequest(stripped)) {
      stripped = stripped.replaceAll(RegExp(r'📞 call request', caseSensitive: false), '').trim();
    }
    return stripped;
  }

  Widget _buildPreviewImage(String? photoUrl) {
    if (widget.message.localImageBytes != null) {
      return Image.memory(
        widget.message.localImageBytes!,
        width: 220,
        height: 180,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      photoUrl!,
      width: 220,
      height: 180,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: 220,
          height: 180,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 220,
          height: 180,
          color: const Color(0xFFF1F5FB),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 42,
            color: Color(0xFF94A0B8),
          ),
        );
      },
    );
  }

  Future<void> _showPreview(BuildContext context, String? photoUrl) async {
    if (widget.message.localImageBytes == null && photoUrl == null) return;

    final nav = Navigator.of(context);

    if (widget.message.localImageBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/chat_preview_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(widget.message.localImageBytes!);
      if (!mounted) return;
      nav.push(MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(imageUrls: [file.path], initialIndex: 0, isLocal: true),
      ));
      return;
    }

    if (photoUrl != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(imageUrls: [photoUrl], initialIndex: 0, isLocal: false),
      ));
    }
  }
}


class _SupportAvatar extends StatelessWidget {
  final IconData icon;

  const _SupportAvatar({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFF0F3F7),
      child: Icon(icon, color: const Color(0xFF6E7B97), size: 18),
    );
  }
}

// ── Inline video preview card ────────────────────────────────────────────────

class _VideoPreviewCard extends StatefulWidget {
  final String url;
  final bool isDriver;

  const _VideoPreviewCard({required this.url, required this.isDriver});

  @override
  State<_VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<_VideoPreviewCard> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenVideoPlayer(url: widget.url),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDriver ? Colors.white : AppColors.primary;
    final bg = widget.isDriver
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFEBF2FA);

    return GestureDetector(
      onTap: _openFullscreen,
      child: Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_ready)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: _ctrl.value.aspectRatio,
                  child: VideoPlayer(_ctrl),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.videocam_rounded, color: accent, size: 36),
              ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
            ),
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Tap to play', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  const _FullscreenVideoPlayer({required this.url});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _ctrl.play();
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _ready
            ? GestureDetector(
                onTap: () {
                  if (_ctrl.value.isPlaying) {
                    _ctrl.pause();
                  } else {
                    _ctrl.play();
                  }
                  setState(() {});
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _ctrl.value.aspectRatio,
                      child: VideoPlayer(_ctrl),
                    ),
                    if (!_ctrl.value.isPlaying)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                      ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ── Location card ─────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final double lat;
  final double lng;
  final String address;
  final bool isDriver;

  const _LocationCard({
    required this.lat,
    required this.lng,
    required this.address,
    required this.isDriver,
  });

  Future<void> _openMaps() async {
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = isDriver ? Colors.white : AppColors.primary;
    final bg = isDriver
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFEBF2FA);
    final subColor = isDriver
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF6B7C93);

    return GestureDetector(
      onTap: _openMaps,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, color: const Color(0xFFFF9500), size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.isNotEmpty ? address : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to open in Maps',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded, size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}

// ── Inline voice player (Telegram-style) ────────────────────────────────────

class _VoicePlayerWidget extends StatelessWidget {
  final String url;
  final bool isDriver;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration total;
  final VoidCallback onToggle;
  final String Function(Duration) fmtDur;

  const _VoicePlayerWidget({
    required this.url,
    required this.isDriver,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.total,
    required this.onToggle,
    required this.fmtDur,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDriver ? Colors.white : AppColors.primary;
    final bg = isDriver
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFEBF2FA);
    final trackBg = isDriver
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFFD0DCF0);
    final totalSecs = total.inSeconds > 0 ? total.inSeconds : 1;
    final progress = position.inSeconds / totalSecs;
    final timeLabel = isPlaying || position.inSeconds > 0
        ? fmtDur(position)
        : fmtDur(total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / pause button
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accent),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: accent,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Waveform bar + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress track
              SizedBox(
                width: 120,
                height: 4,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: trackBg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: accent.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
