import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../audio_playback_system.dart';
import 'web_audio_adapter.dart';

/// 创建Web平台的音频适配器
Future<AudioAdapter?> createPlatformAdapter() async {
  if (!kIsWeb) return null;
  
  try {
    final adapter = WebAudioAdapter();
    await adapter.initialize();
    return adapter;
  } catch (e) {
    print('⚠️ 创建Web音频适配器失败: $e');
    return null;
  }
}