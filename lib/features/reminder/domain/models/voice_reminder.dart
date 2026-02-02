class VoiceReminder {
  final int? id;
  final String time;
  final String content;
  final bool enabled;
  final ReminderType reminderType;
  final String? voiceModel;
  final String? audioFilePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VoiceReminder({
    this.id,
    required this.time,
    required this.content,
    this.enabled = true,
    this.reminderType = ReminderType.aiVoice,
    this.voiceModel = 'tts-1',
    this.audioFilePath,
    this.createdAt,
    this.updatedAt,
  });

  factory VoiceReminder.fromJson(Map<String, dynamic> json) {
    return VoiceReminder(
      id: json['id'],
      time: json['time'] ?? '',
      content: json['content'] ?? '',
      enabled: json['enabled'] ?? true,
      reminderType: ReminderType.fromString(json['reminder_type'] ?? 'ai_voice'),
      voiceModel: json['voice_model'],
      audioFilePath: json['audio_file_path'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'content': content,
      'enabled': enabled,
      'reminder_type': reminderType.value,
      'voice_model': voiceModel,
      'audio_file_path': audioFilePath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  VoiceReminder copyWith({
    int? id,
    String? time,
    String? content,
    bool? enabled,
    ReminderType? reminderType,
    String? voiceModel,
    String? audioFilePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceReminder(
      id: id ?? this.id,
      time: time ?? this.time,
      content: content ?? this.content,
      enabled: enabled ?? this.enabled,
      reminderType: reminderType ?? this.reminderType,
      voiceModel: voiceModel ?? this.voiceModel,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ReminderType {
  system('system'),
  aiVoice('ai_voice'),
  customAudio('custom_audio');

  const ReminderType(this.value);
  final String value;

  static ReminderType fromString(String value) {
    switch (value) {
      case 'system':
        return ReminderType.system;
      case 'ai_voice':
        return ReminderType.aiVoice;
      case 'custom_audio':
        return ReminderType.customAudio;
      default:
        return ReminderType.aiVoice;
    }
  }

  String get displayName {
    switch (this) {
      case ReminderType.system:
        return '系统通知';
      case ReminderType.aiVoice:
        return 'AI语音';
      case ReminderType.customAudio:
        return '自定义音频';
    }
  }

  String get description {
    switch (this) {
      case ReminderType.system:
        return '📱 仅发送系统通知，不播放语音';
      case ReminderType.aiVoice:
        return '🤖 使用 AI 生成自然语音播报';
      case ReminderType.customAudio:
        return '🎵 使用您上传的自定义音频文件';
    }
  }
}

class TTSModel {
  final String id;
  final String name;
  final String description;

  const TTSModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory TTSModel.fromJson(Map<String, dynamic> json) {
    return TTSModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class BatchImportResult {
  final int imported;
  final int failed;
  final List<String> errors;

  const BatchImportResult({
    required this.imported,
    required this.failed,
    required this.errors,
  });

  factory BatchImportResult.fromJson(Map<String, dynamic> json) {
    return BatchImportResult(
      imported: json['imported'] ?? 0,
      failed: json['failed'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}