import 'dart:io';
import 'package:flutter/foundation.dart';
import '../audio_playback_system.dart';
import 'android_audio_adapter.dart';
import 'ios_audio_adapter.dart';

/// 创建移动平台的音频适配器
Future<AudioAdapter?> createPlatformAdapter() async {
  if (kIsWeb) return null;
  
  try {
    if (Platform.isAndroid) {
      final adapter = AndroidAudioAdapter();
      await adapter.initialize();
      return adapter;
    } else if (Platform.isIOS) {
      final adapter = IOSAudioAdapter();
      await adapter.initialize();
      return adapter;
    } else {
      print('⚠️ 不支持的移动平台');
      return null;
    }
  } catch (e) {
    print('❌ 创建移动音频适配器失败: $e');
    return null;
  }
}