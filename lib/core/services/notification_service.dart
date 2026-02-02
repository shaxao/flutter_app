import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// 本地通知服务 - iOS原生通知支持
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  bool _webNotificationPermissionGranted = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    if (kIsWeb) {
      // Web 环境初始化
      await _initializeWebNotifications();
    } else {
      // 移动端初始化
      await _initializeMobileNotifications();
    }
    
    _initialized = true;
  }
  
  Future<void> _initializeWebNotifications() async {
    try {
      // 检查浏览器是否支持通知
      if (html.Notification.supported) {
        // 如果权限是默认状态，先请求权限
        if (html.Notification.permission == 'default') {
          final permission = await html.Notification.requestPermission();
          _webNotificationPermissionGranted = permission == 'granted';
          print('Web 通知权限请求结果: $permission');
        } else {
          _webNotificationPermissionGranted = html.Notification.permission == 'granted';
          print('Web 通知权限状态: ${html.Notification.permission}');
        }
      } else {
        print('浏览器不支持通知功能');
      }
    } catch (e) {
      print('Web 通知初始化失败: $e');
    }
  }
  
  Future<void> _initializeMobileNotifications() async {
    // iOS 设置
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
  }
  
  /// 请求通知权限
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        _webNotificationPermissionGranted = permission == 'granted';
        return _webNotificationPermissionGranted;
      }
      return false;
    }
    
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  
  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      await _showWebNotification(title: title, body: body, payload: payload);
    } else {
      await _showMobileNotification(id: id, title: title, body: body, payload: payload);
    }
  }
  
  Future<void> _showWebNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!html.Notification.supported) {
        print('浏览器不支持通知功能，显示备用通知');
        _showFallbackNotification(title, body);
        return;
      }
      
      // 检查并请求权限
      if (html.Notification.permission == 'default') {
        final permission = await html.Notification.requestPermission();
        _webNotificationPermissionGranted = permission == 'granted';
        print('通知权限请求结果: $permission');
      } else {
        _webNotificationPermissionGranted = html.Notification.permission == 'granted';
      }
      
      if (_webNotificationPermissionGranted) {
        try {
          final notification = html.Notification(title, body: body, icon: '/favicon.png');
          
          // 设置点击事件
          notification.onClick.listen((event) {
            print('通知被点击: $payload');
            notification.close();
          });
          
          // 5秒后自动关闭
          Future.delayed(const Duration(seconds: 5), () {
            try {
              notification.close();
            } catch (e) {
              print('关闭通知失败: $e');
            }
          });
          
          print('✅ Web 原生通知已显示: $title - $body');
        } catch (e) {
          print('创建原生通知失败: $e，显示备用通知');
          _showFallbackNotification(title, body);
        }
      } else {
        print('通知权限被拒绝，显示备用通知');
        _showFallbackNotification(title, body);
      }
    } catch (e) {
      print('显示 Web 通知失败: $e，显示备用通知');
      _showFallbackNotification(title, body);
    }
  }
  
  void _showFallbackNotification(String title, String body) {
    // 创建一个临时的视觉通知
    final notification = html.DivElement()
      ..className = 'flutter-notification'
      ..style.cssText = '''
        position: fixed;
        top: 20px;
        right: 20px;
        background: #2563eb;
        color: white;
        padding: 16px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 10000;
        max-width: 300px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        font-size: 14px;
        line-height: 1.4;
        animation: slideIn 0.3s ease-out;
      '''
      ..innerHtml = '''
        <div style="font-weight: 600; margin-bottom: 4px;">$title</div>
        <div style="opacity: 0.9;">$body</div>
      ''';
    
    // 添加动画样式
    final style = html.StyleElement()
      ..text = '''
        @keyframes slideIn {
          from { transform: translateX(100%); opacity: 0; }
          to { transform: translateX(0); opacity: 1; }
        }
        @keyframes slideOut {
          from { transform: translateX(0); opacity: 1; }
          to { transform: translateX(100%); opacity: 0; }
        }
      ''';
    
    html.document.head?.append(style);
    html.document.body?.append(notification);
    
    // 3秒后移除
    Future.delayed(const Duration(seconds: 3), () {
      notification.style.animation = 'slideOut 0.3s ease-in';
      Future.delayed(const Duration(milliseconds: 300), () {
        notification.remove();
        style.remove();
      });
    });
    
    print('备用通知已显示: $title - $body');
  }
  
  Future<void> _showMobileNotification({
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
  
  /// 调度定时通知
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('Web 环境定时通知: $title - $body (${scheduledTime.toString()})');
      // Web 环境可以使用 setTimeout 实现定时通知
      final delay = scheduledTime.difference(DateTime.now());
      if (delay.isNegative) return;
      
      Future.delayed(delay, () {
        showNotification(id: id, title: title, body: body, payload: payload);
      });
    } else {
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
  }
  
  /// 取消通知
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }
  
  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }
  
  void _onNotificationTap(NotificationResponse response) {
    // 处理通知点击事件
    print('Notification tapped: ${response.payload}');
  }
}
