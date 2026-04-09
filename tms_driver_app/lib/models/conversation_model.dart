import 'package:flutter/material.dart';

/// A minimal conversation model used by the messages inbox screen.
class ConversationModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime lastUpdated;
  final int unreadCount;
  final IconData icon;
  final Color iconBackground;

  ConversationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    this.unreadCount = 0,
    this.icon = Icons.support_agent,
    this.iconBackground = const Color(0xFFD7E6FF),
  });
}
