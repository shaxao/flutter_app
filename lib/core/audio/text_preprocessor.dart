import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 文本预处理引擎 - 将原始文本转换为适合语音合成的标准格式
class TextPreprocessor {
  static final TextPreprocessor _instance = TextPreprocessor._internal();
  factory TextPreprocessor() => _instance;
  TextPreprocessor._internal();

  // 自定义词典缓存
  final Map<String, Map<String, String>> _customDictionaries = {};
  
  /// 预处理文本
  Future<ProcessedText> preprocess(String rawText, {
    String language = 'zh-CN',
    Map<String, String>? customDictionary,
  }) async {
    if (rawText.trim().isEmpty) {
      return ProcessedText(
        originalText: rawText,
        processedText: '',
        language: language,
        metadata: {'isEmpty': true},
        contentHash: _generateContentHash('', language),
      );
    }

    // 加载自定义词典
    if (customDictionary != null) {
      _customDictionaries[language] = customDictionary;
    }

    String processedText = rawText;
    final metadata = <String, dynamic>{};

    try {
      // 1. 时间格式化（在数字转换之前，避免冲突）
      processedText = formatTime(processedText, language);
      metadata['timeFormatted'] = true;

      // 2. 数字转换
      processedText = convertNumbers(processedText, language);
      metadata['numbersConverted'] = true;

      // 3. 特殊符号处理
      processedText = processSpecialCharacters(processedText, language);
      metadata['specialCharsProcessed'] = true;

      // 4. 多语言混合处理
      processedText = processMixedLanguage(processedText);
      metadata['mixedLanguageProcessed'] = true;

      // 5. 应用自定义词典
      processedText = _applyCustomDictionary(processedText, language);
      metadata['customDictionaryApplied'] = customDictionary != null;

      // 6. 清理和标准化
      processedText = _cleanAndNormalize(processedText);
      metadata['normalized'] = true;

    } catch (e) {
      metadata['error'] = e.toString();
      print('❌ 文本预处理失败: $e');
    }

    return ProcessedText(
      originalText: rawText,
      processedText: processedText,
      language: language,
      metadata: metadata,
      contentHash: _generateContentHash(processedText, language),
    );
  }

  /// 数字转换 - 将阿拉伯数字转换为语音友好格式
  String convertNumbers(String text, String language) {
    if (language.startsWith('zh')) {
      return _convertChineseNumbers(text);
    } else if (language.startsWith('en')) {
      return _convertEnglishNumbers(text);
    }
    return text;
  }

  /// 中文数字转换
  String _convertChineseNumbers(String text) {
    // 年份转换 (如: 2024年 -> 二零二四年)
    text = text.replaceAllMapped(
      RegExp(r'(\d{4})年'),
      (match) {
        final year = match.group(1)!;
        final converted = year.split('').map(_digitToChinese).join('');
        return '${converted}年';
      },
    );

    // 月日转换 (如: 1月1日 -> 一月一日)
    text = text.replaceAllMapped(
      RegExp(r'(\d{1,2})月(\d{1,2})日'),
      (match) {
        final month = _numberToChinese(int.parse(match.group(1)!));
        final day = _numberToChinese(int.parse(match.group(2)!));
        return '${month}月${day}日';
      },
    );

    // 一般数字转换 (1-99)
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\b'),
      (match) {
        final number = int.parse(match.group(1)!);
        return _numberToChinese(number);
      },
    );

