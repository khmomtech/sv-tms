import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

class ErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'error.connection'.tr();
    } else if (error is TimeoutException) {
      return 'error.timeout'.tr();
    } else if (error is HandshakeException) {
      return 'error.ssl'.tr();
    } else if (error.toString().contains('Connection refused')) {
      return 'error.server_down'.tr();
    } else if (error.toString().contains('FormatException')) {
      return 'error.invalid_data'.tr();
    }
    return 'error.unknown'.tr();
  }

  static String fromStatusCode(int statusCode) {
    return switch (statusCode) {
      401 => 'error.unauthorized'.tr(),
      403 => 'error.forbidden'.tr(),
      500 => 'error.server'.tr(),
      _ => 'error.unknown'.tr(),
    };
  }
}
