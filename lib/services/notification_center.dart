import 'package:flutter/foundation.dart';

final ValueNotifier<int> notificationCenterVersion = ValueNotifier<int>(0);

final List<Map<String, dynamic>> _localNotifications = [];

List<Map<String, dynamic>> getLocalNotifications() {
  return _localNotifications
      .map((notification) => Map<String, dynamic>.from(notification))
      .toList();
}

void addLocalNotification({
  required String type,
  required String title,
  required String message,
  String? reportType,
  String? itemId,
}) {
  _localNotifications.insert(0, {
    'id': 'local:${DateTime.now().microsecondsSinceEpoch}',
    'type': type,
    'title': title,
    'message': message,
    'report_type': reportType,
    'item_type': reportType,
    'item_id': itemId,
    'created_at': DateTime.now().toIso8601String(),
    'is_read': false,
    'is_local': true,
  });
  notificationCenterVersion.value++;
}

void markLocalNotificationAsRead(String id) {
  final index = _localNotifications.indexWhere(
    (notification) => notification['id']?.toString() == id,
  );
  if (index == -1) return;
  _localNotifications[index] = {
    ..._localNotifications[index],
    'is_read': true,
  };
  notificationCenterVersion.value++;
}
