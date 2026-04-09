import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/call_provider.dart';
import 'package:tms_driver_app/screens/messages/call_screen.dart';

/// Incoming-call screen driven by [CallProvider].
///
/// Production improvements:
///  • 45-second countdown ring timeout → auto-decline (managed in [CallProvider]).
///  • Listens to [CallProvider.state] — if call is cancelled remotely the screen
///    pops automatically without driver action.
///  • Answer flow: [CallProvider.acceptCall()] → Agora join → push [CallScreen].
///  • Decline flow: [CallProvider.declineCall()] → POST /decline-call → pop.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rippleCtrl;
  Timer? _ringTimer;
  bool _isAnswering = false;
  bool _isDeclining = false;

  // Visual countdown so the driver knows how long is left.
  int _secondsLeft = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Ring every 3 seconds.
    _ring();
    _ringTimer = Timer.periodic(const Duration(seconds: 3), (_) => _ring());

    // Visual countdown (the actual timeout is in CallProvider).
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, 45);
      });
    });
  }

  void _ring() {
    if (!mounted) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  // ─── Answer ────────────────────────────────────────────────────────────────

  Future<void> _answer() async {
    if (_isAnswering || _isDeclining) return;
    _ringTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() => _isAnswering = true);

    final callProvider = context.read<CallProvider>();

    // acceptCall() fetches the Agora token and joins the channel.
    await callProvider.acceptCall();

    if (!mounted) return;

    // Replace this screen with the active call screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CallScreen()),
    );
  }

  // ─── Decline ───────────────────────────────────────────────────────────────

  Future<void> _decline() async {
    if (_isAnswering || _isDeclining) return;
    _ringTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() => _isDeclining = true);

    await context.read<CallProvider>().declineCall();

    if (mounted) Navigator.of(context).pop();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        // If call was cancelled remotely (or timed out in provider), auto-pop.
        if (call.state == CallState.declined ||
            call.state == CallState.idle ||
            call.state == CallState.ended) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        // If acceptCall succeeded and engine is now connecting, push CallScreen.
        if (call.state == CallState.connecting ||
            call.state == CallState.connected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CallScreen()),
            );
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B3E),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Column(
                    children: [
                      const Text(
                        'Incoming Call',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        call.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Support is calling you',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      // Countdown ring timer
                      _CountdownArc(secondsLeft: _secondsLeft),
                    ],
                  ),

                  // ── Ripple avatar ──────────────────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRipple(0.0),
                      _buildRipple(0.5),
                      // Pulsing avatar
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) => Transform.scale(
                          scale: 1.0 + _pulseCtrl.value * 0.06,
                          child: child,
                        ),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border:
                                Border.all(color: Colors.white24, width: 2),
                          ),
                          child: const Icon(
                            Icons.headset_mic_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Answer / Decline ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallButton(
                        icon: Icons.call_end_rounded,
                        label: _isDeclining ? 'Declining…' : 'Decline',
                        color: Colors.redAccent,
                        onTap:
                            (_isAnswering || _isDeclining) ? null : _decline,
                      ),
                      _CallButton(
                        icon: Icons.call_rounded,
                        label: _isAnswering ? 'Connecting…' : 'Answer',
                        color: const Color(0xFF34C759),
                        onTap:
                            (_isAnswering || _isDeclining) ? null : _answer,
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

  Widget _buildRipple(double offset) {
    return AnimatedBuilder(
      animation: _rippleCtrl,
      builder: (_, __) {
        final v = (_rippleCtrl.value + offset) % 1.0;
        return Container(
          width: 160 + v * 70,
          height: 160 + v * 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: (1 - v) * 0.07),
          ),
        );
      },
    );
  }
}

// ─── Countdown arc ───────────────────────────────────────────────────────────

class _CountdownArc extends StatelessWidget {
  final int secondsLeft;
  const _CountdownArc({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final progress = secondsLeft / 45.0;
    final color = secondsLeft > 15
        ? const Color(0xFF34C759)
        : secondsLeft > 5
            ? Colors.orange
            : Colors.redAccent;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Call button ─────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? color : color.withValues(alpha: 0.35),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