    return text;
  }

  /// 英文数字转换
  String _convertEnglishNumbers(String text) {
    final numberWords = {
      '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
      '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine',
      '10': 'ten', '11': 'eleven', '12': 'twelve', '13': 'thirteen',
      '14': 'fourteen', '15': 'fifteen', '16': 'sixteen', '17': 'seventeen',
      '18': 'eighteen', '19': 'nineteen', '20': 'twenty',
    };

    // 简单数字替换 (0-20)
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\b'),
      (match) {
        final number = match.group(1)!;
        return numberWords[number] ?? number;
      },
    );

    return text;
  }

  /// 时间格式化 - 将时间格式转换为语音友好格式
  String formatTime(String text, String language) {
    if (language.startsWith('zh')) {
      return _formatChineseTime(text);
    } else if (language.startsWith('en')) {
      return _formatEnglishTime(text);
    }
    return text;
  }

  /// 中文时间格式化
  String _formatChineseTime(String text) {
    // 24小时制时间 (如: 14:30 -> 下午两点三十分)
    text = text.replaceAllMapped(
      RegExp(r'(\d{1,2}):(\d{2})'),
      (match) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        
        String period = '';
        int displayHour = hour;
        
        if (hour < 6) {
          period = '凌晨';
        } else if (hour < 12) {
          period = '上午';
        } else if (hour < 18) {
          period = '下午';
          displayHour = hour > 12 ? hour - 12 : hour;
        } else {
          period = '晚上';
          displayHour = hour - 12;
        }

        final hourText = _numberToChinese(displayHour);
        final minuteText = minute == 0 ? '' : '${_numberToChinese(minute)}分';
        
        return '$period${hourText}点$minuteText';
      },
    );

    return text;
  }

  /// 英文时间格式化
  String _formatEnglishTime(String text) {
    text = text.replaceAllMapped(
      RegExp(r'(\d{1,2}):(\d{2})'),
      (match) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        
        final period = hour < 12 ? 'AM' : 'PM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        
        if (minute == 0) {
          return '$displayHour o\'clock $period';
        } else {
          return '$displayHour $minute $period';
        }
      },
    );

    return text;
  }

  /// 特殊符号处理
  String processSpecialCharacters(String text, String language) {
    final replacements = language.startsWith('zh') 
        ? _getChineseSymbolReplacements()
        : _getEnglishSymbolReplacements();

    for (final entry in replacements.entries) {
      // 简单替换，保持原有的空格结构
      text = text.replaceAll(entry.key, entry.value);
    }

    return text;
  }

  /// 中文符号替换表
  Map<String, String> _getChineseSymbolReplacements() {
    return {
      '@': 'at',
      '#': '井号',
      '%': '百分号',
      '&': '和',
      '+': '加',
      '-': '减',
      '=': '等于',
      '×': '乘以',
      '÷': '除以',
      '°': '度',
      '℃': '摄氏度',
      '℉': '华氏度',
      '¥': '人民币',
      r'$': '美元',
      '€': '欧元',
      '£': '英镑',
      '...': '省略号',
      '……': '省略号',
    };
  }

  /// 英文符号替换表
  Map<String, String> _getEnglishSymbolReplacements() {
    return {
      '@': 'at',
      '#': 'hash',
      '%': 'percent',
      '&': 'and',
      '+': 'plus',
      '-': 'minus',
      '=': 'equals',
      '×': 'times',
      '÷': 'divided by',
      '°': 'degrees',
      '℃': 'celsius',
      '℉': 'fahrenheit',
      '¥': 'yuan',
      r'$': 'dollars',
      '€': 'euros',
      '£': 'pounds',
      '...': 'dot dot dot',
      '……': 'dot dot dot',
    };
  }

  /// 多语言混合处理
  String processMixedLanguage(String text) {
    // 检测中英文混合，在切换点添加适当的停顿，但避免重复空格
    text = text.replaceAllMapped(
      RegExp(r'([\u4e00-\u9fff]+)(\s*)([a-zA-Z]+)'),
      (match) {
        final chinese = match.group(1)!;
        final existingSpace = match.group(2) ?? '';
        final english = match.group(3)!;
        final space = existingSpace.isEmpty ? ' ' : existingSpace;
        return '$chinese$space$english';
      },
    );
    
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z]+)(\s*)([\u4e00-\u9fff]+)'),
      (match) {
        final english = match.group(1)!;
        final existingSpace = match.group(2) ?? '';
        final chinese = match.group(3)!;
        final space = existingSpace.isEmpty ? ' ' : existingSpace;
        return '$english$space$chinese';
      },
    );

    return text;
  }

  /// 应用自定义词典
  String _applyCustomDictionary(String text, String language) {
    final dictionary = _customDictionaries[language];
    if (dictionary == null) return text;

    for (final entry in dictionary.entries) {
      // 使用单词边界来避免部分匹配
      text = text.replaceAllMapped(
        RegExp('\\b${RegExp.escape(entry.key)}\\b'),
        (match) => entry.value,
      );
    }

    return text;
  }

  /// 清理和标准化文本
  String _cleanAndNormalize(String text) {
    // 移除多余的空格
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // 移除首尾空格
    text = text.trim();
    
    // 确保句子结尾有适当的停顿标记
    if (text.isNotEmpty && !RegExp(r'[。！？.!?]$').hasMatch(text)) {
      text += '。';
    }

    return text;
  }

  /// 数字转中文
  String _numberToChinese(int number) {
    if (number == 0) return '零';
    
    final digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    final units = ['', '十', '百', '千'];
    
    if (number < 10) {
      return digits[number];
    } else if (number < 20) {
      return number == 10 ? '十' : '十${digits[number % 10]}';
    } else if (number < 100) {
      final tens = number ~/ 10;
      final ones = number % 10;
      return ones == 0 ? '${digits[tens]}十' : '${digits[tens]}十${digits[ones]}';
    }
    
    return number.toString(); // 复杂数字暂时保持原样
  }

  /// 单个数字转中文
  String _digitToChinese(String digit) {
    const map = {
      '0': '零', '1': '一', '2': '二', '3': '三', '4': '四',
      '5': '五', '6': '六', '7': '七', '8': '八', '9': '九'
    };
    return map[digit] ?? digit;
  }

  /// 生成内容哈希
  String _generateContentHash(String content, String language) {
    final combined = '$content|$language';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // 取前16位作为短哈希
  }

  /// 获取预处理统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'customDictionaries': _customDictionaries.length,
      'supportedLanguages': ['zh-CN', 'en-US'],
      'features': [
        'numberConversion',
        'timeFormatting',
        'specialCharacters',
        'mixedLanguage',
        'customDictionary',
      ],
    };
  }

  /// 清理缓存
  void clearCache() {
    _customDictionaries.clear();
  }
}

