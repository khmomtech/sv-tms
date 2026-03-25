import 'package:flutter/material.dart';
import 'package:tms_driver_app/widgets/custom_dialog.dart';

class DialogHelper {
  static void showDialogBox({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: title,
          message: message,
          onPressed: onConfirm ?? () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
