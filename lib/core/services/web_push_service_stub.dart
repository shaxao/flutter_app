import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Web Push 服务 - 移动端存根实现
class WebPushService {
  static final WebPushService instance = WebPushService._();
  WebPushService._();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    if (!kIsWeb) {
      print('⚠️ Web Push 仅在 Web 环境下可用');
      _initialized = true;
      return;
    }
    
    _initialized = true;
  }
  
  /// 测试推送功能
  Future<void> testPush() async {
    if (!kIsWeb) {
      print('⚠️ 推送测试仅在 Web 环境下可用');
      return;
    }
  }
  
  /// 重置 VAPID 密钥
  Future<void> resetVapidKeys() async {
    if (!kIsWeb) {
      print('⚠️ VAPID 密钥重置仅在 Web 环境下可用');
      return;
    }
  }
  
  /// 获取推送状态
  Map<String, dynamic> getPushStatus() {
    return {
      'status': 'unsupported',
      'hasSubscription': false,
      'hasPublicKey': false,
      'notificationPermission': 'default',
      'serviceWorkerSupported': false,
      'pushManagerSupported': false,
    };
  }
  
  /// 获取推送日志
  Future<List<Map<String, dynamic>>> getPushLogs() async {
    if (!kIsWeb) return [];
    
    try {
      final baseUrl = ApiService.instance.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/push-logs'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ 获取推送日志失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ 获取推送日志异常: $e');
      return [];
    }
  }
  
  /// 解锁语音服务（用户交互后调用）
  void unlockVoiceService() {
    if (!kIsWeb) return;
    print('⚠️ 语音服务解锁仅在 Web 环境下可用');
  }
  
  /// 播放语音
  Future<void> speak(String text, {Map<String, dynamic>? config}) async {
    if (!kIsWeb) return;
    print('⚠️ 语音播放仅在 Web 环境下可用: $text');
  }
  
  /// 预加载语音
  Future<void> preloadAudio(String text, {Map<String, dynamic>? config}) async {
    if (!kIsWeb) return;
    print('⚠️ 语音预加载仅在 Web 环境下可用: $text');
  }
  
  /// 获取语音平台信息
  Map<String, dynamic> getVoicePlatformInfo() {
    return {
      'platform': 'Mobile',
      'capabilities': {},
      'recommendations': ['请在移动端使用本地通知功能'],
    };
  }
  
  /// 获取语音性能统计
  Map<String, dynamic> getVoicePerformanceStats() {
    return {
      'voice': {
        'totalCalls': 0,
        'successful': 0,
        'failed': 0,
        'successRate': '0%',
      },
      'cache': {
        'size': 0,
        'hitRate': '0%',
      },
    };
  }
  
  /// 清理语音缓存
  void clearVoiceCache() {
    if (!kIsWeb) return;
    print('⚠️ 语音缓存清理仅在 Web 环境下可用');
  }
  
  /// 初始化提醒管理器
  Future<void> initializeReminderManager() async {
    if (!kIsWeb) return;
    print('⚠️ 提醒管理器仅在 Web 环境下可用');
  }
  
  /// 刷新提醒列表
  Future<void> refreshReminders() async {
    if (!kIsWeb) return;
    print('⚠️ 提醒列表刷新仅在 Web 环境下可用');
  }
  
  /// 获取提醒统计
  Map<String, dynamic> getReminderStats() {
    return {
      'totalReminders': 0,
      'enabledReminders': 0,
      'upcomingReminders': 0,
      'preloadedCount': 0,
      'currentTime': '00:00',
      'lastTriggered': '',
      'workerActive': false,
    };
  }
  
  /// 停止提醒管理器
  void stopReminderManager() {
    if (!kIsWeb) return;
    print('⚠️ 提醒管理器停止仅在 Web 环境下可用');
  }
}