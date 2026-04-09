import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WelcomeCardWidget extends StatefulWidget {
  final String employeeName;
  final String photoUrl;

  const WelcomeCardWidget({
    super.key,
    required this.employeeName,
    required this.photoUrl,
  });

  @override
  _WelcomeCardWidgetState createState() => _WelcomeCardWidgetState();
}

class _WelcomeCardWidgetState extends State<WelcomeCardWidget> {
  String _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });
  }

  /// Decodes any Khmer text, if necessary.
  String decodeKhmerText(String text) {
    return utf8.decode(text.runes.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentHour = DateTime.now().hour;
    final isMorning = currentHour < 12;

    // Decide which image to load based on `photoUrl`.
    // If empty, load a local asset; otherwise, load from the network.
    final ImageProvider avatarProvider = widget.photoUrl.isNotEmpty
        ? NetworkImage(widget.photoUrl)
        : const AssetImage('assets/images/default_avatar.png');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColorDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Employee Photo with local fallback
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: avatarProvider,
              ),
              const SizedBox(width: 16),

              // Text Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMorning ? 'Good Morning' : 'Good Afternoon',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'NotoSansKhmer',
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      decodeKhmerText(widget.employeeName),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'NotoSansKhmer',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_clock,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentTime,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Positioned Icon (sun or moon)
        Positioned(
          top: 9,
          right: 16,
          child: Icon(
            isMorning ? Icons.wb_sunny : Icons.nights_stay,
            color: isMorning ? Colors.yellowAccent : Colors.blueGrey[100],
            size: 48,
          ),
        ),
      ],
    );
  }
}
