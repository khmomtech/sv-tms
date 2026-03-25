// 📁 lib/screen/diagnostics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_response.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/models/dispatch_action_metadata.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  static const _diagChannel = MethodChannel('diag');
  final DioClient _dio = DioClient();
  final TextEditingController _dispatchIdController = TextEditingController();
  Map<String, dynamic> _info = {};
  Map<String, dynamic>? _runtimeInfo;
  DispatchActionsResponse? _actionsResponse;
  bool _loading = true;
  bool _loadingRuntime = false;
  bool _loadingActions = false;
  String? _runtimeError;
  String? _actionsError;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
    _loadRuntimeInfo();
  }

  @override
  void dispose() {
    _dispatchIdController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    try {
      final res = await _diagChannel.invokeMethod<Map>('getDiagnostics');
      if (res != null) {
        setState(() {
          _info = Map<String, dynamic>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      debugPrint('Diagnostics error: $e');
    }
  }

  Future<void> _loadRuntimeInfo() async {
    setState(() {
      _loadingRuntime = true;
      _runtimeError = null;
    });
    try {
      final ApiResponse<Map<String, dynamic>> res =
          await _dio.get<Map<String, dynamic>>(
        '/public/runtime-info',
        converter: (data) => (data as Map).cast<String, dynamic>(),
      );
      if (!mounted) return;
      setState(() {
        _runtimeInfo = res.success ? _unwrapMap(res.data) : null;
        _runtimeError =
            res.success ? null : (res.message ?? 'Failed to load runtime info');
        _loadingRuntime = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _runtimeError = e.toString();
        _loadingRuntime = false;
      });
    }
  }

  Future<void> _loadDispatchActions() async {
    final dispatchId = _dispatchIdController.text.trim();
    if (dispatchId.isEmpty) {
      setState(() {
        _actionsError = 'Dispatch ID is required';
      });
      return;
    }
    setState(() {
      _loadingActions = true;
      _actionsError = null;
    });
    try {
      final provider = context.read<DispatchProvider>();
      final response = await provider.getAvailableActions(dispatchId);
      if (!mounted) return;
      setState(() {
        _actionsResponse = response;
        _actionsError = response == null ? 'No action payload returned' : null;
        _loadingActions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionsError = e.toString();
        _loadingActions = false;
      });
    }
  }

  Map<String, dynamic>? _unwrapMap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final dynamic data = raw['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return raw;
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text(value?.toString() ?? '-', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDiagnostics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('🔧 Config',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _row('Base API', _info['baseApi']),
                  _row('WS URL', _info['wsUrl']),
                  _row('Driver ID', _info['driverId']),
                  _row('Driver Name', _info['driverName']),
                  _row('Vehicle Plate', _info['vehiclePlate']),
                  _row('Service Running', _info['running']),
                  _row('Service Alive', _info['alive']),
                  _row('Last Heartbeat', _info['lastHeartbeatMs']),
                  _row('Pending Queue Depth', _info['pendingQueueDepth']),
                  _row('Pending Queue Bytes', _info['pendingQueueBytes']),
                  _row('Has Tracking Token', _info['hasTrackingToken']),
                  _row(
                      'Has Tracking Session ID', _info['hasTrackingSessionId']),
                  const SizedBox(height: 16),
                  const Text('Runtime',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_loadingRuntime)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_runtimeError != null)
                    Text(_runtimeError!,
                        style: const TextStyle(color: Colors.red)),
                  _row('Service', _runtimeInfo?['serviceName']),
                  _row('Git SHA', _runtimeInfo?['gitSha']),
                  _row('Build Time', _runtimeInfo?['buildTime']),
                  _row('Workflow Schema',
                      _runtimeInfo?['workflowSchemaVersion']),
                  _row('Migration Version', _runtimeInfo?['migrationVersion']),
                  const SizedBox(height: 16),
                  const Text('Dispatch Workflow',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _dispatchIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Dispatch ID',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadingActions ? null : _loadDispatchActions,
                    child: Text(_loadingActions
                        ? 'Loading Dispatch...'
                        : 'Load Dispatch Actions'),
                  ),
                  if (_actionsError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_actionsError!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  _row(
                      'Last Dispatch ID',
                      _actionsResponse?.dispatchId ??
                          context
                              .watch<DispatchProvider>()
                              .lastActionsDispatchId),
                  _row('Linked Template', _actionsResponse?.loadingTypeCode),
                  _row('Workflow Version', _actionsResponse?.workflowVersionId),
                  _row('Resolved Version',
                      _actionsResponse?.resolvedWorkflowVersionId),
                  _row('Current Status', _actionsResponse?.currentStatus),
                  _row('Action Count',
                      _actionsResponse?.availableActions.length ?? 0),
                  if (_actionsResponse != null &&
                      _actionsResponse!.availableActions.isNotEmpty)
                    SelectableText(
                      _actionsResponse!.availableActions
                          .map(
                            (action) => '${action.targetStatus} '
                                '[${action.requiredInput}] '
                                'template=${action.templateCode ?? '-'} '
                                'rule=${action.ruleId ?? '-'} '
                                'wv=${action.workflowVersionId ?? '-'}',
                          )
                          .join('\n'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 16),
                  const Text('Service',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _row('Running', _info['running']),
                  _row('User Stop', _info['userStop']),
                  _row('Last Heartbeat', _info['lastHeartbeatMs']),
                  const SizedBox(height: 16),
                  const Text('Permissions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _row('Foreground Location', _info['fgLocation']),
                  _row('Background Location', _info['bgLocation']),
                  _row('Notifications', _info['notifEnabled']),
                  const SizedBox(height: 16),
                  const Text('🔋 Battery',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _row('Ignoring Optimizations', _info['batteryOpt']),
                  const SizedBox(height: 16),
                  const Text('🔔 Notification Channels',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _row('Alerts Channel', _info['hasAlertsChannel']),
                  _row('Updates Channel', _info['hasUpdatesChannel']),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/permissions'),
                    child: const Text('Fix Permissions'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadRuntimeInfo,
                    child: const Text('Refresh Runtime Info'),
                  ),
                ],
              ),
            ),
    );
  }
}
