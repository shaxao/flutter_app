import 'voice_service_web.dart' if (dart.library.io) 'voice_service_mobile.dart';

/// 语音合成服务 - 支持后台和锁屏播报
class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();
  
  final VoiceServicePlatform _platform = VoiceServicePlatform();
  
  Future<void> initialize() async {
    await _platform.initialize();
  }
  
  /// 播报文本
  Future<void> speak(String text) async {
    await _platform.speak(text);
  }
  
  /// 停止播报
  Future<void> stop() async {
    await _platform.stop();
  }
  
  /// 暂停播报
  Future<void> pause() async {
    await _platform.pause();
  }
  
  /// 检查并播报提醒（后台任务调用）
  static Future<void> checkAndPlayReminders() async {
    // TODO: 从数据库读取当前时间的提醒
    // TODO: 调用 speak() 播报
    
    final now = DateTime.now();
    print('Checking reminders at: $now');
    
    // 示例：播报提醒
    await instance.speak('您有新的排班提醒');
  }
  
  /// 播报提醒内容
  Future<void> speakReminder({
    required String type,
    required String content,
  }) async {
    String message = '';
    
    switch (type) {
      case 'shift_start':
        message = '上班提醒：$content';
        break;
      case 'shift_end':
        message = '下班提醒：$content';
        break;
      case 'break':
        message = '休息提醒：$content';
        break;
      case 'custom':
        message = content;
        break;
      default:
        message = content;
    }
    
    await speak(message);
  }
}