/// 预处理后的文本数据模型
class ProcessedText {
  final String originalText;
  final String processedText;
  final String language;
  final Map<String, dynamic> metadata;
  final String contentHash;

  const ProcessedText({
    required this.originalText,
    required this.processedText,
    required this.language,
    required this.metadata,
    required this.contentHash,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'processedText': processedText,
      'language': language,
      'metadata': metadata,
      'contentHash': contentHash,
    };
  }

  /// 从JSON创建
  factory ProcessedText.fromJson(Map<String, dynamic> json) {
    return ProcessedText(
      originalText: json['originalText'] ?? '',
      processedText: json['processedText'] ?? '',
      language: json['language'] ?? 'zh-CN',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      contentHash: json['contentHash'] ?? '',
    );
  }

  /// 测试用构造函数
  factory ProcessedText.test({
    String content = '测试内容',
    String language = 'zh-CN',
  }) {
    final hash = sha256.convert(utf8.encode('$content|$language')).toString().substring(0, 16);
    return ProcessedText(
      originalText: content,
      processedText: content,
      language: language,
      metadata: {'test': true},
      contentHash: hash,
    );
  }

  @override
  String toString() {
    return 'ProcessedText(original: "$originalText", processed: "$processedText", hash: $contentHash)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessedText && other.contentHash == contentHash;
  }

  @override
  int get hashCode => contentHash.hashCode;
}