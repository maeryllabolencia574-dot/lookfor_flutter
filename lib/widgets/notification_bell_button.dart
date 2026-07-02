import 'package:flutter/material.dart';

import '../screens/inventory_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/profile_screen.dart';
import '../services/api_client.dart';
import '../services/notification_center.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  List<Map<String, dynamic>> _notifications = const [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    notificationCenterVersion.addListener(_handleNotificationCenterChanged);
    _loadNotifications();
  }

  @override
  void dispose() {
    notificationCenterVersion.removeListener(_handleNotificationCenterChanged);
    super.dispose();
  }

  void _handleNotificationCenterChanged() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final results = await Future.wait([
        apiClient.getNotifications(),
        apiClient.getUnreadNotificationCount(),
      ]);

      if (!mounted) return;
      final localNotifications = getLocalNotifications();
      final serverNotifications = (results[0] as List<dynamic>)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final notifications = [...localNotifications, ...serverNotifications]
        ..sort(_compareNotificationsByDate);

      setState(() {
        _notifications = notifications;
        _unreadCount =
            (results[1] as int) +
            localNotifications
                .where((notification) => notification['is_read'] != true)
                .length;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final localNotifications = getLocalNotifications();
      setState(() {
        _notifications = localNotifications;
        _unreadCount = localNotifications
            .where((notification) => notification['is_read'] != true)
            .length;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSelected(String value) async {
    if (value == '__refresh__') {
      await _loadNotifications();
      return;
    }

    final notification = _notifications.firstWhere(
      (item) => item['id']?.toString() == value,
      orElse: () => const <String, dynamic>{},
    );
    if (notification.isEmpty) return;

    try {
      if (notification['is_local'] == true) {
        markLocalNotificationAsRead(value);
      } else {
        final id = int.tryParse(value);
        if (id != null) {
          await apiClient.markNotificationAsRead(id);
        }
      }
      await _loadNotifications();
      if (!mounted) return;
      _openNotificationTarget(notification);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Notifications',
      onOpened: _loadNotifications,
      onSelected: _handleSelected,
      icon: Stack(
        children: [
          const Icon(Icons.notifications_none),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) {
        if (_isLoading) {
          return const [
            PopupMenuItem<String>(
              enabled: false,
              value: '__loading__',
              child: SizedBox(
                width: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ];
        }

        if (_notifications.isEmpty) {
          return const [
            PopupMenuItem<String>(
              enabled: false,
              value: '__empty__',
              child: SizedBox(
                width: 240,
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ];
        }

        return [
          ..._notifications.map((notification) {
            final id = notification['id']?.toString() ?? '';
            final title = _notificationTitle(notification);
            final message = _notificationMessage(notification);
            final time = _notificationTime(notification);
            final isRead = notification['is_read'] == true;

            return PopupMenuItem<String>(
              value: id,
              child: SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFCC00),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: '__refresh__',
            child: Text('Refresh notifications'),
          ),
        ];
      },
    );
  }

  void _openNotificationTarget(Map<String, dynamic> notification) {
    final route = _notificationRoute(notification);
    final itemId = _notificationItemId(notification);

    if (route == _NotificationRoute.messages) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessagesScreen()),
      );
      return;
    }

    if (route == _NotificationRoute.profile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    if (route == _NotificationRoute.lostInventory ||
        route == _NotificationRoute.foundInventory) {
      final type = route == _NotificationRoute.lostInventory ? 'Lost' : 'Found';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InventoryScreen(type: type, initialItemId: itemId),
        ),
      );

      if (_isLostItemMatchedNotification(notification)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showLostItemMatchedDialog();
        });
      }
      return;
    }

    _showNotificationDetails(notification);
  }

  _NotificationRoute _notificationRoute(Map<String, dynamic> notification) {
    final combined = _combinedNotificationText(notification);

    if (combined.contains('message') ||
        combined.contains('chat') ||
        combined.contains('conversation')) {
      return _NotificationRoute.messages;
    }

    if (combined.contains('profile') ||
        combined.contains('password') ||
        combined.contains('account') ||
        combined.contains('security')) {
      return _NotificationRoute.profile;
    }

    if (combined.contains('lost')) return _NotificationRoute.lostInventory;
    if (combined.contains('found') ||
        combined.contains('approval') ||
        combined.contains('approved') ||
        combined.contains('surrender')) {
      return _NotificationRoute.foundInventory;
    }

    if (combined.contains('match')) return _NotificationRoute.lostInventory;
    if (combined.contains('report') || combined.contains('item')) {
      return _NotificationRoute.foundInventory;
    }

    return _NotificationRoute.details;
  }

  String? _notificationItemId(Map<String, dynamic> notification) {
    dynamic value = notification['item_id'] ??
        notification['report_id'] ??
        notification['lost_item_id'] ??
        notification['found_item_id'] ??
        notification['related_id'] ??
        notification['target_id'];
    final data = notification['data'];
    if ((value == null || value.toString().trim().isEmpty) &&
        data is Map<String, dynamic>) {
      value = data['item_id'] ??
          data['report_id'] ??
          data['id'] ??
          data['lost_item_id'] ??
          data['found_item_id'] ??
          data['related_id'] ??
          data['target_id'];
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  String _notificationTitle(Map<String, dynamic> notification) {
    final title = notification['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;

    final type = notification['type']?.toString().trim();
    if (type != null && type.isNotEmpty) {
      return _humanizeType(type);
    }
    return 'Notification';
  }

  bool _isLostItemMatchedNotification(Map<String, dynamic> notification) {
    if (notification.isEmpty) return false;
    final combined = _combinedNotificationText(notification);
    return combined.contains('match') &&
        (combined.contains('lost') || combined.contains('lost item'));
  }

  String _combinedNotificationText(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().toLowerCase() ?? '';
    final title = _notificationTitle(notification).toLowerCase();
    final message = _notificationMessage(notification).toLowerCase();
    final status = notification['status']?.toString().toLowerCase() ?? '';
    final itemType =
        (notification['item_type'] ?? notification['report_type'])
            ?.toString()
            .toLowerCase() ??
        '';
    final data = notification['data']?.toString().toLowerCase() ?? '';

    return '$type $title $message $status $itemType $data';
  }

  void _showLostItemMatchedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFDDF4E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: Color(0xFF198754),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Item Match Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF005BAB),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Good news! Your lost item has been successfully matched.\n\n'
          'Please proceed to the Discipline Office to claim your item.\n\n'
          'Kindly bring a valid ID or proof of ownership for verification.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_notificationTitle(notification)),
        content: Text(_notificationMessage(notification)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _notificationMessage(Map<String, dynamic> notification) {
    final message = notification['message']?.toString().trim() ?? '';
    return message.isEmpty ? 'No message provided.' : message;
  }

  String _notificationTime(Map<String, dynamic> notification) {
    final raw = notification['created_at']?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour24 = local.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$year-$month-$day $hour12:$minute $period';
  }

  String _humanizeType(String type) {
    return type
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  int _compareNotificationsByDate(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
    final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}

enum _NotificationRoute {
  details,
  foundInventory,
  lostInventory,
  messages,
  profile,
}
