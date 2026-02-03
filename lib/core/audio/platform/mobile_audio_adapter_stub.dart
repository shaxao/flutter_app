import '../audio_playback_system.dart';
import '../audio_config.dart';

/// 移动音频适配器存根（用于Web平台）
class AndroidAudioAdapter extends BaseAudioAdapter {
  @override
  String get platformName => 'android_stub';

  @override
  bool get isSupported => false;

  @override
  List<PlaybackStrategy> get supportedStrategies => [];

  Future<void> initialize() async {
    throw UnsupportedError('Android适配器在Web平台不可用');
  }

  @override
  Future<PlaybackResult> playAudio(String filePath, {PlaybackConfig? config}) async {
    return PlaybackResult.notSupported;
  }

  @override
  Future<void> stopPlayback() async {}
}

class IOSAudioAdapter extends BaseAudioAdapter {
  @override
  String get platformName => 'ios_stub';

  @override
  bool get isSupported => false;

  @override
  List<PlaybackStrategy> get supportedStrategies => [];

  Future<void> initialize() async {
    throw UnsupportedError('iOS适配器在Web平台不可用');
  }

  @override
  Future<PlaybackResult> playAudio(String filePath, {PlaybackConfig? config}) async {
    return PlaybackResult.notSupported;
  }

  @override
  Future<void> stopPlayback() async {}
}