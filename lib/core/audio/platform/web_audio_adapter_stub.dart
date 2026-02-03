import '../audio_playback_system.dart';
import '../audio_config.dart';

/// Web音频适配器存根（用于移动平台）
class WebAudioAdapter extends BaseAudioAdapter {
  @override
  String get platformName => 'web_stub';

  @override
  bool get isSupported => false;

  @override
  List<PlaybackStrategy> get supportedStrategies => [];

  Future<void> initialize() async {
    throw UnsupportedError('Web适配器在移动平台不可用');
  }

  @override
  Future<PlaybackResult> playAudio(String filePath, {PlaybackConfig? config}) async {
    return PlaybackResult.notSupported;
  }

  @override
  Future<void> stopPlayback() async {}
}