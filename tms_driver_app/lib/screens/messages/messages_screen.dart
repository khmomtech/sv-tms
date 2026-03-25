// ignore_for_file: directives_ordering
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:tms_driver_app/core/constants/app_colors.dart';
import 'package:tms_driver_app/models/chat_message_model.dart';
import 'package:tms_driver_app/providers/chat_provider.dart';
import 'package:tms_driver_app/screens/messages/call_screen.dart';
import 'package:tms_driver_app/screens/messages/incoming_call_screen.dart';
import 'package:tms_driver_app/widgets/chat_message_bubble.dart';

class MessagesScreen extends StatefulWidget {
  final String? entryPoint;
  final String? initialDraft;

  const MessagesScreen({
    super.key,
    this.entryPoint,
    this.initialDraft,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _markedReadIds = {}; // Track which messages we've marked as read locally
  Timer? _refreshTimer;
  int _lastAutoHandledSignature = -1;

  XFile? _attachedPhoto;
  Uint8List? _attachedPhotoPreview;
  PlatformFile? _attachedFile;
  XFile? _attachedVideo;

  // Voice recording state
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _recordCancelled = false;

  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.setChatScreenVisible(true);
    _chatProvider.addListener(_handleIncomingCall);

    _messageFocusNode.addListener(_handleComposerFocusChanged);
    if (widget.initialDraft != null && widget.initialDraft!.isNotEmpty) {
      _messageController.text = widget.initialDraft!;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      if ((widget.entryPoint ?? '').isNotEmpty) {
        _messageFocusNode.requestFocus();
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _loadMessages(force: true);
      }
    });
  }

  @override
  void dispose() {
    _chatProvider.setChatScreenVisible(false);

    _chatProvider.removeListener(_handleIncomingCall);
    _messageFocusNode.removeListener(_handleComposerFocusChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _handleComposerFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleIncomingCall() {
    if (!mounted) return;
    if (_chatProvider.incomingCall == null) return;
    // Clear immediately to prevent duplicate pushes on subsequent notifyListeners().
    _chatProvider.clearIncomingCall();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncomingCallScreen()),
    );
  }

