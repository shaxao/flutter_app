import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/models/voice_reminder.dart';
import '../../../../core/services/api_service.dart';

class VoiceReminderRepository {
  final ApiService _apiService;

  VoiceReminderRepository(this._apiService);

  Future<List<VoiceReminder>> getReminders() async {
    try {
      final response = await _apiService.get('/api/v1/voice-reminders');
      final List<dynamic> data = response.data;
      return data.map((json) => VoiceReminder.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  Future<VoiceReminder> createReminder(VoiceReminder reminder) async {
    try {
      final response = await _apiService.post('/api/v1/voice-reminders', data: reminder.toJson());
      return VoiceReminder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  Future<List<VoiceReminder>> batchCreateReminders(List<VoiceReminder> reminders) async {
    try {
      final items = reminders.map((r) => r.toJson()).toList();
      final response = await _apiService.post('/api/v1/voice-reminders/batch', data: {'items': items});
      final List<dynamic> data = response.data;
      return data.map((json) => VoiceReminder.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to batch create reminders: $e');
    }
  }

  Future<VoiceReminder> updateReminder(VoiceReminder reminder) async {
    try {
      final response = await _apiService.patch('/api/v1/voice-reminders/${reminder.id}', data: reminder.toJson());
      return VoiceReminder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _apiService.delete('/api/v1/voice-reminders/$id');
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  Future<void> deleteAllReminders() async {
    try {
      await _apiService.delete('/api/v1/voice-reminders');
    } catch (e) {
      throw Exception('Failed to delete all reminders: $e');
    }
  }

  Future<List<TTSModel>> getTTSModels() async {
    try {
      final response = await _apiService.get('/api/v1/tts-models');
      final Map<String, dynamic> data = response.data;
      final List<dynamic> models = data['models'] ?? [];
      return models.map((json) => TTSModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch TTS models: $e');
    }
  }

  Future<String> uploadAudioFile(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/api/v1/voice-reminders/upload-audio'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['file_path'] ?? '';
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload audio file: $e');
    }
  }

  Future<BatchImportResult> processBatchImport(String batchText) async {
    try {
      final lines = batchText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      final reminders = <VoiceReminder>[];
      final errors = <String>[];

      for (final line in lines) {
        try {
          final parsed = _parseBatchLine(line.trim());
          if (parsed != null) {
            reminders.add(parsed);
          } else {
            errors.add('无法解析行: $line');
          }
        } catch (e) {
          errors.add('解析错误 "$line": $e');
        }
      }

      if (reminders.isNotEmpty) {
        await batchCreateReminders(reminders);
      }

      return BatchImportResult(
        imported: reminders.length,
        failed: errors.length,
        errors: errors,
      );
    } catch (e) {
      throw Exception('Failed to process batch import: $e');
    }
  }

  VoiceReminder? _parseBatchLine(String line) {
    // Parse formats like:
    // "蜗牛 14点" -> content: "蜗牛", time: "14:00"
    // "面包 15:30" -> content: "面包", time: "15:30"
    // "检查库存 9点半" -> content: "检查库存", time: "09:30"
    
    final parts = line.split(' ');
    if (parts.length < 2) return null;

    final content = parts.sublist(0, parts.length - 1).join(' ');
    final timeStr = parts.last;

    final time = _parseTimeString(timeStr);
    if (time == null) return null;

    return VoiceReminder(
      time: time,
      content: content,
      reminderType: ReminderType.aiVoice,
    );
  }

  String? _parseTimeString(String timeStr) {
    // Handle various time formats
    timeStr = timeStr.toLowerCase();
    
    // Direct time format: "15:30", "9:00"
    final directTimeRegex = RegExp(r'^(\d{1,2}):(\d{2})$');
    final directMatch = directTimeRegex.firstMatch(timeStr);
    if (directMatch != null) {
      final hour = int.parse(directMatch.group(1)!);
      final minute = int.parse(directMatch.group(2)!);
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    }

    // Chinese time formats
    if (timeStr.contains('点')) {
      // "14点" -> "14:00"
      final hourOnlyRegex = RegExp(r'^(\d{1,2})点$');
      final hourMatch = hourOnlyRegex.firstMatch(timeStr);
      if (hourMatch != null) {
        final hour = int.parse(hourMatch.group(1)!);
        if (hour >= 0 && hour <= 23) {
          return '${hour.toString().padLeft(2, '0')}:00';
        }
      }

      // "9点半" -> "09:30"
      final halfHourRegex = RegExp(r'^(\d{1,2})点半$');
      final halfMatch = halfHourRegex.firstMatch(timeStr);
      if (halfMatch != null) {
        final hour = int.parse(halfMatch.group(1)!);
        if (hour >= 0 && hour <= 23) {
          return '${hour.toString().padLeft(2, '0')}:30';
        }
      }

      // "14点30分" -> "14:30"
      final fullRegex = RegExp(r'^(\d{1,2})点(\d{1,2})分?$');
      final fullMatch = fullRegex.firstMatch(timeStr);
      if (fullMatch != null) {
        final hour = int.parse(fullMatch.group(1)!);
        final minute = int.parse(fullMatch.group(2)!);
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }
    }

    return null;
  }
}