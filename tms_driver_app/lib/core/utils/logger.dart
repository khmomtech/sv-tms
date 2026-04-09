// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

class Logger {
  static void debug(dynamic message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🐛 $prefix$message');
    }
  }

  static void info(dynamic message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $prefix$message');
    }
  }

  static void warning(dynamic message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  static void error(dynamic message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint(' $prefix$message');
  }
}
