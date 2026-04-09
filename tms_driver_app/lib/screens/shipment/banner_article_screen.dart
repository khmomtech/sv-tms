import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerArticleScreen extends StatefulWidget {
  final String? id;
  final String? url;
  final String? title;

  const BannerArticleScreen({
    super.key,
    this.id,
    this.url,
    this.title,
  });

  @override
  State<BannerArticleScreen> createState() => _BannerArticleScreenState();
}

class _BannerArticleScreenState extends State<BannerArticleScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  Uri? _targetUri;

  @override
  void initState() {
    super.initState();
    _targetUri = _parseUrl(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onNavigationRequest: (request) {
            // Allow same-url navigation; otherwise open externally
            final reqUri = Uri.tryParse(request.url);
            if (reqUri != null &&
                _targetUri != null &&
                reqUri.host == _targetUri!.host) {
              return NavigationDecision.navigate;
            }
            _launchExternal(request.url);
            return NavigationDecision.prevent;
          },
        ),
      );

    if (_targetUri != null) {
      _controller.loadRequest(_targetUri!);
    }
  }

  Uri? _parseUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return null;
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'Article';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_targetUri != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => _launchExternal(_targetUri!.toString()),
            ),
        ],
      ),
      body: _targetUri == null
          ? _buildEmpty()
          : Column(
              children: [
                if (_progress > 0 && _progress < 1)
                  LinearProgressIndicator(value: _progress),
                Expanded(child: WebViewWidget(controller: _controller)),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 52, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No article URL provided',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide a valid link for banner articles.',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
