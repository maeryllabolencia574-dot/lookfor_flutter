import 'package:flutter/material.dart';

import '../services/api_client.dart';

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
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final results = await Future.wait([
        apiClient.getNotifications(),
        apiClient.getUnreadNotificationCount(),
      ]);

      if (!mounted) return;
      setState(() {
        _notifications = (results[0] as List<dynamic>)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _unreadCount = results[1] as int;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _unreadCount = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSelected(String value) async {
    if (value == '__refresh__') {
      await _loadNotifications();
      return;
    }

    final id = int.tryParse(value);
    if (id == null) return;
    
    final notification = _notifications.firstWhere(
      (item) => item['id']?.toString() == value,
      orElse: () => const <String, dynamic>{},
    );
    final shouldShowMatchDialog = _isLostItemMatchedNotification(notification);

    try {
      await apiClient.markNotificationAsRead(id);
      await _loadNotifications();
      if (!mounted) return;
      if (shouldShowMatchDialog) {
        _showLostItemMatchedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification marked as read.')),
        );
      }
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

  String _notificationTitle(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().trim();
    if (type != null && type.isNotEmpty) {
      return _humanizeType(type);
    }
    return 'Notification';
  }

  bool _isLostItemMatchedNotification(Map<String, dynamic> notification) {
    if (notification.isEmpty) return false;

    final type = notification['type']?.toString().toLowerCase() ?? '';
    final title = _notificationTitle(notification).toLowerCase();
    final message = _notificationMessage(notification).toLowerCase();
    final status = notification['status']?.toString().toLowerCase() ?? '';
    final itemType =
        (notification['item_type'] ?? notification['report_type'])
            ?.toString()
            .toLowerCase() ??
        '';
    final combined = '$type $title $message $status $itemType';

    return combined.contains('match') &&
        (combined.contains('lost') || combined.contains('lost item'));
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
}
