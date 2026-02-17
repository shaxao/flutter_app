import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/voice_reminder.dart';
import '../../domain/services/voice_reminder_service.dart';
import '../../data/repositories/voice_reminder_repository.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/reminder_scheduler_service.dart';

class VoiceReminderProvider extends ChangeNotifier {
  final VoiceReminderRepository _repository;
  final VoiceReminderService _voiceService;

  VoiceReminderProvider()
      : _repository = VoiceReminderRepository(ApiService.instance),
        _voiceService = VoiceReminderService();

  List<VoiceReminder> _reminders = [];
  List<TTSModel> _ttsModels = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<VoiceReminder> get reminders => List.unmodifiable(_reminders);
  List<VoiceReminder> get sortedReminders {
    final sorted = List<VoiceReminder>.from(_reminders);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }
  
  List<TTSModel> get ttsModels => List.unmodifiable(_ttsModels);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  
  Map<String, dynamic> get serviceStatus => _voiceService.getStatus();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      // Initialize voice service
      await _voiceService.initialize();
      
      // Load initial data
      await Future.wait([
        loadReminders(),
        loadTTSModels(),
      ]);
      
      _isInitialized = true;
      debugPrint('[VoiceReminderProvider] Initialized successfully');
    } catch (e) {
      _setError('初始化失败: $e');
      debugPrint('[VoiceReminderProvider] Initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReminders() async {
    try {
      _clearError();
      final reminders = await _repository.getReminders();
      _reminders = reminders;
      
      // Update voice service with current reminders
      _voiceService.updateScheduledReminders(_reminders);
      
      // 使用新的调度服务调度提醒
      await ReminderSchedulerService.instance.scheduleReminders(_reminders);
      
      notifyListeners();
      debugPrint('[VoiceReminderProvider] Loaded ${_reminders.length} reminders');
    } catch (e) {
      _setError('加载提醒失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to load reminders: $e');
    }
  }

  Future<void> loadTTSModels() async {
    try {
      final models = await _repository.getTTSModels();
      _ttsModels = models;
      notifyListeners();
      debugPrint('[VoiceReminderProvider] Loaded ${_ttsModels.length} TTS models');
    } catch (e) {
      debugPrint('[VoiceReminderProvider] Failed to load TTS models: $e');
      // Set default models if API fails
      _ttsModels = [
        const TTSModel(id: 'tts-1', name: 'TTS-1 (标准音质)', description: '标准音质，响应速度快'),
        const TTSModel(id: 'tts-1-hd', name: 'TTS-1-HD (高清音质)', description: '高清音质，音质更佳'),
      ];
      notifyListeners();
    }
  }

  Future<void> createReminder(VoiceReminder reminder) async {
    _setLoading(true);
    try {
      _clearError();
      final created = await _repository.createReminder(reminder);
      _reminders.add(created);
      _voiceService.updateScheduledReminders(_reminders);
      
      // 调度新创建的提醒
      await ReminderSchedulerService.instance.scheduleReminder(created);
      
      notifyListeners();
      debugPrint('[VoiceReminderProvider] Created reminder: ${created.content}');
    } catch (e) {
      _setError('创建提醒失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to create reminder: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<BatchImportResult> batchImportReminders(String batchText) async {
    _setLoading(true);
    try {
      _clearError();
      final result = await _repository.processBatchImport(batchText);
      
      // Reload reminders to get the latest data
      await loadReminders();
      
      debugPrint('[VoiceReminderProvider] Batch import completed: ${result.imported} imported, ${result.failed} failed');
      return result;
    } catch (e) {
      _setError('批量导入失败: $e');
      debugPrint('[VoiceReminderProvider] Batch import failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateReminder(VoiceReminder reminder) async {
    _setLoading(true);
    try {
      _clearError();
      final updated = await _repository.updateReminder(reminder);
      final index = _reminders.indexWhere((r) => r.id == updated.id);
      if (index != -1) {
        _reminders[index] = updated;
        _voiceService.updateScheduledReminders(_reminders);
        
        // 重新调度所有提醒
        ReminderSchedulerService.instance.cancelAllReminders();
        await ReminderSchedulerService.instance.scheduleReminders(_reminders);
        
        notifyListeners();
      }
      debugPrint('[VoiceReminderProvider] Updated reminder: ${updated.content}');
    } catch (e) {
      _setError('更新提醒失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to update reminder: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleReminder(VoiceReminder reminder) async {
    try {
      _clearError();
      final updated = reminder.copyWith(enabled: !reminder.enabled);
      await updateReminder(updated);
    } catch (e) {
      _setError('切换提醒状态失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to toggle reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(int id) async {
    _setLoading(true);
    try {
      _clearError();
      await _repository.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);
      _voiceService.updateScheduledReminders(_reminders);
      
      // 取消特定提醒的调度
      ReminderSchedulerService.instance.cancelReminder(id);
      
      notifyListeners();
      debugPrint('[VoiceReminderProvider] Deleted reminder: $id');
    } catch (e) {
      _setError('删除提醒失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to delete reminder: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAllReminders() async {
    _setLoading(true);
    try {
      _clearError();
      await _repository.deleteAllReminders();
      _reminders.clear();
      _voiceService.updateScheduledReminders(_reminders);
      
      // 取消所有调度的提醒
      ReminderSchedulerService.instance.cancelAllReminders();
      
      notifyListeners();
      debugPrint('[VoiceReminderProvider] Deleted all reminders');
    } catch (e) {
      _setError('删除所有提醒失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to delete all reminders: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> uploadAudioFile(File file) async {
    try {
      _clearError();
      final filePath = await _repository.uploadAudioFile(file);
      debugPrint('[VoiceReminderProvider] Uploaded audio file: $filePath');
      return filePath;
    } catch (e) {
      _setError('上传音频文件失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to upload audio file: $e');
      rethrow;
    }
  }

  Future<String> uploadAudioBytes(List<int> bytes, String filename) async {
    try {
      _clearError();
      final filePath = await _repository.uploadAudioBytes(bytes, filename);
      debugPrint('[VoiceReminderProvider] Uploaded audio bytes: $filePath');
      return filePath;
    } catch (e) {
      _setError('上传音频数据失败: $e');
      debugPrint('[VoiceReminderProvider] Failed to upload audio bytes: $e');
      rethrow;
    }
  }

  // Test methods
  Future<void> testSystemNotification() async {
    try {
      _clearError();
      await _voiceService.testSystemNotification();
      debugPrint('[VoiceReminderProvider] System notification test completed');
    } catch (e) {
      _setError('系统通知测试失败: $e');
      debugPrint('[VoiceReminderProvider] System notification test failed: $e');
    }
  }

  Future<void> testVoice([String? customText]) async {
    try {
      _clearError();
      await _voiceService.testVoice(customText);
      debugPrint('[VoiceReminderProvider] Voice test completed');
    } catch (e) {
      _setError('语音测试失败: $e');
      debugPrint('[VoiceReminderProvider] Voice test failed: $e');
    }
  }

  Future<void> testCustomAudio(String audioPath) async {
    try {
      _clearError();
      await _voiceService.testCustomAudio(audioPath);
      debugPrint('[VoiceReminderProvider] Custom audio test completed');
    } catch (e) {
      _setError('自定义音频测试失败: $e');
      debugPrint('[VoiceReminderProvider] Custom audio test failed: $e');
    }
  }
  
  /// 测试提醒调度功能
  Future<void> testReminderScheduling() async {
    try {
      _clearError();
      await ReminderSchedulerService.instance.testReminder();
      debugPrint('[VoiceReminderProvider] Reminder scheduling test completed');
    } catch (e) {
      _setError('提醒调度测试失败: $e');
      debugPrint('[VoiceReminderProvider] Reminder scheduling test failed: $e');
    }
  }

  // TTS Configuration
  Future<void> configureTTS({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) async {
    try {
      await _voiceService.configureTTS(
        speechRate: speechRate,
        volume: volume,
        pitch: pitch,
        language: language,
      );
      debugPrint('[VoiceReminderProvider] TTS configured');
    } catch (e) {
      debugPrint('[VoiceReminderProvider] TTS configuration failed: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}