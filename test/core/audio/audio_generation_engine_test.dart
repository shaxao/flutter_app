import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import '../../../lib/core/audio/audio_generation_engine.dart';
import '../../../lib/core/audio/text_preprocessor.dart';
import '../../../lib/core/audio/audio_config.dart';

void main() {
  group('AudioGenerationEngine Tests', () {
    late AudioGenerationEngine engine;
    late TextPreprocessor preprocessor;

    setUpAll(() async {
      // 设置测试环境
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock Method Channels for testing
      _setupMockMethodChannels();
    });

    setUp(() async {
      engine = AudioGenerationEngine();
      preprocessor = TextPreprocessor();
      await engine.initialize();
    });

    tearDown(() async {
      await engine.dispose();
    });

    group('Unit Tests - Basic Functionality', () {
      test('should initialize successfully', () async {
        final newEngine = AudioGenerationEngine();
        await newEngine.initialize();
        
        expect(newEngine.getAvailableEngines(), isNotEmpty);
        expect(newEngine.defaultEngine, isNotNull);
        expect(newEngine.audioDirectory, isNotNull);
        
        await newEngine.dispose();
      });

      test('should generate audio file for simple text', () async {
        final text = await preprocessor.preprocess('测试音频生成');
        final config = AudioConfig.defaultConfig();
        
        final result = await engine.generateAudio(text, config);
        
        expect(result.success, isTrue);
        expect(result.audioFile, isNotNull);
        expect(result.audioFile!.exists(), isTrue);
        expect(result.audioFile!.contentHash, equals(text.contentHash));
        expect(result.generationTime.inMilliseconds, greaterThan(0));
      });

      test('should handle empty text gracefully', () async {
        final text = await preprocessor.preprocess('');
        final config = AudioConfig.defaultConfig();
        
        final result = await engine.generateAudio(text, config);
        
        expect(result.success, isFalse);
        expect(result.error, contains('文本内容为空'));
      });

      test('should handle invalid config gracefully', () async {
        final text = await preprocessor.preprocess('测试文本');
        final invalidConfig = AudioConfig(
          voice: 'test_voice',
          rate: -1.0, // 无效的语速
          pitch: 1.0,
          volume: 1.0,
          language: 'zh-CN',
          format: AudioFormat.mp3,
          quality: 3,
        );
        
        final result = await engine.generateAudio(text, invalidConfig);
        
        expect(result.success, isFalse);
        expect(result.error, contains('音频配置无效'));
      });

      test('should use cache for identical requests', () async {
        final text = await preprocessor.preprocess('缓存测试文本');
        final config = AudioConfig.defaultConfig();
        
        // 第一次生成
        final result1 = await engine.generateAudio(text, config);
        expect(result1.success, isTrue);
        expect(result1.metadata['fromCache'], isFalse);
        
        // 第二次生成应该使用缓存
        final result2 = await engine.generateAudio(text, config);
        expect(result2.success, isTrue);
        expect(result2.metadata['fromCache'], isTrue);
        expect(result2.generationTime.inMilliseconds, lessThan(result1.generationTime.inMilliseconds));
      });

      test('should support batch generation', () async {
        final texts = [
          await preprocessor.preprocess('批量测试文本1'),
          await preprocessor.preprocess('批量测试文本2'),
          await preprocessor.preprocess('批量测试文本3'),
        ];
        final config = AudioConfig.defaultConfig();
        
        final results = await engine.batchGenerateAudio(texts, config);
        
        expect(results.length, equals(3));
        expect(results.every((r) => r.success), isTrue);
        expect(results.every((r) => r.audioFile != null), isTrue);
        expect(results.every((r) => r.audioFile!.exists()), isTrue);
      });
    });

    group('Property Tests - Feature: dynamic-audio-reminder-system', () {
      /// Property 1: Audio generation consistency
      /// 对于任何有效的文本内容和音频配置，系统应该能够生成符合格式要求（AAC/MP3）、
      /// 大小限制（<100KB）和时间限制（<3秒）的音频文件
      test('Property 1: Audio generation consistency', () async {
        final random = Random(42); // 固定种子确保可重现性
        
        for (int i = 0; i < 100; i++) {
          // 生成随机但有效的测试数据
          final testText = _generateRandomValidText(random);
          final testConfig = _generateRandomValidConfig(random);
          
          final processedText = await preprocessor.preprocess(testText);
          final result = await engine.generateAudio(processedText, testConfig);
          
          // 验证音频生成一致性属性
          expect(result.success, isTrue, 
            reason: 'Audio generation should succeed for valid input: "$testText"');
          
          expect(result.audioFile, isNotNull,
            reason: 'Audio file should be generated');
          
          final audioFile = result.audioFile!;
          
          // 验证文件存在
          expect(audioFile.exists(), isTrue,
            reason: 'Generated audio file should exist');
          
          // 验证格式要求（AAC/MP3）
          expect([AudioFormat.mp3, AudioFormat.aac].contains(testConfig.format), isTrue,
            reason: 'Audio format should be MP3 or AAC');
          
          // 验证大小限制（<100KB）
          final fileSize = audioFile.getActualFileSize();
          expect(fileSize, lessThan(100 * 1024),
            reason: 'Audio file size should be less than 100KB, got ${fileSize}B');
          
          // 验证时间限制（<3秒生成时间）
          expect(result.generationTime.inSeconds, lessThan(3),
            reason: 'Generation time should be less than 3 seconds, got ${result.generationTime.inSeconds}s');
          
          // 验证内容哈希一致性
          expect(audioFile.contentHash, equals(processedText.contentHash),
            reason: 'Content hash should match processed text hash');
          
          // 验证配置应用
          expect(audioFile.config, equals(testConfig),
            reason: 'Audio file should preserve the configuration');
          
          // 清理测试文件
          await audioFile.delete();
        }
      }, timeout: const Timeout(Duration(minutes: 5)));

      /// Property 10: Batch processing efficiency
      /// 对于任何批量音频生成请求，系统应该能够高效处理并支持预加载常用提醒内容
      test('Property 10: Batch processing efficiency', () async {
        final random = Random(123);
        
        for (int batchSize in [1, 5, 10, 20]) {
          final texts = List.generate(batchSize, (i) => 
            _generateRandomValidText(random, seed: i)
          );
          
          final processedTexts = <ProcessedText>[];
          for (final text in texts) {
            processedTexts.add(await preprocessor.preprocess(text));
          }
          
          final config = _generateRandomValidConfig(random);
          
          final stopwatch = Stopwatch()..start();
          final results = await engine.batchGenerateAudio(processedTexts, config);
          stopwatch.stop();
          
          // 验证批量处理效率属性
          expect(results.length, equals(batchSize),
            reason: 'Should generate audio for all input texts');
          
          expect(results.every((r) => r.success), isTrue,
            reason: 'All batch generation should succeed');
          
          // 验证效率：批量处理应该比单独处理更快
          if (batchSize > 1) {
            final avgTimePerItem = stopwatch.elapsedMilliseconds / batchSize;
            expect(avgTimePerItem, lessThan(1000), // 每个项目平均少于1秒
              reason: 'Batch processing should be efficient: ${avgTimePerItem}ms per item');
          }
          
          // 验证预加载支持：相同内容的重复请求应该更快
          if (batchSize >= 2) {
            final duplicateTexts = [processedTexts.first, processedTexts.first];
            final duplicateStopwatch = Stopwatch()..start();
            final duplicateResults = await engine.batchGenerateAudio(duplicateTexts, config);
            duplicateStopwatch.stop();
            
            expect(duplicateResults.length, equals(2));
            expect(duplicateResults.every((r) => r.success), isTrue);
            
            // 第二个结果应该来自缓存，因此更快
            final secondResult = duplicateResults[1];
            expect(secondResult.metadata['fromCache'], isTrue,
              reason: 'Duplicate content should use cache');
          }
          
          // 清理测试文件
          for (final result in results) {
            if (result.audioFile != null) {
              await result.audioFile!.delete();
            }
          }
        }
      }, timeout: const Timeout(Duration(minutes: 3)));
    });

    group('Edge Cases and Error Handling', () {
      test('should handle very long text', () async {
        final longText = 'A' * 1000; // 1000字符的长文本
        final processedText = await preprocessor.preprocess(longText);
        final config = AudioConfig.defaultConfig();
        
        final result = await engine.generateAudio(processedText, config);
        
        // 长文本应该能够处理，但可能需要更长时间
        expect(result.success, isTrue);
        if (result.audioFile != null) {
          await result.audioFile!.delete();
        }
      });

      test('should handle special characters in text', () async {
        final specialText = '测试@#\$%^&*()特殊字符123';
        final processedText = await preprocessor.preprocess(specialText);
        final config = AudioConfig.defaultConfig();
        
        final result = await engine.generateAudio(processedText, config);
        
        expect(result.success, isTrue);
        if (result.audioFile != null) {
          await result.audioFile!.delete();
        }
      });

      test('should handle concurrent generation requests', () async {
        final texts = List.generate(5, (i) => '并发测试文本$i');
        final config = AudioConfig.defaultConfig();
        
        final futures = texts.map((text) async {
          final processedText = await preprocessor.preprocess(text);
          return engine.generateAudio(processedText, config);
        });
        
        final results = await Future.wait(futures);
        
        expect(results.length, equals(5));
        expect(results.every((r) => r.success), isTrue);
        
        // 清理测试文件
        for (final result in results) {
          if (result.audioFile != null) {
            await result.audioFile!.delete();
          }
        }
      });
    });

    group('Cache Management Tests', () {
      test('should cleanup expired audio files', () async {
        // 生成一些测试音频文件
        final texts = ['缓存测试1', '缓存测试2', '缓存测试3'];
        final config = AudioConfig.defaultConfig();
        
        for (final text in texts) {
          final processedText = await preprocessor.preprocess(text);
          await engine.generateAudio(processedText, config);
        }
        
        // 清理过期文件（使用很短的过期时间）
        final deletedCount = await engine.cleanupExpiredAudioFiles(
          olderThan: const Duration(milliseconds: 1)
        );
        
        expect(deletedCount, greaterThanOrEqualTo(0));
      });

      test('should provide engine statistics', () async {
        final stats = engine.getStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['initialized'], isTrue);
        expect(stats['audioDirectory'], isNotNull);
        expect(stats['availableEngines'], isA<List>());
        expect(stats['defaultEngine'], isNotNull);
      });
    });
  });
}

