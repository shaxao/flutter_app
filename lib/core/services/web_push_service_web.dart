import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Web Push 服务 - 基于 od_web 实现的完整推送系统 (Web 专用)
class WebPushService {
  static final WebPushService instance = WebPushService._();
  WebPushService._();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (kIsWeb) {
        await _initializeWebPush();
      } else {
        print('⚠️ Web Push 仅在 Web 环境下可用');
      }
      _initialized = true;
    } catch (e) {
      print('❌ Web Push 初始化失败: $e');
      _initialized = true;
    }
  }
  
  Future<void> _initializeWebPush() async {
    try {
      // 调用 JavaScript 初始化函数
      final result = await _callJavaScriptFunction('initializeWebPush');
      if (result == true) {
        print('✅ Web Push 初始化成功');
      } else {
        print('❌ Web Push 初始化失败');
      }
    } catch (e) {
      print('❌ Web Push 初始化异常: $e');
    }
  }
  
  /// 测试推送功能
  Future<void> testPush() async {
    try {
      final result = await _callJavaScriptFunction('testWebPush');
      if (result != null) {
        print('✅ 推送测试请求已发送: $result');
      } else {
        print('❌ 推送测试失败');
      }
    } catch (e) {
      print('❌ 推送测试异常: $e');
      rethrow;
    }
  }
  
  /// 重置 VAPID 密钥
  Future<void> resetVapidKeys() async {
    try {
      final result = await _callJavaScriptFunction('resetWebPushKeys');
      if (result == true) {
        print('✅ VAPID 密钥已重置');
      } else {
        print('❌ 重置 VAPID 密钥失败');
      }
    } catch (e) {
      print('❌ 重置 VAPID 密钥异常: $e');
      rethrow;
    }
  }
  
  /// 获取推送状态
  Map<String, dynamic> getPushStatus() {
    try {
      final status = _callJavaScriptFunctionSync('getWebPushStatus');
      if (status != null) {
        return Map<String, dynamic>.from(status);
      }
    } catch (e) {
      print('❌ 获取推送状态失败: $e');
    }
    
    return {
      'status': 'error',
      'hasSubscription': false,
      'hasPublicKey': false,
      'notificationPermission': 'default',
      'serviceWorkerSupported': false,
      'pushManagerSupported': false,
    };
  }
  
  /// 获取推送日志
  Future<List<Map<String, dynamic>>> getPushLogs() async {
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
    try {
      _callJavaScriptFunctionSync('unlockVoiceService');
      print('✅ 语音服务已解锁');
    } catch (e) {
      print('❌ 解锁语音服务失败: $e');
    }
  }
  
  /// 播放语音
  Future<void> speak(String text, {Map<String, dynamic>? config}) async {
    try {
      await _callJavaScriptFunction('speakText', [text, config]);
      print('✅ 语音播放请求已发送: $text');
    } catch (e) {
      print('❌ 语音播放失败: $e');
    }
  }
  
  /// 预加载语音
  Future<void> preloadAudio(String text, {Map<String, dynamic>? config}) async {
    try {
      await _callJavaScriptFunction('preloadVoiceAudio', [text, config]);
      print('✅ 语音预加载请求已发送: $text');
    } catch (e) {
      print('❌ 语音预加载失败: $e');
    }
  }
  
  /// 获取语音平台信息
  Map<String, dynamic> getVoicePlatformInfo() {
    try {
      final info = _callJavaScriptFunctionSync('getVoicePlatformInfo');
      if (info != null) {
        return Map<String, dynamic>.from(info);
      }
    } catch (e) {
      print('❌ 获取语音平台信息失败: $e');
    }
    
    return {
      'platform': 'Unknown',
      'capabilities': {},
      'recommendations': [],
    };
  }
  
  /// 获取语音性能统计
  Map<String, dynamic> getVoicePerformanceStats() {
    try {
      final stats = _callJavaScriptFunctionSync('getVoicePerformanceStats');
      if (stats != null) {
        return Map<String, dynamic>.from(stats);
      }
    } catch (e) {
      print('❌ 获取语音性能统计失败: $e');
    }
    
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
    try {
      _callJavaScriptFunctionSync('clearVoiceCache');
      print('✅ 语音缓存已清理');
    } catch (e) {
      print('❌ 清理语音缓存失败: $e');
    }
  }
  
  /// 初始化提醒管理器
  Future<void> initializeReminderManager() async {
    try {
      await _callJavaScriptFunction('initializeReminderManager');
      print('✅ 提醒管理器初始化成功');
    } catch (e) {
      print('❌ 提醒管理器初始化失败: $e');
    }
  }
  
  /// 刷新提醒列表
  Future<void> refreshReminders() async {
    try {
      await _callJavaScriptFunction('refreshReminders');
      print('✅ 提醒列表已刷新');
    } catch (e) {
      print('❌ 刷新提醒列表失败: $e');
    }
  }
  
  /// 获取提醒统计
  Map<String, dynamic> getReminderStats() {
    try {
      final stats = _callJavaScriptFunctionSync('getReminderStats');
      if (stats != null) {
        return Map<String, dynamic>.from(stats);
      }
    } catch (e) {
      print('❌ 获取提醒统计失败: $e');
    }
    
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
    try {
      _callJavaScriptFunctionSync('stopReminderManager');
      print('✅ 提醒管理器已停止');
    } catch (e) {
      print('❌ 停止提醒管理器失败: $e');
    }
  }
  
  /// 调用 JavaScript 函数（异步）
  Future<dynamic> _callJavaScriptFunction(String functionName, [List<dynamic>? args]) async {
    if (!kIsWeb) return null;
    
    try {
      final jsFunction = js.context[functionName];
      if (jsFunction == null) {
        throw Exception('JavaScript function $functionName not found');
      }
      
      if (args != null && args.isNotEmpty) {
        return jsFunction.apply(args);
      } else {
        return jsFunction.apply([]);
      }
    } catch (e) {
      print('❌ 调用 JavaScript 函数 $functionName 失败: $e');
      rethrow;
    }
  }
  
  /// 调用 JavaScript 函数（同步）
  dynamic _callJavaScriptFunctionSync(String functionName, [List<dynamic>? args]) {
    if (!kIsWeb) return null;
    
    try {
      final jsFunction = js.context[functionName];
      if (jsFunction == null) {
        throw Exception('JavaScript function $functionName not found');
      }
      
      if (args != null && args.isNotEmpty) {
        return jsFunction.apply(args);
      } else {
        return jsFunction.apply([]);
      }
    } catch (e) {
      print('❌ 调用 JavaScript 函数 $functionName 失败: $e');
      return null;
    }
  }
}