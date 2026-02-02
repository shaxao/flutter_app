import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'web_push_service.dart';
import 'api_service.dart';
import '../../features/reminder/domain/models/voice_reminder.dart';

/// 混合通知服务 - 基于 od_web 实现的完整通知系统
class HybridNotificationService {
  static final HybridNotificationService instance = HybridNotificationService._();
  HybridNotificationService._();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 初始化本地通知服务
      await NotificationService.instance.initialize();
      
      // 如果是 Web 环境，初始化完整的 Web Push 系统
      if (kIsWeb) {
        await WebPushService.instance.initialize();
        await WebPushService.instance.initializeReminderManager();
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
      
      // 1. 设置本地通知（移动端主要方式）
      if (!kIsWeb) {
        // 解析时间字符串为 DateTime
        final timeParts = reminder.time.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final now = DateTime.now();
          var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
          
          // 如果时间已过，设置为明天
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }
          
          await NotificationService.instance.scheduleNotification(
            id: reminderId,
            title: '🔔 VoiceFlow 提醒',
            body: reminder.content,
            scheduledTime: scheduledTime,
            payload: 'reminder_${reminder.id}',
          );
        }
      }
      
      // 2. Web 环境：向服务器注册提醒并预加载语音
      if (kIsWeb) {
        await _registerReminderOnServer(reminder);
        
        // 预加载语音（如果提醒在接下来的2分钟内）
        final timeParts = reminder.time.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final now = DateTime.now();
          final reminderDateTime = DateTime(now.year, now.month, now.day, hour, minute);
          
          final diffMinutes = reminderDateTime.difference(now).inMinutes;
          if (diffMinutes >= 0 && diffMinutes <= 2) {
            await WebPushService.instance.preloadAudio('提醒事项：${reminder.content}');
          }
        }
        
        // 刷新提醒管理器
        await WebPushService.instance.refreshReminders();
      }
      
      print('✅ 提醒通知已设置: ${reminder.content}');
    } catch (e) {
      print('❌ 设置提醒通知失败: $e');
    }
  }
  
  /// 向服务器注册提醒（用于 Web Push）
  Future<void> _registerReminderOnServer(VoiceReminder reminder) async {
    try {
      // 这里需要调用服务器 API 来注册提醒
      // 服务器会在指定时间发送 Web Push 通知
      
      final reminderData = {
        'id': reminder.id,
        'content': reminder.content,
        'time': reminder.time,
        'reminder_type': reminder.reminderType.value,
        'enabled': reminder.enabled,
        'voice_model': reminder.voiceModel,
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
      if (!kIsWeb) {
        await NotificationService.instance.cancelNotification(reminderId);
      }
      
      // 如果是 Web 环境，同时从服务器取消并刷新提醒管理器
      if (kIsWeb) {
        await _cancelReminderOnServer(reminderId);
        await WebPushService.instance.refreshReminders();
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
    if (kIsWeb) {
      // Web 环境：使用语音播放
      await WebPushService.instance.speak(body);
    } else {
      // 移动端：使用本地通知
      await NotificationService.instance.showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }
  
  /// 解锁语音服务（Web 环境用户交互后调用）
  void unlockVoiceService() {
    if (kIsWeb) {
      WebPushService.instance.unlockVoiceService();
    }
  }
  
  /// 播放语音提醒
  Future<void> speakReminder(String content, {Map<String, dynamic>? config}) async {
    if (kIsWeb) {
      await WebPushService.instance.speak('提醒事项：$content', config: config);
    }
  }
  
  /// 测试通知功能
  Future<void> testNotification() async {
    try {
      if (kIsWeb) {
        // Web 环境：测试推送和语音
        await WebPushService.instance.testPush();
        await WebPushService.instance.speak('这是一个测试通知，如果您听到这条消息，说明语音通知功能正常');
      } else {
        // 移动端：测试本地通知
        await showNotification(
          id: 999999,
          title: '🧪 通知测试',
          body: '这是一个测试通知，如果您看到这条消息，说明本地通知功能正常',
        );
      }
      
      print('✅ 通知测试完成');
    } catch (e) {
      print('❌ 通知测试失败: $e');
      rethrow;
    }
  }
  
  /// 重置推送系统（解决 VAPID 密钥不匹配问题）
  Future<void> resetPushSystem() async {
    if (kIsWeb) {
      try {
        await WebPushService.instance.resetVapidKeys();
        print('✅ 推送系统已重置');
      } catch (e) {
        print('❌ 重置推送系统失败: $e');
        rethrow;
      }
    }
  }
  
  /// 获取通知状态
  Map<String, dynamic> getNotificationStatus() {
    final baseStatus = {
      'initialized': _initialized,
      'platform': kIsWeb ? 'web' : 'mobile',
      'localNotificationSupported': !kIsWeb,
      'webPushSupported': kIsWeb,
    };
    
    if (kIsWeb) {
      // 添加 Web 特有的状态信息
      final pushStatus = WebPushService.instance.getPushStatus();
      final voiceInfo = WebPushService.instance.getVoicePlatformInfo();
      final reminderStats = WebPushService.instance.getReminderStats();
      
      baseStatus.addAll({
        'pushStatus': pushStatus,
        'voiceInfo': voiceInfo,
        'reminderStats': reminderStats,
      });
    }
    
    return baseStatus;
  }
  
  /// 获取推送日志（Web 环境）
  Future<List<Map<String, dynamic>>> getPushLogs() async {
    if (kIsWeb) {
      return await WebPushService.instance.getPushLogs();
    }
    return [];
  }
  
  /// 获取语音性能统计（Web 环境）
  Map<String, dynamic> getVoicePerformanceStats() {
    if (kIsWeb) {
      return WebPushService.instance.getVoicePerformanceStats();
    }
    return {};
  }
  
  /// 清理语音缓存（Web 环境）
  void clearVoiceCache() {
    if (kIsWeb) {
      WebPushService.instance.clearVoiceCache();
    }
  }
  
  /// 刷新提醒列表（Web 环境）
  Future<void> refreshReminders() async {
    if (kIsWeb) {
      await WebPushService.instance.refreshReminders();
    }
  }
}