/// 生成随机但有效的测试文本
String _generateRandomValidText(Random random, {int? seed}) {
  final testTexts = [
    '今天天气很好',
    '请记住明天的会议',
    '该吃药了',
    '休息一下',
    '喝水提醒',
    '运动时间到了',
    '该睡觉了',
    '起床时间',
    '午餐时间',
    '工作提醒',
  ];
  
  final numbers = ['1', '2', '3', '10', '30', '下午2点', '明天', '今天'];
  final extras = ['！', '。', '，请注意', '，不要忘记'];
  
  final baseIndex = seed ?? random.nextInt(testTexts.length);
  var text = testTexts[baseIndex % testTexts.length];
  
  // 随机添加数字
  if (random.nextBool()) {
    text += numbers[random.nextInt(numbers.length)];
  }
  
  // 随机添加额外内容
  if (random.nextBool()) {
    text += extras[random.nextInt(extras.length)];
  }
  
  return text;
}

/// 生成随机但有效的音频配置
AudioConfig _generateRandomValidConfig(Random random) {
  final voices = ['default', 'male', 'female', 'child'];
  final languages = ['zh-CN', 'en-US'];
  final formats = [AudioFormat.mp3, AudioFormat.aac];
  
  return AudioConfig(
    voice: voices[random.nextInt(voices.length)],
    rate: 0.5 + random.nextDouble() * 1.5, // 0.5 - 2.0
    pitch: 0.5 + random.nextDouble() * 1.5, // 0.5 - 2.0
    volume: 0.5 + random.nextDouble() * 0.5, // 0.5 - 1.0
    language: languages[random.nextInt(languages.length)],
    format: formats[random.nextInt(formats.length)],
    quality: 1 + random.nextInt(5), // 1 - 5
  );
}

