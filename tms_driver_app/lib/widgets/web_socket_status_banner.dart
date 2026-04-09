import 'package:flutter/material.dart';

class WebSocketStatusBanner extends StatelessWidget {
  final bool isConnected;

  const WebSocketStatusBanner({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink(); // No banner if connected

    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Disconnected from Server',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
