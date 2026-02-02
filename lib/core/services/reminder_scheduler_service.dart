import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'voice_service.dart';
import 'hybrid_notification_service.dart';
import '../../features/reminder/domain/models/voice_reminder.dart';

/// 提醒调度服务 - 管理所有提醒的调度和执行
class ReminderSchedulerService {
  static final ReminderSchedulerService instance = ReminderSchedulerService._();
  ReminderSchedulerService._();
  
  final List<Timer> _activeTimers = [];
  final List<VoiceReminder> _scheduledReminders = [];
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    _initialized = true;
    print('✅ 提醒调度服务初始化完成');
  }
  
  /// 调度单个提醒
  Future<void> scheduleReminder(VoiceReminder reminder) async {
    if (!reminder.enabled) {
      print('⚠️ 提醒已禁用，跳过调度: ${reminder.content}');
      return;
    }
    
    try {
      // 计算下次提醒时间
      final nextReminderTime = _calculateNextReminderTime(reminder);
      if (nextReminderTime == null) {
        print('⚠️ 无法计算下次提醒时间: ${reminder.content}');
        return;
      }
      
      final now = DateTime.now();
      if (nextReminderTime.isBefore(now)) {
        print('⚠️ 提醒时间已过期: ${reminder.content}');
        return;
      }
      
      // 调度混合通知（本地 + 服务器推送）
      await HybridNotificationService.instance.scheduleReminderNotification(reminder);
      
      // 调度语音播报（使用 Timer）
      final delay = nextReminderTime.difference(now);
      final timer = Timer(delay, () async {
        await _executeReminder(reminder);
      });
      
      _activeTimers.add(timer);
      _scheduledReminders.add(reminder);
      
      print('✅ 提醒已调度: ${reminder.content} 于 ${nextReminderTime.toString()}');
    } catch (e) {
      print('❌ 调度提醒失败: $e');
    }
  }
  
  /// 批量调度提醒
  Future<void> scheduleReminders(List<VoiceReminder> reminders) async {
    print('📅 开始批量调度 ${reminders.length} 个提醒');
    
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
    
    print('✅ 批量调度完成，共调度 ${_scheduledReminders.length} 个有效提醒');
  }
  
  /// 取消所有调度的提醒
  void cancelAllReminders() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _scheduledReminders.clear();
    
    // 取消系统通知
    NotificationService.instance.cancelAllNotifications();
    
    print('✅ 已取消所有调度的提醒');
  }
  
  /// 取消特定提醒
  void cancelReminder(int reminderId) {
    _scheduledReminders.removeWhere((r) => r.id == reminderId);
    NotificationService.instance.cancelNotification(reminderId);
    print('✅ 已取消提醒: $reminderId');
  }
  
  /// 执行提醒
  Future<void> _executeReminder(VoiceReminder reminder) async {
    try {
      print('🔔 执行提醒: ${reminder.content}');
      
      // 语音播报
      await VoiceService.instance.speakReminder(
        type: reminder.type,
        content: reminder.content,
      );
      
      // 如果是重复提醒，重新调度下次提醒
      if (reminder.repeatDays.isNotEmpty) {
        await scheduleReminder(reminder);
      }
      
    } catch (e) {
      print('❌ 执行提醒失败: $e');
    }
  }
  
  /// 计算下次提醒时间
  DateTime? _calculateNextReminderTime(VoiceReminder reminder) {
    final now = DateTime.now();
    final reminderTime = reminder.time;
    
    // 今天的提醒时间
    var nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    
    // 如果今天的时间已过，检查是否有重复设置
    if (nextTime.isBefore(now)) {
      if (reminder.repeatDays.isEmpty) {
        // 一次性提醒，时间已过
        return null;
      }
      
      // 寻找下一个重复日期
      for (int i = 1; i <= 7; i++) {
        final checkDate = now.add(Duration(days: i));
        final weekday = checkDate.weekday;
        
        if (reminder.repeatDays.contains(weekday)) {
          nextTime = DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
            reminderTime.hour,
            reminderTime.minute,
          );
          break;
        }
      }
    } else {
      // 今天的时间还没到，检查今天是否在重复日期中
      if (reminder.repeatDays.isNotEmpty && !reminder.repeatDays.contains(now.weekday)) {
        // 今天不在重复日期中，寻找下一个重复日期
        for (int i = 1; i <= 7; i++) {
          final checkDate = now.add(Duration(days: i));
          final weekday = checkDate.weekday;
          
          if (reminder.repeatDays.contains(weekday)) {
            nextTime = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day,
              reminderTime.hour,
              reminderTime.minute,
            );
            break;
          }
        }
      }
    }
    
    return nextTime.isAfter(now) ? nextTime : null;
  }
  
  /// 获取调度状态
  Map<String, dynamic> getScheduleStatus() {
    return {
      'activeTimers': _activeTimers.length,
      'scheduledReminders': _scheduledReminders.length,
      'reminders': _scheduledReminders.map((r) => {
        'id': r.id,
        'content': r.content,
        'time': r.time.toString(),
        'enabled': r.enabled,
      }).toList(),
    };
  }
  
  /// 测试提醒功能
  Future<void> testReminder() async {
    try {
      print('🧪 开始测试提醒功能');
      
      // 创建一个测试提醒（5秒后触发）
      final testTime = DateTime.now().add(const Duration(seconds: 5));
      final testReminder = VoiceReminder(
        id: 999999,
        content: '这是一个测试提醒',
        time: testTime,
        type: 'test',
        enabled: true,
        repeatDays: [],
        createdAt: DateTime.now(),
      );
      
      await scheduleReminder(testReminder);
      print('✅ 测试提醒已调度，将在5秒后触发');
      
    } catch (e) {
      print('❌ 测试提醒失败: $e');
    }
  }
}