  // ── Voice recording ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _recordCancelled = false;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    if (!_isRecording) return;
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() => _isRecording = false);
    if (_recordCancelled || path == null || _recordSeconds < 1) {
      _recordCancelled = false;
      return;
    }
    final success = await provider.sendVoice(path);
    if (success) {
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to send voice note'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordCancelled = true;
    if (_isRecording) {
      await _recorder.stop();
      if (mounted) setState(() => _isRecording = false);
    }
  }

  String _formatRecordDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Attach menu ────────────────────────────────────────────────────────────

  Future<void> _showAttachMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D7E3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF7B61FF)),
                ),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF34C759)),
                ),
                title: const Text('Send photo'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_file_rounded, color: Color(0xFF007AFF)),
                ),
                title: const Text('Send file'),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Color(0xFFFF3B30)),
                ),
                title: const Text('Record video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF9500)),
                ),
                title: const Text('Send location'),
                onTap: () => Navigator.pop(context, 'location'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    switch (choice) {
      case 'camera':
        await _pickImage(ImageSource.camera);
        break;
      case 'gallery':
        await _pickImage(ImageSource.gallery);
        break;
      case 'file':
        await _pickFile();
        break;
      case 'video':
        await _recordVideo();
        break;
      case 'location':
        await _sendCurrentLocation();
        break;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _attachedPhoto = file;
        _attachedPhotoPreview = bytes;
        _attachedFile = null;
        _attachedVideo = null;
      });
      _messageFocusNode.requestFocus();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      setState(() {
        _attachedFile = result.files.first;
        _attachedPhoto = null;
        _attachedPhotoPreview = null;
        _attachedVideo = null;
      });
      _messageFocusNode.requestFocus();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _recordVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 3),
      );
      if (file == null) return;
      setState(() {
        _attachedVideo = file;
        _attachedPhoto = null;
        _attachedPhotoPreview = null;
        _attachedFile = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video recording failed: $e')),
        );
      }
    }
  }

  Future<void> _sendCurrentLocation() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);

    // Check & request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location…')),
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final address = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      final success = await provider.sendLocation(pos.latitude, pos.longitude, address);
      if (success) {
        _scrollToBottom();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to send location')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  Future<void> _requestCall() async {
    try {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      final success = await provider.requestCall();
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call request sent to support')),
          );
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const CallScreen()),
          );
        }
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to request call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call request failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLocalAttachmentPreview() async {
    final bytes = _attachedPhotoPreview;
    if (bytes == null || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.46),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearAttachment() {
    setState(() {
      _attachedPhoto = null;
      _attachedPhotoPreview = null;
      _attachedFile = null;
      _attachedVideo = null;
    });
  }

  Future<void> _loadMessages({bool force = false}) async {
    await _chatProvider.loadMessages(force: force);
  }

  Future<void> _sendMessage() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final text = _messageController.text.trim();

    // Handle video attachment separately
    if (_attachedVideo != null) {
      final videoPath = _attachedVideo!.path;
      _clearAttachment();
      final success = await provider.sendVideo(videoPath, message: text.isNotEmpty ? text : null);
      if (success) {
        _messageController.clear();
        _scrollToBottom();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to send video'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final hasAttachment = _attachedPhoto != null || _attachedFile != null;
    if (text.isEmpty && !hasAttachment) return;

    final success = await provider.sendMessage(
      text,
      photo: _attachedPhoto,
    );
    if (success) {
      _messageController.clear();
      _clearAttachment();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(ChatMessageModel message) async {
    final messageId = message.id;
    if (messageId == null || messageId <= 0) return;
    if (message.read || message.isPending) return;
    if (message.senderRole.toUpperCase().contains('DRIVER')) return;

    if (mounted) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.markRead(messageId);
    }
  }

  void _markUnreadMessages(List<ChatMessageModel> messages) {
    for (final message in messages) {
      final messageId = message.id;
      if (messageId == null || messageId <= 0) continue;
      if (message.read) continue;
      if (message.isPending) continue;
      if (message.senderRole.toUpperCase().contains('DRIVER')) continue;
      if (_markedReadIds.contains(messageId)) continue;
      _markedReadIds.add(messageId);
      _markAsRead(message);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final maxExtent = position.maxScrollExtent;
      if (!maxExtent.isFinite) return;

      final target = maxExtent < 0 ? 0.0 : maxExtent;
      if ((position.pixels - target).abs() < 8) return;

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat.jm().format(dt);
  }

  String? _extractPhotoUrl(String message) {
    final marker = '📷 ';
    final start = message.indexOf(marker);
    if (start < 0) return null;
    final url = message.substring(start + marker.length).trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return null;
  }

  Widget _buildEmptyState(ChatProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF2FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage == null
                  ? 'Support is ready to help.'
                  : 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131C39),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.errorMessage ??
                  'Send a message about your current delivery and our support team will jump in.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF73819A),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _messageFocusNode.requestFocus();
                _scrollToBottom();
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('Start chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadMessages(force: true),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => _loadMessages(force: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        color: Colors.white,
        icon: const Icon(Icons.arrow_back_rounded, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0x80FFFFFF),
                child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D16F),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Team',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.entryPoint == 'support_center'
                      ? 'Support request started from Help Center'
                      : 'Online • Typical reply 2m',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD9E7F4),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _requestCall,
          color: Colors.white,
          icon: const Icon(Icons.call_rounded, size: 24),
        ),
        IconButton(
          onPressed: () {},
          color: Colors.white,
          icon: const Icon(Icons.more_vert_rounded, size: 28),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0x403B58B0),
        ),
      ),
    );
  }

  Widget _buildTodayPill() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD9E3EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'TODAY',
          style: TextStyle(
            color: Color(0xFF6B7C8F),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadHintCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 46, top: 8, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2A52).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD8E0EE),
            ),
          ),
          child: Row(
            children: const [
              Icon(Icons.photo_camera_rounded, color: Color(0xFF97A4BC)),
              SizedBox(width: 14),
              Text(
                'Click to upload photo',
                style: TextStyle(
                  color: Color(0xFF6F7E99),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7EEF4),
      appBar: _buildHeader(context),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          Widget content;
          if (provider.isLoading && provider.messages.isEmpty) {
            content = const Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage != null && provider.messages.isEmpty) {
            content = Center(
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (provider.messages.isEmpty) {
            content = _buildEmptyState(provider);
          } else {
            final extraItems = 2 + (provider.errorMessage != null ? 1 : 0);
            content = RefreshIndicator(
              onRefresh: () => _loadMessages(force: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: provider.messages.length + extraItems,
                padding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildTodayPill();
                  }

                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: _TypingIndicator(isTyping: provider.isTyping),
                    );
                  }

                  // Show an inline banner if there is an error but we have messages
                  if (index == 2 && provider.errorMessage != null) {
                    return _buildInlineErrorBanner(provider.errorMessage!);
                  }

                  final messageIndex =
                      index - (provider.errorMessage != null ? 3 : 2);
                  if (messageIndex < 0 || messageIndex >= provider.messages.length) {
                    return const SizedBox.shrink();
                  }

                  final message = provider.messages[messageIndex];
                  final bubble = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ChatMessageBubble(
                      message: message,
                      time: _formatTime(message.createdAt),
                      isRead: message.read,
                    ),
                  );

                  final photoUrl = _extractPhotoUrl(message.message);
                  if (photoUrl != null && !message.senderRole.toUpperCase().contains('DRIVER')) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bubble,
                        _buildUploadHintCard(),
                      ],
                    );
                  }

                  return bubble;
                },
              ),
            );

            final autoHandledSignature =
                provider.messages.length * 10 + (provider.errorMessage != null ? 1 : 0);
            if (_lastAutoHandledSignature != autoHandledSignature) {
              _lastAutoHandledSignature = autoHandledSignature;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _scrollToBottom();
                _markUnreadMessages(provider.messages);
              });
            }
          }

          return Column(
            children: [
              Expanded(child: content),
              _buildMessageInput(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider provider) {
    final hasAttachment = _attachedPhoto != null || _attachedFile != null || _attachedVideo != null;
    final hasContent = _messageController.text.trim().isNotEmpty || hasAttachment;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        border: Border(top: BorderSide(color: Color(0xFFDDE3EE), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Attachment previews ──────────────────────────────────────────
          if (!_isRecording && _attachedPhotoPreview != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _showLocalAttachmentPreview,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Hero(
                        tag: 'chat-local-attachment-preview',
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: MemoryImage(_attachedPhotoPreview!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearAttachment,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (!_isRecording && _attachedFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFD0EE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _attachedFile!.name,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1A2441), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _clearAttachment,
                      child: const Icon(Icons.close_rounded, color: Color(0xFF6B7C93), size: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ── Video preview chip ───────────────────────────────────────────
          if (!_isRecording && _attachedVideo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFBDBD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_rounded, color: Color(0xFFFF3B30), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _attachedVideo!.path.split('/').last,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1A2441), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _clearAttachment,
                      child: const Icon(Icons.close_rounded, color: Color(0xFF6B7C93), size: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ── Input row ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Pill: emoji + textfield + (paperclip when empty)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _isRecording
                      // ── Recording indicator inside pill ──────────────────
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _cancelRecording,
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatRecordDuration(_recordSeconds),
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '< Slide to cancel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF9DADC0), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      // ── Normal compose row ────────────────────────────────
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Emoji / sticker icon (left, always)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Icon(
                                Icons.sentiment_satisfied_alt_rounded,
                                color: const Color(0xFF8596AB),
                                size: 26,
                              ),
                            ),
                            // Text field
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Message',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9DADC0),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                cursorColor: AppColors.primary,
                                cursorWidth: 2,
                                cursorHeight: 20,
                                style: const TextStyle(fontSize: 16, height: 1.3, color: Color(0xFF1A2441)),
                                minLines: 1,
                                maxLines: 5,
                                textInputAction: TextInputAction.newline,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            // Paperclip — visible only when nothing typed and no attachment
                            if (!hasContent)
                              Padding(
                                padding: const EdgeInsets.only(right: 4, bottom: 4),
                                child: IconButton(
                                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF8596AB), size: 24),
                                  onPressed: _showAttachMenu,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  splashRadius: 18,
                                ),
                              )
                            else
                              const SizedBox(width: 10),
                          ],
                        ),
                ),
              ),

              const SizedBox(width: 6),

              // ── Blue circle: mic (hold) or send (tap) ────────────────────
              GestureDetector(
                onTap: hasContent && !_isRecording ? _sendMessage : null,
                onLongPressStart: !hasContent && !_isRecording ? (_) => _startRecording() : null,
                onLongPressEnd: _isRecording ? (_) => _stopAndSendRecording() : null,
                onLongPressMoveUpdate: _isRecording
                    ? (d) { if (d.offsetFromOrigin.dx < -80) _cancelRecording(); }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : AppColors.primary).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: provider.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Icon(
                          hasContent && !_isRecording ? Icons.send_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final bool isTyping;

  const _TypingIndicator({this.isTyping = false});

  @override
  Widget build(BuildContext context) {
    if (!isTyping) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 4),
            SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 4),
            SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Sarah from Support is typing...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF73819B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
