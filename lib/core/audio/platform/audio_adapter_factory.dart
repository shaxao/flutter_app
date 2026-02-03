import 'dart:io';
import 'package:flutter/foundation.dart';
import '../audio_playback_system.dart';

// 条件导入 - 根据平台导入不同的实现
import 'audio_adapter_factory_web.dart' if (dart.library.io) 'audio_adapter_factory_mobile.dart';

/// 音频适配器工厂
class AudioAdapterFactory {
  /// 创建平台特定的音频适配器
  static Future<AudioAdapter?> createAdapter() async {
    try {
      return await createPlatformAdapter();
    } catch (e) {
      print('❌ 创建音频适配器失败: $e');
      return null;
    }
  }
}