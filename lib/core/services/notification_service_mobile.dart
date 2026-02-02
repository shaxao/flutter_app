import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'voice_service.dart';

/// 移动端通知服务实现 - iOS锁屏语音播放兼容版本
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
  
  /// 显示带语音播放功能的通知
  Future<void> showVoiceNotification({
    required int id,
    required String title,
    required String body,
    String? voiceText,
    String? payload,
  }) async {
    try {
      // 先尝试直接播放语音
      if (voiceText != null && voiceText.isNotEmpty) {
        await _playVoiceInBackground(voiceText);
      }
      
      // 然后显示通知（作为备选和用户交互方式）
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'voiceflow_reminder',
        threadIdentifier: 'voice_reminder',
      );
      
      const androidDetails = AndroidNotificationDetails(
        'voiceflow_voice_reminders',
        'VoiceFlow 语音提醒',
        channelDescription: 'VoiceFlow 语音提醒通知，支持语音播放',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
      );
      
      const details = NotificationDetails(
        iOS: iosDetails,
        android: androidDetails,
      );
      
      // 将语音文本包含在payload中
      final voicePayload = payload ?? '';
      final fullPayload = voiceText != null 
          ? 'voice:$voiceText|$voicePayload'
          : voicePayload;
      
      await _notifications.show(id, title, body, details, payload: fullPayload);
      print('✅ 语音通知已显示: $title');
    } catch (e) {
      print('❌ 显示语音通知失败: $e');
    }
  }
  
  /// 在后台播放语音（锁屏状态）
  Future<void> _playVoiceInBackground(String text) async {
    try {
      // 使用语音服务播放
      await VoiceService.instance.speak(text);
      
      // 如果是iOS，还可以尝试使用原生方法
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          const platform = MethodChannel('voiceflow/voice');
          await platform.invokeMethod('speakInBackground', {'text': text});
        } catch (e) {
          print('⚠️ 原生语音播放不可用，已使用Flutter TTS: $e');
          // 不抛出错误，因为Flutter TTS已经播放了
        }
      }
      
      print('✅ 后台语音播放完成');
    } catch (e) {
      print('❌ 后台语音播放失败: $e');
      // 尝试系统提示音作为最后备选
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (e2) {
        print('❌ 系统提示音也失败: $e2');
      }
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
  
  /// 调度语音提醒通知
  Future<void> scheduleVoiceNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? voiceText,
    String? payload,
  }) async {
    try {
      // 检查时间是否在未来
      if (scheduledTime.isBefore(DateTime.now())) {
        print('⚠️ 调度时间已过期，直接显示语音通知');
        await showVoiceNotification(
          id: id, 
          title: title, 
          body: body, 
          voiceText: voiceText,
          payload: payload,
        );
        return;
      }
      
      // 将语音文本包含在payload中，以便通知触发时播放
      final voicePayload = payload ?? '';
      final fullPayload = voiceText != null 
          ? 'voice:$voiceText|$voicePayload'
          : voicePayload;
      
      // 使用标准调度方法，但在通知触发时会播放语音
      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: fullPayload,
      );
      
      print('✅ 语音提醒已调度: $title 于 ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ 调度语音提醒失败: $e');
    }
  }
  
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  void _onNotificationTap(NotificationResponse response) {
    print('📱 通知被点击: ${response.payload}');
    
    try {
      final payload = response.payload ?? '';
      
      // 检查是否包含语音文本
      if (payload.startsWith('voice:')) {
        final parts = payload.split('|');
        if (parts.isNotEmpty) {
          final voicePart = parts[0].substring(6); // 移除 'voice:' 前缀
          if (voicePart.isNotEmpty) {
            // 播放语音
            _playVoiceInBackground(voicePart);
          }
        }
      }
      
      // 处理动作按钮
      if (response.actionId == 'play_voice') {
        // 用户点击了播放语音按钮
        if (payload.startsWith('voice:')) {
          final parts = payload.split('|');
          if (parts.isNotEmpty) {
            final voicePart = parts[0].substring(6);
            if (voicePart.isNotEmpty) {
              _playVoiceInBackground(voicePart);
            }
          }
        }
      } else if (response.actionId == 'dismiss') {
        // 用户点击了关闭按钮
        print('用户关闭了通知');
      }
      
    } catch (e) {
      print('❌ 处理通知点击失败: $e');
    }
  }
  
  /// 获取通知服务状态
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'platform': defaultTargetPlatform.toString(),
    };
  }
}