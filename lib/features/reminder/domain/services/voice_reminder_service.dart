import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/voice_reminder.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/voice_service.dart';

class VoiceReminderService {
  static final VoiceReminderService _instance = VoiceReminderService._internal();
  factory VoiceReminderService() => _instance;
  VoiceReminderService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NotificationService _notificationService = NotificationService.instance;
  final VoiceService _voiceService = VoiceService.instance;
  
  Timer? _schedulerTimer;
  List<VoiceReminder> _scheduledReminders = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize TTS
      await _initializeTTS();
      
      // Initialize notifications
      await _notificationService.initialize();
      
      // Start reminder scheduler
      _startScheduler();
      
      _isInitialized = true;
      debugPrint('[VoiceReminderService] Initialized successfully');
    } catch (e) {
      debugPrint('[VoiceReminderService] Initialization failed: $e');
    }
  }

  Future<void> _initializeTTS() async {
    if (kIsWeb) return; // Skip TTS initialization on web

    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
        );
      }

      debugPrint('[VoiceReminderService] TTS initialized');
    } catch (e) {
      debugPrint('[VoiceReminderService] TTS initialization failed: $e');
    }
  }

  void updateScheduledReminders(List<VoiceReminder> reminders) {
    _scheduledReminders = reminders.where((r) => r.enabled).toList();
    debugPrint('[VoiceReminderService] Updated ${_scheduledReminders.length} scheduled reminders');
  }

  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkReminders();
    });
    debugPrint('[VoiceReminderService] Scheduler started');
  }

  void _checkReminders() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final reminder in _scheduledReminders) {
      if (reminder.time == currentTime) {
        _triggerReminder(reminder);
      }
    }
  }

  Future<void> _triggerReminder(VoiceReminder reminder) async {
    debugPrint('[VoiceReminderService] Triggering reminder: ${reminder.content}');

    try {
      switch (reminder.reminderType) {
        case ReminderType.system:
          await _sendSystemNotification(reminder);
          break;
        case ReminderType.aiVoice:
          await _playAIVoice(reminder);
          await _sendSystemNotification(reminder);
          break;
        case ReminderType.customAudio:
          await _playCustomAudio(reminder);
          await _sendSystemNotification(reminder);
          break;
      }
    } catch (e) {
      debugPrint('[VoiceReminderService] Failed to trigger reminder: $e');
      // Fallback to system notification
      await _sendSystemNotification(reminder);
    }
  }

  Future<void> _sendSystemNotification(VoiceReminder reminder) async {
    await _notificationService.showNotification(
      id: reminder.id ?? DateTime.now().millisecondsSinceEpoch,
      title: '食材过期提醒',
      body: reminder.content,
      payload: 'voice_reminder:${reminder.id}',
    );
  }

  Future<void> _playAIVoice(VoiceReminder reminder) async {
    try {
      final text = '提醒事项：${reminder.content}';
      await _voiceService.speak(text);
      debugPrint('[VoiceReminderService] AI voice played: $text');
    } catch (e) {
      debugPrint('[VoiceReminderService] Failed to play AI voice: $e');
    }
  }

  Future<void> _playCustomAudio(VoiceReminder reminder) async {
    if (reminder.audioFilePath == null || reminder.audioFilePath!.isEmpty) {
      debugPrint('[VoiceReminderService] No audio file path for custom audio');
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(reminder.audioFilePath!));
      debugPrint('[VoiceReminderService] Custom audio played: ${reminder.audioFilePath}');
    } catch (e) {
      debugPrint('[VoiceReminderService] Failed to play custom audio: $e');
    }
  }

  // Test methods
  Future<void> testSystemNotification() async {
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '系统通知测试',
      body: '这是一个测试通知，如果您看到这条消息，说明通知功能正常工作。',
      payload: 'test_notification',
    );
  }

  Future<void> testVoice([String? customText]) async {
    try {
      final text = customText ?? '语音测试：系统语音功能正常工作。';
      await _voiceService.speak(text);
      debugPrint('[VoiceReminderService] Voice test completed: $text');
    } catch (e) {
      debugPrint('[VoiceReminderService] Voice test failed: $e');
    }
  }

  Future<void> testCustomAudio(String audioPath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(audioPath));
      debugPrint('[VoiceReminderService] Custom audio test completed: $audioPath');
    } catch (e) {
      debugPrint('[VoiceReminderService] Custom audio test failed: $e');
    }
  }

  // TTS Configuration
  Future<void> configureTTS({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) async {
    if (kIsWeb) return;

    try {
      if (speechRate != null) await _flutterTts.setSpeechRate(speechRate);
      if (volume != null) await _flutterTts.setVolume(volume);
      if (pitch != null) await _flutterTts.setPitch(pitch);
      if (language != null) await _flutterTts.setLanguage(language);
      
      debugPrint('[VoiceReminderService] TTS configured');
    } catch (e) {
      debugPrint('[VoiceReminderService] TTS configuration failed: $e');
    }
  }

  // Status methods
  bool get isInitialized => _isInitialized;
  bool get isSchedulerRunning => _schedulerTimer?.isActive ?? false;
  int get scheduledCount => _scheduledReminders.length;

  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isSchedulerRunning': isSchedulerRunning,
      'scheduledCount': scheduledCount,
      'ttsAvailable': !kIsWeb,
      'audioPlayerAvailable': true,
      'notificationsAvailable': true,
    };
  }

  void dispose() {
    _schedulerTimer?.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _isInitialized = false;
    debugPrint('[VoiceReminderService] Disposed');
  }
}