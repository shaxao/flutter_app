import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Web Push 服务 - 处理服务器推送订阅
class WebPushService {
  static final WebPushService instance = WebPushService._();
  WebPushService._();
  
  String? _publicKey;
  String? _subscription;
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
      // 获取服务器的 VAPID 公钥
      await _fetchVapidPublicKey();
      
      if (_publicKey != null) {
        // 注册 Service Worker 和订阅推送
        await _registerServiceWorker();
        await _subscribeToPush();
      }
    } catch (e) {
      print('❌ Web Push 初始化失败: $e');
    }
  }
  
  Future<void> _fetchVapidPublicKey() async {
    try {
      final baseUrl = ApiService.instance.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/vapid-public-key'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _publicKey = data['publicKey'];
        print('✅ 获取 VAPID 公钥成功');
      } else {
        print('❌ 获取 VAPID 公钥失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取 VAPID 公钥异常: $e');
    }
  }
  
  Future<void> _registerServiceWorker() async {
    if (!kIsWeb) return;
    
    try {
      // 在 Web 环境中注册 Service Worker
      // 这需要在 web/sw.js 中实现
      print('📝 注册 Service Worker...');
      // 实际的 Service Worker 注册需要在 JavaScript 中完成
    } catch (e) {
      print('❌ Service Worker 注册失败: $e');
    }
  }
  
  Future<void> _subscribeToPush() async {
    if (!kIsWeb || _publicKey == null) return;
    
    try {
      // 这里需要调用 JavaScript 代码来订阅推送
      // 由于 Flutter Web 的限制，我们需要通过 JS 互操作来实现
      print('📱 订阅推送通知...');
      
      // 模拟订阅过程（实际需要 JS 实现）
      await _sendSubscriptionToServer();
    } catch (e) {
      print('❌ 推送订阅失败: $e');
    }
  }
  
  Future<void> _sendSubscriptionToServer() async {
    try {
      final baseUrl = ApiService.instance.baseUrl;
      
      // 这里应该发送真实的订阅信息
      // 现在先发送一个测试订阅
      final subscriptionData = {
        'endpoint': 'https://fcm.googleapis.com/fcm/send/test-endpoint',
        'keys': {
          'p256dh': 'test-p256dh-key',
          'auth': 'test-auth-key',
        }
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/push-subscriptions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(subscriptionData),
      );
      
      if (response.statusCode == 200) {
        print('✅ 推送订阅已发送到服务器');
      } else {
        print('❌ 发送推送订阅失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 发送推送订阅异常: $e');
    }
  }
  
  /// 测试推送功能
  Future<void> testPush() async {
    try {
      final baseUrl = ApiService.instance.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/test-push'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        print('✅ 推送测试请求已发送');
      } else {
        print('❌ 推送测试失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 推送测试异常: $e');
    }
  }
  
  /// 重置 VAPID 密钥
  Future<void> resetVapidKeys() async {
    try {
      final baseUrl = ApiService.instance.baseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/vapid-keys'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        print('✅ VAPID 密钥已重置');
        _publicKey = null;
        // 重新初始化
        await _initializeWebPush();
      } else {
        print('❌ 重置 VAPID 密钥失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 重置 VAPID 密钥异常: $e');
    }
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
}