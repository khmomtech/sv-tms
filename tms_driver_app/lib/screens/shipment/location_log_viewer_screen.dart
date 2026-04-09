import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocationLogViewerScreen extends StatefulWidget {
  const LocationLogViewerScreen({super.key});

  @override
  State<LocationLogViewerScreen> createState() =>
      _LocationLogViewerScreenState();
}

class _LocationLogViewerScreenState extends State<LocationLogViewerScreen> {
  String _logContent = 'Loading logs...';

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/background_location_log.txt');

      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() => _logContent = content);
      } else {
        setState(() => _logContent = 'No logs found.');
      }
    } catch (e) {
      setState(() => _logContent = 'Failed to load logs: $e');
    }
  }

  Future<void> _clearLog() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/background_location_log.txt');
      if (await file.exists()) {
        await file.writeAsString('');
        setState(() => _logContent = 'Logs cleared.');
      }
    } catch (e) {
      setState(() => _logContent = 'Failed to clear logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLog,
            tooltip: 'Refresh Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLog,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(
          _logContent,
          style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
        ),
      ),
    );
  }
}
