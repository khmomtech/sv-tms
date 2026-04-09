import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/constants/app_colors.dart';
import 'package:tms_driver_app/providers/call_provider.dart';
import 'package:tms_driver_app/services/call_service.dart';

/// Active call screen — driven entirely by [CallProvider].
///
/// Replaces the old UI-only mock.
/// - Real mute / speakerphone via [CallService] (Agora RTC).
/// - Elapsed timer from [CallProvider.elapsedFormatted].
/// - Network quality badge.
/// - Safe hang-up that calls [CallProvider.endCall()].
class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        // If call ended / declined externally, pop automatically.
        if (call.state == CallState.ended ||
            call.state == CallState.declined ||
            call.state == CallState.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F1F5C),
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white70),
                        onPressed: () => _hangUp(context, call),
                      ),
                      const Spacer(),
                      _NetworkQualityBadge(quality: call.networkQuality),
                    ],
                  ),

                  // ── Avatar + name + status ───────────────────────────────
                  Column(
                    children: [
                      _PulsingAvatar(
                        isConnected: call.state == CallState.connected,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        call.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusLabel(call: call),
                    ],
                  ),

                  // ── Controls ─────────────────────────────────────────────
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallControlButton(
                            icon: call.isSpeakerOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            label: call.isSpeakerOn ? 'Speaker' : 'Earpiece',
                            active: call.isSpeakerOn,
                            onTap: () => call.toggleSpeaker(),
                          ),
                          _CallControlButton(
                            icon: call.isLocalMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            label: call.isLocalMuted ? 'Unmute' : 'Mute',
                            active: call.isLocalMuted,
                            onTap: () => call.toggleMute(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Hang-up button
                      GestureDetector(
                        onTap: () => _hangUp(context, call),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hang up',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _hangUp(BuildContext context, CallProvider call) async {
    await call.endCall();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

// ── Pulsing avatar ─────────────────────────────────────────────────────────

class _PulsingAvatar extends StatefulWidget {
  final bool isConnected;
  const _PulsingAvatar({required this.isConnected});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final scale = widget.isConnected ? 1.0 : 1.0 + _ctrl.value * 0.1;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(
                  alpha: 0.08 + (widget.isConnected ? 0 : _ctrl.value * 0.05)),
            ),
            child: const CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white24,
              child: Icon(Icons.headset_mic_rounded,
                  size: 48, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

// ── Status label ────────────────────────────────────────────────────────────

class _StatusLabel extends StatelessWidget {
  final CallProvider call;
  const _StatusLabel({required this.call});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (call.state) {
      case CallState.connecting:
        label = 'Connecting…';
        color = Colors.amber;
        break;
      case CallState.connected:
        label = call.elapsedFormatted;
        color = const Color(0xFF34C759);
        break;
      case CallState.outgoing:
        label = 'Ringing…';
        color = Colors.white60;
        break;
      case CallState.ended:
        label = 'Call ended';
        color = Colors.white38;
        break;
      default:
        label = '–';
        color = Colors.white38;
    }
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w500),
    );
  }
}

// ── Network quality badge ────────────────────────────────────────────────────

class _NetworkQualityBadge extends StatelessWidget {
  final CallNetworkQuality quality;
  const _NetworkQualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (quality) {
      case CallNetworkQuality.excellent:
      case CallNetworkQuality.good:
        icon = Icons.signal_cellular_alt_rounded;
        color = const Color(0xFF34C759);
        tooltip = 'Good connection';
        break;
      case CallNetworkQuality.poor:
        icon = Icons.signal_cellular_alt_2_bar_rounded;
        color = Colors.orange;
        tooltip = 'Poor connection';
        break;
      case CallNetworkQuality.bad:
      case CallNetworkQuality.veryBad:
        icon = Icons.signal_cellular_alt_1_bar_rounded;
        color = Colors.redAccent;
        tooltip = 'Weak connection';
        break;
      case CallNetworkQuality.down:
        icon = Icons.signal_cellular_off_rounded;
        color = Colors.red;
        tooltip = 'No connection';
        break;
      default:
        icon = Icons.signal_cellular_alt_rounded;
        color = Colors.white38;
        tooltip = 'Checking…';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ── Control button ───────────────────────────────────────────────────────────

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
