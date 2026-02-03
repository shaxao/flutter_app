import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/audio/text_preprocessor.dart';

void main() {
  group('TextPreprocessor', () {
    late TextPreprocessor processor;

    setUp(() {
      processor = TextPreprocessor();
      processor.clearCache(); // 确保每个测试开始时缓存为空
    });

    group('数字转换测试', () {
      test('应该正确转换中文年份', () {
        final result = processor.convertNumbers('2024年1月1日', 'zh-CN');
        expect(result, equals('二零二四年一月一日'));
      });

      test('应该正确转换中文月日', () {
        final result = processor.convertNumbers('12月25日', 'zh-CN');
        expect(result, equals('十二月二十五日'));
      });

      test('应该正确转换简单数字', () {
        expect(processor.convertNumbers('5个苹果', 'zh-CN'), equals('五个苹果'));
        expect(processor.convertNumbers('10只鸟', 'zh-CN'), equals('十只鸟'));
        expect(processor.convertNumbers('20分钟', 'zh-CN'), equals('二十分钟'));
      });

      test('应该正确转换英文数字', () {
        expect(processor.convertNumbers('5 apples', 'en-US'), equals('five apples'));
        expect(processor.convertNumbers('10 birds', 'en-US'), equals('ten birds'));
        expect(processor.convertNumbers('15 minutes', 'en-US'), equals('fifteen minutes'));
      });

      test('应该处理边界情况', () {
        expect(processor.convertNumbers('0个', 'zh-CN'), equals('零个'));
        expect(processor.convertNumbers('99个', 'zh-CN'), equals('九十九个'));
      });
    });

    group('时间格式化测试', () {
      test('应该正确格式化中文时间', () {
        expect(processor.formatTime('09:00', 'zh-CN'), equals('上午九点'));
        expect(processor.formatTime('12:00', 'zh-CN'), equals('下午十二点'));
        expect(processor.formatTime('14:30', 'zh-CN'), equals('下午二点三十分'));
        expect(processor.formatTime('18:45', 'zh-CN'), equals('晚上六点四十五分'));
        expect(processor.formatTime('23:59', 'zh-CN'), equals('晚上十一点五十九分'));
      });

      test('应该正确格式化英文时间', () {
        expect(processor.formatTime('09:00', 'en-US'), equals('9 o\'clock AM'));
        expect(processor.formatTime('12:00', 'en-US'), equals('12 o\'clock PM'));
        expect(processor.formatTime('14:30', 'en-US'), equals('2 30 PM'));
        expect(processor.formatTime('23:59', 'en-US'), equals('11 59 PM'));
      });

      test('应该处理特殊时间', () {
        expect(processor.formatTime('00:00', 'zh-CN'), equals('凌晨零点'));
        expect(processor.formatTime('06:00', 'zh-CN'), equals('上午六点'));
      });
    });

    group('特殊符号处理测试', () {
      test('应该正确处理中文符号', () {
        expect(processor.processSpecialCharacters('发送@用户', 'zh-CN'), equals('发送at用户'));
        expect(processor.processSpecialCharacters('温度25℃', 'zh-CN'), equals('温度25摄氏度'));
        expect(processor.processSpecialCharacters('价格¥100', 'zh-CN'), equals('价格人民币100'));
        expect(processor.processSpecialCharacters('3+5=8', 'zh-CN'), equals('3加5等于8'));
      });

      test('应该正确处理英文符号', () {
        expect(processor.processSpecialCharacters('send @user', 'en-US'), equals('send atuser'));
        expect(processor.processSpecialCharacters('temp 25℃', 'en-US'), equals('temp 25celsius'));
        expect(processor.processSpecialCharacters('price \$100', 'en-US'), equals('price dollars100'));
        expect(processor.processSpecialCharacters('3+5=8', 'en-US'), equals('3plus5equals8'));
      });
    });

    group('多语言混合处理测试', () {
      test('应该在中英文切换点添加空格', () {
        expect(processor.processMixedLanguage('你好world'), equals('你好 world'));
        expect(processor.processMixedLanguage('hello世界'), equals('hello 世界'));
        expect(processor.processMixedLanguage('这是test内容'), equals('这是 test 内容'));
      });

      test('应该保持已有空格', () {
        expect(processor.processMixedLanguage('你好 world'), equals('你好 world'));
        expect(processor.processMixedLanguage('hello 世界'), equals('hello 世界'));
      });
    });

    group('文本预处理集成测试', () {
      test('应该完整处理复杂文本', () async {
        const input = '今天是2024年1月1日14:30，温度25℃，发送@用户消息';
        final result = await processor.preprocess(input, language: 'zh-CN');
        
        expect(result.originalText, equals(input));
        expect(result.language, equals('zh-CN'));
        expect(result.contentHash.length, equals(16));
        expect(result.metadata['numbersConverted'], isTrue);
        expect(result.metadata['timeFormatted'], isTrue);
        expect(result.metadata['specialCharsProcessed'], isTrue);
        
        // 验证处理后的文本包含预期的转换
        expect(result.processedText, contains('二零二四年一月一日'));
        expect(result.processedText, contains('下午二点三十分'));
        expect(result.processedText, contains('摄氏度'));
        expect(result.processedText, contains('at 用户')); // 注意空格
      });

      test('应该处理空文本', () async {
        final result = await processor.preprocess('', language: 'zh-CN');
        
        expect(result.originalText, equals(''));
        expect(result.processedText, equals(''));
        expect(result.metadata['isEmpty'], isTrue);
        expect(result.contentHash.isNotEmpty, isTrue);
      });

      test('应该处理仅空格的文本', () async {
        final result = await processor.preprocess('   ', language: 'zh-CN');
        
        expect(result.originalText, equals('   '));
        expect(result.processedText, equals(''));
        expect(result.metadata['isEmpty'], isTrue);
      });

      test('应该应用自定义词典', () async {
        final customDict = {'VIP': '贵宾', 'CEO': '首席执行官'};
        final result = await processor.preprocess(
          'VIP用户和CEO开会',
          language: 'zh-CN',
          customDictionary: customDict,
        );
        
        expect(result.processedText, equals('贵宾 用户和 首席执行官 开会。'));
        expect(result.metadata['customDictionaryApplied'], isTrue);
      });

      test('应该生成一致的内容哈希', () async {
        const text = '测试内容';
        const language = 'zh-CN';
        
        final result1 = await processor.preprocess(text, language: language);
        final result2 = await processor.preprocess(text, language: language);
        
        expect(result1.contentHash, equals(result2.contentHash));
      });

      test('不同内容应该生成不同的哈希', () async {
        final result1 = await processor.preprocess('内容1', language: 'zh-CN');
        final result2 = await processor.preprocess('内容2', language: 'zh-CN');
        
        expect(result1.contentHash, isNot(equals(result2.contentHash)));
      });

      test('相同内容不同语言应该生成不同哈希', () async {
        const text = 'hello';
        final result1 = await processor.preprocess(text, language: 'zh-CN');
        final result2 = await processor.preprocess(text, language: 'en-US');
        
        expect(result1.contentHash, isNot(equals(result2.contentHash)));
      });
    });

    group('ProcessedText 数据模型测试', () {
      test('应该正确序列化和反序列化', () {
        final original = ProcessedText(
          originalText: '原始文本',
          processedText: '处理后文本',
          language: 'zh-CN',
          metadata: {'test': true, 'count': 5},
          contentHash: 'abcd1234',
        );

        final json = original.toJson();
        final restored = ProcessedText.fromJson(json);

        expect(restored.originalText, equals(original.originalText));
        expect(restored.processedText, equals(original.processedText));
        expect(restored.language, equals(original.language));
        expect(restored.metadata, equals(original.metadata));
        expect(restored.contentHash, equals(original.contentHash));
      });

      test('应该正确实现相等性比较', () {
        final text1 = ProcessedText.test(content: '测试', language: 'zh-CN');
        final text2 = ProcessedText.test(content: '测试', language: 'zh-CN');
        final text3 = ProcessedText.test(content: '不同', language: 'zh-CN');

        expect(text1, equals(text2)); // 相同内容应该相等
        expect(text1, isNot(equals(text3))); // 不同内容应该不相等
      });

      test('toString 应该返回有用的信息', () {
        final text = ProcessedText.test(content: '测试内容');
        final str = text.toString();
        
        expect(str, contains('测试内容'));
        expect(str, contains('ProcessedText'));
        expect(str, contains('hash'));
      });
    });

    group('错误处理测试', () {
      test('应该优雅处理异常', () async {
        // 这个测试验证即使处理过程中出现异常，也能返回有效结果
        final result = await processor.preprocess('正常文本', language: 'zh-CN');
        
        expect(result.originalText, equals('正常文本'));
        expect(result.processedText.isNotEmpty, isTrue);
        expect(result.contentHash.isNotEmpty, isTrue);
      });
    });

    group('性能测试', () {
      test('应该在合理时间内处理文本', () async {
        final longText = '这是一个很长的文本，包含2024年1月1日14:30的时间，还有@用户和25℃的温度信息。' * 10;
        
        final stopwatch = Stopwatch()..start();
        final result = await processor.preprocess(longText, language: 'zh-CN');
        stopwatch.stop();
        
        expect(result.processedText.isNotEmpty, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 应该在1秒内完成
      });
    });

    group('统计信息测试', () {
      test('应该返回正确的统计信息', () {
        final stats = processor.getStatistics();
        
        expect(stats['supportedLanguages'], contains('zh-CN'));
        expect(stats['supportedLanguages'], contains('en-US'));
        expect(stats['features'], contains('numberConversion'));
        expect(stats['features'], contains('timeFormatting'));
        expect(stats['features'], contains('specialCharacters'));
        expect(stats['features'], contains('mixedLanguage'));
        expect(stats['features'], contains('customDictionary'));
      });
    });

    // **Feature: dynamic-audio-reminder-system, Property 6: 文本预处理正确性**
    // 对于任何包含数字、时间格式或特殊字符的文本，预处理引擎应该将其转换为适合语音合成的标准格式
    group('Property 6: 文本预处理正确性', () {
      test('属性测试 - 数字转换正确性', () async {
        final testCases = [
          {'input': '2024年', 'expected': '二零二四年'},
          {'input': '1月1日', 'expected': '一月一日'},
          {'input': '12月31日', 'expected': '十二月三十一日'},
          {'input': '5个', 'expected': '五个'},
          {'input': '10个', 'expected': '十个'},
          {'input': '20个', 'expected': '二十个'},
          {'input': '99个', 'expected': '九十九个'},
        ];

        for (final testCase in testCases) {
          final result = processor.convertNumbers(testCase['input']!, 'zh-CN');
          expect(result, equals(testCase['expected']), 
                 reason: '输入 "${testCase['input']}" 应该转换为 "${testCase['expected']}"');
        }
      });

      test('属性测试 - 时间格式化正确性', () async {
        final testCases = [
          {'input': '09:00', 'expected': '上午九点'},
          {'input': '12:00', 'expected': '下午十二点'},
          {'input': '14:30', 'expected': '下午二点三十分'},
          {'input': '18:45', 'expected': '晚上六点四十五分'},
          {'input': '23:59', 'expected': '晚上十一点五十九分'},
          {'input': '00:00', 'expected': '凌晨零点'},
        ];

        for (final testCase in testCases) {
          final result = processor.formatTime(testCase['input']!, 'zh-CN');
          expect(result, equals(testCase['expected']), 
                 reason: '时间 "${testCase['input']}" 应该格式化为 "${testCase['expected']}"');
        }
      });

      test('属性测试 - 特殊字符处理正确性', () async {
        final testCases = [
          {'input': '@用户', 'expected': 'at用户'},
          {'input': '25℃', 'expected': '25摄氏度'},
          {'input': '¥100', 'expected': '人民币100'},
          {'input': '3+5', 'expected': '3加5'},
          {'input': '10%', 'expected': '10百分号'},
          {'input': 'A&B', 'expected': 'A和B'},
        ];

        for (final testCase in testCases) {
          final result = processor.processSpecialCharacters(testCase['input']!, 'zh-CN');
          expect(result, equals(testCase['expected']), 
                 reason: '特殊字符 "${testCase['input']}" 应该处理为 "${testCase['expected']}"');
        }
      });

      test('属性测试 - 综合文本预处理正确性', () async {
        final complexTestCases = [
          {
            'input': '2024年1月1日14:30提醒@用户',
            'shouldContain': ['二零二四年', '一月一日', '下午二点三十分', 'at 用户']
          },
          {
            'input': '温度25℃，价格¥100',
            'shouldContain': ['摄氏度', '人民币']
          },
          {
            'input': '12月25日09:00开会',
            'shouldContain': ['十二月二十五日', '上午九点']
          },
        ];

        for (final testCase in complexTestCases) {
          final result = await processor.preprocess(testCase['input']! as String, language: 'zh-CN');
          final processedText = result.processedText;
          
          for (final expectedContent in testCase['shouldContain']! as List<String>) {
            expect(processedText, contains(expectedContent), 
                   reason: '处理后的文本应该包含 "$expectedContent"');
          }
        }
      });

      test('属性测试 - 空文本和边界情况处理', () async {
        final boundaryTestCases = [
          {'input': '', 'description': '空字符串'},
          {'input': '   ', 'description': '仅空格'},
          {'input': '\n\t', 'description': '仅换行和制表符'},
          {'input': '0', 'description': '单个零'},
          {'input': '00:00', 'description': '零点时间'},
        ];

        for (final testCase in boundaryTestCases) {
          final result = await processor.preprocess(testCase['input']!, language: 'zh-CN');
          
          // 验证不会抛出异常，并且返回有效的ProcessedText对象
          expect(result.originalText, equals(testCase['input']));
          expect(result.contentHash.isNotEmpty, isTrue, 
                 reason: '${testCase['description']} 应该生成有效的内容哈希');
          expect(result.language, equals('zh-CN'));
          expect(result.metadata, isA<Map<String, dynamic>>());
        }
      });
    });
  });
}