import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HomeErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  const HomeErrorView({required this.errorMessage, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(tr('common.retry')),
            ),
          ],
        ],
      ),
    );
  }
}
