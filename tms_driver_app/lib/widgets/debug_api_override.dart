import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

/// Debug screen to override API base URL at runtime.
class DebugApiOverride extends StatefulWidget {
  const DebugApiOverride({super.key});

  @override
  State<DebugApiOverride> createState() => _DebugApiOverrideState();
}

class _DebugApiOverrideState extends State<DebugApiOverride> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ApiConstants.ensureInitialized();
    setState(() {
      _controller.text = ApiConstants.baseUrl;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final val = _controller.text.trim();
    if (val.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid API base URL'),
      ));
      return;
    }

    await ApiConstants.setBaseUrlOverride(val);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('API base override saved'),
    ));
    setState(() {});
  }

  Future<void> _clear() async {
    await ApiConstants.clearBaseUrlOverride();
    await ApiConstants.ensureInitialized();
    _controller.text = ApiConstants.baseUrl;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('API override cleared'),
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug — API Override'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current API Base URL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'https://host:port/api',
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Save override'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear override'),
                      ),
                      const SizedBox(width: 12),
                      if (kDebugMode)
                        TextButton(
                          onPressed: () async {
                            final base = ApiConstants.baseUrl;
                            await showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Current base'),
                                content: Text(base),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  )
                                ],
                              ),
                            );
                          },
                          child: const Text('Show active base'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '''- Compile-time overrides (`--dart-define`) are pinned and cannot be replaced by this screen.
- Overrides are persisted locally and will be used until cleared or stale.
- Use full URL (including scheme) and end with `/api` (the UI will normalize as needed).''',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
    );
  }
}
