import 'package:flutter/material.dart';

/// Global navigation key to be used across the app (e.g., for dialogs, routing)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background task ID for WorkManager
const String backgroundTaskId = 'sv.background.fallback';
