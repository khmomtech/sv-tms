import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/providers/notification_provider.dart';
import 'package:tms_driver_app/widgets/notification_item_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
      _connectWebSocket();
    });
  }

  Future<void> _fetchNotifications() async {
    try {
      final provider = context.read<NotificationProvider>();
      await provider.fetchNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('notifications.fetch_error')),
            backgroundColor: const Color(0xFF2563eb),
          ),
        );
      }
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId');
      if (driverId != null) {
        final provider = context.read<NotificationProvider>();
        provider.connectWebSocket(driverId);
      }
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
    }
  }

  Future<void> _refresh() async {
    try {
      final provider = context.read<NotificationProvider>();
      await provider.fetchNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('notifications.refresh_error')),
            backgroundColor: const Color(0xFF2563eb),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final provider = context.read<NotificationProvider>();
      await provider.markNotificationAsRead(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('notifications.mark_read_error')),
            backgroundColor: const Color(0xFF2563eb),
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: Text(tr('notifications.delete_title')),
        content: Text(tr('notifications.delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('notifications.title'),
          style: const TextStyle(fontFamily: 'NotoSansKhmer'),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return notificationProvider.unreadCount > 0
                  ? TextButton(
                      onPressed: () {
                        notificationProvider.markAllAsRead();
                      },
                      child: Text(
                        tr('notifications.mark_read'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'NotoSansKhmer',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return _buildLoadingSkeleton();
          }

          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('notifications.none'),
                    style: const TextStyle(
                      fontFamily: 'NotoSansKhmer',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            displacement: 30,
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];

                return Dismissible(
                  key: ValueKey('notif-${item.id}'),
                  direction:
                      DismissDirection.endToStart, // swipe left to delete
                  background: const SizedBox.shrink(),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed: (_) async {
                    try {
                      await context
                          .read<NotificationProvider>()
                          .deleteNotification(item.id);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('notifications.deleted'))),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      // Re-fetch to restore UI if provider didn't revert
                      await _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('notifications.delete_error')),
                          backgroundColor: const Color(0xFF2563eb),
                        ),
                      );
                    }
                  },
                  child: NotificationItemWidget(
                    item: item,
                    onTap: () {
                      if (!item.read) {
                        _markAsRead(item.id);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Build skeleton loading UI for better UX
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          color: Colors.grey.shade100,
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              color: Colors.grey.shade300,
            ),
            title: Container(
              height: 16,
              color: Colors.grey.shade300,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 200,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
            trailing: Container(
              height: 12,
              width: 80,
              color: Colors.grey.shade300,
            ),
          ),
        );
      },
    );
  }
}
