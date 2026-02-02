import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// 移动端通知服务实现
class NotificationServicePlatform {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(iOS: iosSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _initialized = true;
  }
  
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );
    
    const details = NotificationDetails(iOS: iosDetails);
    
    await _notifications.show(id, title, body, details, payload: payload);
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );
    
    const details = NotificationDetails(iOS: iosDetails);
    
    // 简化版本：先显示即时通知
    await _notifications.show(id, title, body, details, payload: payload);
  }
  
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }
}