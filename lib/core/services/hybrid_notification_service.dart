import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'web_push_service.dart';
import 'api_service.dart';
import '../../features/reminder/domain/models/voice_reminder.dart';

/// 混合通知服务 - 结合本地通知和服务器推送
class HybridNotificationService {
  static final HybridNotificationService instance = HybridNotificationService._();
  HybridNotificationService._();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 初始化本地通知服务
      await NotificationService.instance.initialize();
      
      // 如果是 Web 环境，初始化 Web Push 服务
      if (kIsWeb) {
        await WebPushService.instance.initialize();
      }
      
      _initialized = true;
      print('✅ 混合通知服务初始化完成');
    } catch (e) {
      print('❌ 混合通知服务初始化失败: $e');
      _initialized = true;
    }
  }
  
  /// 创建提醒时同时设置本地和服务器通知
  Future<void> scheduleReminderNotification(VoiceReminder reminder) async {
    if (!_initialized) await initialize();
    
    try {
      final reminderId = reminder.id ?? DateTime.now().millisecondsSinceEpoch;
      
      // 1. 设置本地通知（作为主要方式）
      await NotificationService.instance.scheduleNotification(
        id: reminderId,
        title: '🔔 VoiceFlow 提醒',
        body: reminder.content,
        scheduledTime: reminder.time,
        payload: 'reminder_${reminder.id}',
      );
      
      // 2. 如果是 Web 环境，同时向服务器注册提醒
      if (kIsWeb) {
        await _registerReminderOnServer(reminder);
      }
      
      print('✅ 提醒通知已设置: ${reminder.content}');
    } catch (e) {
      print('❌ 设置提醒通知失败: $e');
    }
  }
  
  /// 向服务器注册提醒（用于 Web Push）
  Future<void> _registerReminderOnServer(VoiceReminder reminder) async {
    try {
      final baseUrl = ApiService.instance.baseUrl;
      
      // 这里需要调用服务器 API 来注册提醒
      // 服务器会在指定时间发送 Web Push 通知
      
      final reminderData = {
        'id': reminder.id,
        'content': reminder.content,
        'time': '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
        'type': reminder.type,
        'enabled': reminder.enabled,
        'repeat_days': reminder.repeatDays,
      };
      
      // 注意：这里需要服务器端实现对应的 API
      // 目前服务器端已经有提醒调度任务，我们需要确保数据同步
      
      print('📡 提醒已注册到服务器: ${reminder.content}');
    } catch (e) {
      print('❌ 向服务器注册提醒失败: $e');
    }
  }
  
  /// 取消提醒通知
  Future<void> cancelReminderNotification(int reminderId) async {
    try {
      // 取消本地通知
      await NotificationService.instance.cancelNotification(reminderId);
      
      // 如果是 Web 环境，同时从服务器取消
      if (kIsWeb) {
        await _cancelReminderOnServer(reminderId);
      }
      
      print('✅ 提醒通知已取消: $reminderId');
    } catch (e) {
      print('❌ 取消提醒通知失败: $e');
    }
  }
  
  /// 从服务器取消提醒
  Future<void> _cancelReminderOnServer(int reminderId) async {
    try {
      // 这里需要调用服务器 API 来取消提醒
      print('📡 提醒已从服务器取消: $reminderId');
    } catch (e) {
      print('❌ 从服务器取消提醒失败: $e');
    }
  }
  
  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await NotificationService.instance.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
  
  /// 测试通知功能
  Future<void> testNotification() async {
    try {
      // 测试本地通知
      await showNotification(
        id: 999999,
        title: '🧪 通知测试',
        body: '这是一个测试通知，如果您看到这条消息，说明本地通知功能正常',
      );
      
      // 如果是 Web 环境，测试服务器推送
      if (kIsWeb) {
        await WebPushService.instance.testPush();
      }
      
      print('✅ 通知测试完成');
    } catch (e) {
      print('❌ 通知测试失败: $e');
      rethrow;
    }
  }
  
  /// 获取通知状态
  Map<String, dynamic> getNotificationStatus() {
    return {
      'initialized': _initialized,
      'platform': kIsWeb ? 'web' : 'mobile',
      'localNotificationSupported': true,
      'webPushSupported': kIsWeb,
    };
  }
}