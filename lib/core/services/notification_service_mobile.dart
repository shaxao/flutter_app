import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

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
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // 请求通知权限
    await requestPermission();
    
    _initialized = true;
    print('✅ 移动端通知服务初始化完成');
  }
  
  Future<bool> requestPermission() async {
    try {
      // iOS 权限请求
      final iosPermission = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      // Android 权限请求
      final androidPermission = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      // 系统级权限请求
      final systemPermission = await Permission.notification.request();
      
      final isGranted = (iosPermission ?? true) && 
                       (androidPermission ?? true) && 
                       systemPermission.isGranted;
      
      print(isGranted ? '✅ 通知权限已获取' : '❌ 通知权限被拒绝');
      return isGranted;
    } catch (e) {
      print('❌ 请求通知权限失败: $e');
      return false;
    }
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'voiceflow_reminder',
      );
      
      const androidDetails = AndroidNotificationDetails(
        'voiceflow_reminders',
        'VoiceFlow 提醒',
        channelDescription: 'VoiceFlow 语音提醒通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      const details = NotificationDetails(
        iOS: iosDetails,
        android: androidDetails,
      );
      
      await _notifications.show(id, title, body, details, payload: payload);
      print('✅ 通知已显示: $title');
    } catch (e) {
      print('❌ 显示通知失败: $e');
    }
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // 检查时间是否在未来
      if (scheduledTime.isBefore(DateTime.now())) {
        print('⚠️ 调度时间已过期，直接显示通知');
        await showNotification(id: id, title: title, body: body, payload: payload);
        return;
      }
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'voiceflow_reminder',
      );
      
      const androidDetails = AndroidNotificationDetails(
        'voiceflow_reminders',
        'VoiceFlow 提醒',
        channelDescription: 'VoiceFlow 语音提醒通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      const details = NotificationDetails(
        iOS: iosDetails,
        android: androidDetails,
      );
      
      // 转换为时区感知的时间
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ 通知已调度: $title 于 ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ 调度通知失败: $e');
      // 如果调度失败，尝试显示即时通知
      await showNotification(id: id, title: title, body: body, payload: payload);
    }
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