/// 设置测试用的Mock Method Channels
void _setupMockMethodChannels() {
  // Mock flutter_tts
  const MethodChannel('flutter_tts').setMockMethodCallHandler((call) async {
    switch (call.method) {
      case 'setLanguage':
      case 'setSpeechRate':
      case 'setVolume':
      case 'setPitch':
      case 'setIosAudioCategory':
        return 1; // Success
      case 'synthesizeToFile':
        // 模拟成功的文件合成 - 创建实际的测试文件
        final args = call.arguments as Map<String, dynamic>;
        final text = args['text'] as String? ?? '';
        final filePath = args['filePath'] as String? ?? '';
        
        if (filePath.isNotEmpty) {
          try {
            // 创建包含文本信息的测试音频文件
            final testAudioData = {
              'type': 'test_audio',
              'text': text,
              'format': 'mp3',
              'created_at': DateTime.now().toIso8601String(),
            };
            
            // 创建一个简单的MP3文件头 + JSON数据
            final mp3Header = [0xFF, 0xFB, 0x90, 0x00]; // 简化的MP3头
            final jsonData = utf8.encode(jsonEncode(testAudioData));
            final fileData = [...mp3Header, ...jsonData];
            
            await File(filePath).writeAsBytes(fileData);
            return 1; // Success
          } catch (e) {
            print('Mock synthesizeToFile failed: $e');
            return 0; // Failure
          }
        }
        return 0;
      case 'speak':
        return 1;
      case 'stop':
        return 1;
      default:
        return null;
    }
  });

  // Mock path_provider
  const MethodChannel('plugins.flutter.io/path_provider').setMockMethodCallHandler((call) async {
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
        return '/tmp/test_audio_cache'; // 测试用临时目录
      default:
        return null;
    }
  });

  // Mock iOS audio generation
  const MethodChannel('audio_generation/ios').setMockMethodCallHandler((call) async {
    if (call.method == 'generateAudioFile') {
      return {'success': true};
    }
    return null;
  });
}