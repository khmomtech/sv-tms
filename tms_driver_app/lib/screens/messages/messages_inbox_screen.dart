import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/constants/app_colors.dart';
import 'package:tms_driver_app/models/conversation_model.dart';
import 'package:tms_driver_app/providers/chat_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<ConversationModel> _placeholderConversations = [
    ConversationModel(
      id: 'dispatch',
      title: 'Dispatch - Michael',
      subtitle: 'Your next pickup is scheduled for 10:50 at Terminal 4.',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 18)),
      unreadCount: 2,
      icon: Icons.person,
      iconBackground: const Color(0xFFF6C28B),
    ),
    ConversationModel(
      id: 'support',
      title: 'Roadside Support',
      subtitle: 'We’ve received your ticket regarding the scanner issue.',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      icon: Icons.headset_mic_rounded,
      iconBackground: const Color(0xFF6C8B8A),
    ),
    ConversationModel(
      id: 'maintenance',
      title: 'Maintenance - Garage',
      subtitle: 'The brake inspection for Truck #402 is due today.',
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      icon: Icons.build_rounded,
      iconBackground: const Color(0xFFE8EEF8),
    ),
    ConversationModel(
      id: 'system',
      title: 'System Notifications',
      subtitle: 'New safety guidelines have been updated for your fleet.',
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
      unreadCount: 0,
      icon: Icons.info,
      iconBackground: const Color(0xFFE8E5FB),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().loadMessages();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return DateFormat.jm().format(time);
    }
    if (time.isAfter(now.subtract(const Duration(days: 2)))) {
      return 'Yesterday';
    }
    return DateFormat.MMMd().format(time);
  }

  void _openConversation(ConversationModel conversation) {
    Navigator.pushNamed(
      context,
      AppRoutes.messagesChat,
      arguments: ChatRouteArgs(entryPoint: conversation.id),
    );
  }

  List<ConversationModel> _buildConversations(ChatProvider provider) {
    final conversations = [
      _buildSupportConversation(provider),
      ..._placeholderConversations.where(
        (conversation) => conversation.id != 'support',
      ),
    ];
    conversations.sort(
      (a, b) => b.lastUpdated.compareTo(a.lastUpdated),
    );
    return conversations;
  }

  ConversationModel _buildSupportConversation(ChatProvider provider) {
    final messages = provider.messages;
    final latest = messages.isNotEmpty ? messages.last : null;
    final unseenCount = messages
        .where((message) =>
            !message.read &&
            !message.isPending &&
            message.senderRole.toUpperCase() != 'DRIVER')
        .length;

    final latestText = latest == null
        ? 'Contact support for help with delivery, scanning, and route issues.'
        : _messagePreview(latest.message);

    return ConversationModel(
      id: 'support',
      title: 'Support Team',
      subtitle: latestText,
      lastUpdated: latest?.createdAt ??
          DateTime.now().subtract(const Duration(days: 30)),
      unreadCount: unseenCount,
      icon: Icons.headset_mic_rounded,
      iconBackground: const Color(0xFFE7ECFF),
    );
  }

  String _messagePreview(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Photo attachment';
    if (trimmed.startsWith('📷 ')) return 'Photo attachment';
    final photoMarker = '\n📷 ';
    final markerIndex = trimmed.indexOf(photoMarker);
    if (markerIndex >= 0) {
      final visible = trimmed.substring(0, markerIndex).trim();
      return visible.isEmpty ? 'Photo attachment' : visible;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final conversations = _buildConversations(provider);
        final unreadConversations =
            conversations.where((c) => c.unreadCount > 0).toList();
        final archivedConversations =
            conversations.where((c) => c.unreadCount == 0).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111B3A),
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 30),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text(
              'Messages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.search_rounded, size: 30),
                  onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 30),
                  onPressed: () {}),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF6C7A96),
              labelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
                Tab(text: 'Archived'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConversationList(conversations, theme),
              _buildConversationList(unreadConversations, theme),
              _buildConversationList(archivedConversations, theme),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.messagesChat,
                arguments: const ChatRouteArgs(entryPoint: 'support_center'),
              );
            },
            child:
                const Icon(Icons.mark_chat_unread_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildConversationList(
    List<ConversationModel> items,
    ThemeData theme,
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No conversations yet.',
          style: TextStyle(color: Color(0xFF6C7A96), fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        indent: 96,
        height: 1,
        color: theme.dividerColor.withValues(alpha: 0.18),
      ),
      itemBuilder: (context, index) {
        final conversation = items[index];
        return InkWell(
          onTap: () => _openConversation(conversation),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: conversation.iconBackground,
                      child: Icon(
                        conversation.icon,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    if (conversation.id == 'dispatch')
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111B3A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatTime(conversation.lastUpdated),
                            style: TextStyle(
                              fontSize: 14,
                              color: conversation.unreadCount > 0
                                  ? AppColors.primary
                                  : const Color(0xFF75829B),
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF61708E),
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
