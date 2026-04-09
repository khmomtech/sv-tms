import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_constants.dart';

class DeviceApprovalPendingScreen extends StatefulWidget {
  const DeviceApprovalPendingScreen({super.key});

  @override
  State<DeviceApprovalPendingScreen> createState() =>
      _DeviceApprovalPendingScreenState();
}

class _DeviceApprovalPendingScreenState
    extends State<DeviceApprovalPendingScreen> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _deviceId = '';
  String _deviceName = '';
  String _os = '';
  String _version = '';
  String _appVersion = '';
  String _manufacturer = '';
  String _model = '';
  String _location = '';

  bool _isLoading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    try {
      // Location services/permission are optional here; we proceed even if denied
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (serviceEnabled &&
          (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever)) {
        permission = await Geolocator.requestPermission();
      }

      Position? position;
      try {
        if (serviceEnabled &&
            (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse)) {
          position = await Geolocator.getCurrentPosition();
        }
      } catch (_) {
        position = null; // ignore location failures
      }

      final latLng = (position != null)
          ? '${position.latitude},${position.longitude}'
          : 'UNKNOWN';

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        if (!mounted) return;
        setState(() {
          _deviceId = android.id;
          _deviceName = '${android.brand} ${android.model}';
          _os = 'Android';
          _version = android.version.release;
          _manufacturer = android.manufacturer;
          _model = android.device;
          _appVersion = packageInfo.version;
          _location = latLng;
        });
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        if (!mounted) return;
        setState(() {
          _deviceId = ios.identifierForVendor ?? 'UNKNOWN';
          _deviceName = '${ios.name} ${ios.model}';
          _os = 'iOS';
          _version = ios.systemVersion;
          _manufacturer = 'Apple';
          _model = ios.utsname.machine;
          _appVersion = packageInfo.version;
          _location = latLng;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _deviceId = 'UNKNOWN';
          _deviceName = _os = _version = 'UNKNOWN';
          _manufacturer = _model = _appVersion = _location = 'UNKNOWN';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deviceId = 'ERROR';
        _deviceName = _os = _version =
            _manufacturer = _model = _appVersion = _location = 'UNKNOWN';
        _message = ' មិនអាចទាញយកព័ត៏មានឧបករណ៍បាន: $e';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deviceId == 'UNKNOWN' || _deviceId == 'ERROR') {
      setState(() {
        _message = ' មិនទាន់ទទួលបាន Device ID ត្រឹមត្រូវ!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final ipAddress = await _getIpAddress();
      final response = await http.post(
        _resolveDirectAuthUri('/driver/device/request-approval'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          'os': _os,
          'version': _version,
          'appVersion': _appVersion,
          'manufacturer': _manufacturer,
          'model': _model,
          'location': _location,
          'ipAddress': ipAddress,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = ' សំណើបានផ្ញើរដោយជោគជ័យ។ សូមរងចាំអនុញ្ញាតពីអ្នកគ្រប់គ្រង។';
        });
      } else {
        final String fallback = 'បរាជ័យក្នុងការស្នើសុំអនុញ្ញាត';
        String serverMessage = fallback;
        try {
          if (response.body.isNotEmpty) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded['message'] is String) {
              serverMessage = decoded['message'] as String;
            }
          }
        } catch (_) {
          serverMessage = fallback;
        }
        if (!mounted) return;
        setState(() {
          _message = ' $serverMessage';
        });
      }
    } catch (e) {
      setState(() {
        _message = ' កំហុសបណ្តាញ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Uri _resolveDirectAuthUri(String apiPath) {
    try {
      final baseUri = Uri.parse(ApiConstants.baseUrl);
      final host = baseUri.host.trim();
      if (host.isEmpty) return Uri.parse('${ApiConstants.baseUrl}$apiPath');

      final isLocalHost = host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2' ||
          host == '::1';
      final isPrivateIpv4 = RegExp(
        r'^(10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+)$',
      ).hasMatch(host);
      final currentPort = baseUri.hasPort
          ? baseUri.port
          : (baseUri.scheme == 'https' ? 443 : 80);

      if (!(isLocalHost || isPrivateIpv4)) {
        return Uri.parse('${ApiConstants.baseUrl}$apiPath');
      }
      if (currentPort != 8080 && currentPort != 8086) {
        return Uri.parse('${ApiConstants.baseUrl}$apiPath');
      }

      return baseUri.replace(
        port: 8080,
        path: '/api$apiPath',
        query: null,
        fragment: null,
      );
    } catch (_) {
      return Uri.parse('${ApiConstants.baseUrl}$apiPath');
    }
  }

  Future<String> _getIpAddress() async {
    try {
      final interfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade700,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Semantics(
                  label: 'Company logo',
                  child: Image.asset('assets/images/logo.png', height: 100),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ឧបករណ៍មិនទាន់បានអនុញ្ញាត!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Device ID: $_deviceId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  'ឈ្មោះឧបករណ៍: $_deviceName | $_os $_version',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  'សូមបញ្ចូលព័ត៌មានដើម្បីស្នើសុំអនុញ្ញាត',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),

                ///  Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'ឈ្មោះអ្នកប្រើ',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'បញ្ចូលឈ្មោះ' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        enableSuggestions: false,
                        autocorrect: false,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'ពាក្យសម្ងាត់',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'បញ្ចូលពាក្យសម្ងាត់'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      if (_message.isNotEmpty)
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _message.contains('បរាជ័យ') ||
                                    _message.contains('កំហុស')
                                ? Colors.yellowAccent
                                : Colors.greenAccent,
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                await _submitRequest();
                              },
                        icon: const Icon(Icons.send),
                        label: Text(
                            _isLoading ? 'កំពុងផ្ញើ...' : 'ស្នើសុំអនុញ្ញាត'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signin');
                  },
                  child: const Text(
                    'ត្រលប់ទៅការចូល',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
