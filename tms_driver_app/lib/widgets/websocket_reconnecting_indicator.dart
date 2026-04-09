import 'package:flutter/material.dart';

class WebSocketReconnectingIndicator extends StatelessWidget {
  final bool isReconnecting;

  const WebSocketReconnectingIndicator(
      {super.key, required this.isReconnecting});

  @override
  Widget build(BuildContext context) {
    if (!isReconnecting) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: const [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Reconnecting to server...',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
