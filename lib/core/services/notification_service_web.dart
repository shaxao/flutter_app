import 'dart:html' as html;

/// Web端通知服务实现
class NotificationServicePlatform {
  bool _initialized = false;
  bool _webNotificationPermissionGranted = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (html.Notification.supported) {
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
    
    _initialized = true;
  }
  
  Future<bool> requestPermission() async {
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      _webNotificationPermissionGranted = permission == 'granted';
      return _webNotificationPermissionGranted;
    }
    return false;
  }
  
  Future<void> showNotification({
    required int id,
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
      
      if (html.Notification.permission == 'default') {
        final permission = await html.Notification.requestPermission();
        _webNotificationPermissionGranted = permission == 'granted';
      } else {
        _webNotificationPermissionGranted = html.Notification.permission == 'granted';
      }
      
      if (_webNotificationPermissionGranted) {
        try {
          final notification = html.Notification(title, body: body, icon: '/favicon.png');
          
          notification.onClick.listen((event) {
            print('通知被点击: $payload');
            notification.close();
          });
          
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
    
    Future.delayed(const Duration(seconds: 3), () {
      notification.style.animation = 'slideOut 0.3s ease-in';
      Future.delayed(const Duration(milliseconds: 300), () {
        notification.remove();
        style.remove();
      });
    });
    
    print('备用通知已显示: $title - $body');
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    print('Web 环境定时通知: $title - $body (${scheduledTime.toString()})');
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;
    
    Future.delayed(delay, () {
      showNotification(id: id, title: title, body: body, payload: payload);
    });
  }
  
  Future<void> cancelNotification(int id) async {
    // Web环境无法取消特定通知
  }
  
  Future<void> cancelAllNotifications() async {
    // Web环境无法取消所有通知
  }
}