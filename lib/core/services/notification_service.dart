import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'notification_service_web.dart' if (dart.library.io) 'notification_service_mobile.dart';

/// 本地通知服务 - iOS原生通知支持
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  
  final NotificationServicePlatform _platform = NotificationServicePlatform();
  
  Future<void> initialize() async {
    await _platform.initialize();
  }
  
  /// 请求通知权限
  Future<bool> requestPermission() async {
    return await _platform.requestPermission();
  }
  
  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _platform.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
  
  /// 调度定时通知
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _platform.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }
  
  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _platform.cancelNotification(id);
  }
  
  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _platform.cancelAllNotifications();
  }
}