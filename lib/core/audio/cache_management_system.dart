import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'audio_generation_engine.dart';
import 'audio_config.dart';

/// 缓存条目数据模型
class AudioCacheEntry {
  final String contentHash;
  final String configHash;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int accessCount;
  final AudioConfig config;
  final Map<String, dynamic> metadata;

  const AudioCacheEntry({
    required this.contentHash,
    required this.configHash,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.accessCount,
    required this.config,
    required this.metadata,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'contentHash': contentHash,
      'configHash': configHash,
      'filePath': filePath,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'accessCount': accessCount,
      'config': config.toJson(),
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory AudioCacheEntry.fromJson(Map<String, dynamic> json) {
    return AudioCacheEntry(
      contentHash: json['contentHash'] ?? '',
      configHash: json['configHash'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastAccessedAt: DateTime.tryParse(json['lastAccessedAt'] ?? '') ?? DateTime.now(),
      accessCount: json['accessCount'] ?? 0,
      config: AudioConfig.fromJson(json['config'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 创建更新的缓存条目（访问计数+1）
  AudioCacheEntry withAccess() {
    return AudioCacheEntry(
      contentHash: contentHash,
      configHash: configHash,
      filePath: filePath,
      fileSize: fileSize,
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
      config: config,
      metadata: metadata,
    );
  }

  /// 生成缓存键
  String get cacheKey => '${contentHash}_$configHash';

  /// 检查文件是否存在
  bool fileExists() {
    try {
      return File(filePath).existsSync();
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'AudioCacheEntry(key: $cacheKey, path: $filePath, size: ${fileSize}B, accessed: $accessCount times)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioCacheEntry && other.cacheKey == cacheKey;
  }

  @override
  int get hashCode => cacheKey.hashCode;
}

/// 缓存配置
class CacheConfig {
  final int maxMemoryCacheSize;    // 内存缓存大小限制 (MB)
  final int maxDiskCacheSize;      // 磁盘缓存大小限制 (MB)
  final Duration cacheExpiration;  // 缓存过期时间
  final int maxCacheEntries;       // 最大缓存条目数
  final bool enablePreloading;     // 是否启用预加载
  final double lruEvictionRatio;   // LRU淘汰比例 (0.0-1.0)

  const CacheConfig({
    this.maxMemoryCacheSize = 50,
    this.maxDiskCacheSize = 200,
    this.cacheExpiration = const Duration(days: 7),
    this.maxCacheEntries = 1000,
    this.enablePreloading = true,
    this.lruEvictionRatio = 0.2,
  });

  /// 默认配置
  factory CacheConfig.defaultConfig() => const CacheConfig();

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'maxMemoryCacheSize': maxMemoryCacheSize,
      'maxDiskCacheSize': maxDiskCacheSize,
      'cacheExpirationMs': cacheExpiration.inMilliseconds,
      'maxCacheEntries': maxCacheEntries,
      'enablePreloading': enablePreloading,
      'lruEvictionRatio': lruEvictionRatio,
    };
  }

  /// 从JSON创建
  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      maxMemoryCacheSize: json['maxMemoryCacheSize'] ?? 50,
      maxDiskCacheSize: json['maxDiskCacheSize'] ?? 200,
      cacheExpiration: Duration(milliseconds: json['cacheExpirationMs'] ?? 604800000),
      maxCacheEntries: json['maxCacheEntries'] ?? 1000,
      enablePreloading: json['enablePreloading'] ?? true,
      lruEvictionRatio: (json['lruEvictionRatio'] ?? 0.2).toDouble(),
    );
  }
}

/// 缓存统计信息
class CacheStatistics {
  final int totalEntries;
  final int memoryEntries;
  final int diskEntries;
  final double hitRate;
  final int totalSize;
  final DateTime lastCleanup;
  final int totalHits;
  final int totalMisses;
  final int totalEvictions;

  const CacheStatistics({
    required this.totalEntries,
    required this.memoryEntries,
    required this.diskEntries,
    required this.hitRate,
    required this.totalSize,
    required this.lastCleanup,
    required this.totalHits,
    required this.totalMisses,
    required this.totalEvictions,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'memoryEntries': memoryEntries,
      'diskEntries': diskEntries,
      'hitRate': hitRate,
      'totalSize': totalSize,
      'lastCleanup': lastCleanup.toIso8601String(),
      'totalHits': totalHits,
      'totalMisses': totalMisses,
      'totalEvictions': totalEvictions,
    };
  }
}

/// 内存缓存实现 (LRU)
class MemoryCache {
  final int _maxSize;
  final LinkedHashMap<String, AudioCacheEntry> _cache = LinkedHashMap();

  MemoryCache(this._maxSize);

  /// 获取缓存条目
  AudioCacheEntry? get(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      // 移到最后（最近使用）
      _cache[key] = entry.withAccess();
      return _cache[key];
    }
    return null;
  }

  /// 存储缓存条目
  void put(String key, AudioCacheEntry entry) {
    _cache.remove(key); // 如果已存在，先移除
    _cache[key] = entry;

    // 检查是否超过最大大小
    while (_cache.length > _maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  /// 移除缓存条目
  AudioCacheEntry? remove(String key) {
    return _cache.remove(key);
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
  }

  /// 获取所有条目
  List<AudioCacheEntry> get entries => _cache.values.toList();

  /// 缓存大小
  int get size => _cache.length;

  /// 是否包含键
  bool containsKey(String key) => _cache.containsKey(key);
}

/// 磁盘缓存实现
class DiskCache {
  final String _cacheDirectory;
  final String _indexFilePath;
  final Map<String, AudioCacheEntry> _index = {};
  bool _initialized = false;

  DiskCache(this._cacheDirectory) : _indexFilePath = '$_cacheDirectory/cache_index.json';

  /// 初始化磁盘缓存
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 创建缓存目录
      final dir = Directory(_cacheDirectory);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // 加载缓存索引
      await _loadIndex();
      
      // 验证缓存完整性
      await _validateCache();

      _initialized = true;
      print('✅ 磁盘缓存初始化完成: $_cacheDirectory');
    } catch (e) {
      print('❌ 磁盘缓存初始化失败: $e');
      _initialized = true; // 即使失败也标记为已初始化
    }
  }

  /// 加载缓存索引
  Future<void> _loadIndex() async {
    try {
      final indexFile = File(_indexFilePath);
      if (indexFile.existsSync()) {
        final content = await indexFile.readAsString();
        final indexData = jsonDecode(content) as Map<String, dynamic>;
        
        _index.clear();
        for (final entry in indexData.entries) {
          try {
            final cacheEntry = AudioCacheEntry.fromJson(entry.value);
            _index[entry.key] = cacheEntry;
          } catch (e) {
            print('⚠️ 跳过损坏的缓存条目: ${entry.key}, $e');
          }
        }
        
        print('✅ 加载了 ${_index.length} 个缓存条目');
      }
    } catch (e) {
      print('⚠️ 加载缓存索引失败: $e');
      _index.clear();
    }
  }

  /// 保存缓存索引
  Future<void> _saveIndex() async {
    try {
      final indexData = <String, dynamic>{};
      for (final entry in _index.entries) {
        indexData[entry.key] = entry.value.toJson();
      }

      final indexFile = File(_indexFilePath);
      final jsonString = jsonEncode(indexData);
      await indexFile.writeAsString(jsonString);
    } catch (e) {
      print('❌ 保存缓存索引失败: $e');
    }
  }

  /// 验证缓存完整性
  Future<void> _validateCache() async {
    final keysToRemove = <String>[];
    
    for (final entry in _index.entries) {
      if (!entry.value.fileExists()) {
        keysToRemove.add(entry.key);
      }
    }

    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        _index.remove(key);
      }
      await _saveIndex();
      print('🧹 清理了 ${keysToRemove.length} 个无效缓存条目');
    }
  }

  /// 获取缓存条目
  Future<AudioCacheEntry?> get(String key) async {
    if (!_initialized) await initialize();

    final entry = _index[key];
    if (entry != null && entry.fileExists()) {
      // 更新访问时间
      final updatedEntry = entry.withAccess();
      _index[key] = updatedEntry;
      await _saveIndex();
      return updatedEntry;
    }

    // 如果文件不存在，从索引中移除
    if (entry != null) {
      _index.remove(key);
      await _saveIndex();
    }

    return null;
  }

  /// 存储缓存条目
  Future<void> put(String key, AudioCacheEntry entry) async {
    if (!_initialized) await initialize();

    _index[key] = entry;
    await _saveIndex();
  }

  /// 移除缓存条目
  Future<AudioCacheEntry?> remove(String key) async {
    if (!_initialized) await initialize();

    final entry = _index.remove(key);
    if (entry != null) {
      // 删除文件
      try {
        final file = File(entry.filePath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        print('⚠️ 删除缓存文件失败: ${entry.filePath}, $e');
      }
      
      await _saveIndex();
    }
    return entry;
  }

  /// 清空缓存
  Future<void> clear() async {
    if (!_initialized) await initialize();

    // 删除所有缓存文件
    for (final entry in _index.values) {
      try {
        final file = File(entry.filePath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        print('⚠️ 删除缓存文件失败: ${entry.filePath}, $e');
      }
    }

    _index.clear();
    await _saveIndex();
  }

  /// 获取所有条目
  List<AudioCacheEntry> get entries => _index.values.toList();

  /// 缓存大小
  int get size => _index.length;

  /// 是否包含键
  bool containsKey(String key) => _index.containsKey(key);

  /// 获取总文件大小
  int getTotalSize() {
    return _index.values.fold(0, (sum, entry) => sum + entry.fileSize);
  }
}

/// 多级缓存管理系统
class CacheManagementSystem {
  static CacheManagementSystem? _instance;
  factory CacheManagementSystem() => _instance ??= CacheManagementSystem._internal();
  CacheManagementSystem._internal();

  late MemoryCache _memoryCache;
  late DiskCache _diskCache;
  CacheConfig _config = CacheConfig.defaultConfig();
  bool _initialized = false;

  // 统计信息
  int _totalHits = 0;
  int _totalMisses = 0;
  int _totalEvictions = 0;
  DateTime _lastCleanup = DateTime.now();

  /// 重置实例（仅用于测试）
  static void resetForTesting() {
    _instance = null;
  }

  /// 初始化缓存管理系统
  Future<void> initialize({CacheConfig? config}) async {
    if (_initialized) return;

    _config = config ?? CacheConfig.defaultConfig();

    try {
      // 获取缓存目录
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = '${appDir.path}/audio_cache';

      // 初始化内存缓存
      _memoryCache = MemoryCache(_config.maxCacheEntries ~/ 4); // 内存缓存占总容量的1/4

      // 初始化磁盘缓存
      _diskCache = DiskCache(cacheDir);
      await _diskCache.initialize();

      _initialized = true;
      print('✅ 缓存管理系统初始化完成');
    } catch (e) {
      print('❌ 缓存管理系统初始化失败: $e');
      _initialized = true; // 即使失败也标记为已初始化
    }
  }

  /// 获取缓存的音频文件
  Future<AudioFile?> getCachedAudio(String contentHash, AudioConfig config) async {
    if (!_initialized) await initialize();

    final cacheKey = '${contentHash}_${config.configHash}';

    // 1. 先检查内存缓存
    var entry = _memoryCache.get(cacheKey);
    if (entry != null && entry.fileExists()) {
      _totalHits++;
      print('🎯 内存缓存命中: $cacheKey');
      return _createAudioFileFromEntry(entry);
    }

    // 2. 检查磁盘缓存
    entry = await _diskCache.get(cacheKey);
    if (entry != null && entry.fileExists()) {
      _totalHits++;
      // 将热点数据提升到内存缓存
      _memoryCache.put(cacheKey, entry);
      print('💾 磁盘缓存命中: $cacheKey');
      return _createAudioFileFromEntry(entry);
    }

    _totalMisses++;
    print('❌ 缓存未命中: $cacheKey');
    return null;
  }

  /// 缓存音频文件
  Future<void> cacheAudio(AudioFile audioFile) async {
    if (!_initialized) await initialize();

    final cacheKey = '${audioFile.contentHash}_${audioFile.config.configHash}';
    
    final entry = AudioCacheEntry(
      contentHash: audioFile.contentHash,
      configHash: audioFile.config.configHash,
      filePath: audioFile.filePath,
      fileSize: audioFile.fileSize,
      createdAt: audioFile.createdAt,
      lastAccessedAt: DateTime.now(),
      accessCount: 1,
      config: audioFile.config,
      metadata: audioFile.metadata,
    );

    // 同时存储到内存和磁盘缓存
    _memoryCache.put(cacheKey, entry);
    await _diskCache.put(cacheKey, entry);

    print('✅ 音频文件已缓存: $cacheKey');

    // 检查是否需要清理
    await _checkAndCleanup();
  }

  /// 预加载常用音频
  Future<void> preloadCommonAudio(List<String> commonTexts) async {
    if (!_initialized) await initialize();
    if (!_config.enablePreloading) return;

    print('🔄 开始预加载 ${commonTexts.length} 个常用音频');

    // 使用默认配置预生成音频
    final defaultConfig = AudioConfig.defaultConfig();
    int preloadedCount = 0;
    int skippedCount = 0;

    for (final text in commonTexts) {
      try {
        // 计算内容哈希
        final contentHash = _generateContentHash(text);
        final cacheKey = '${contentHash}_${defaultConfig.configHash}';

        // 检查是否已经缓存
        final existing = await getCachedAudio(contentHash, defaultConfig);
        if (existing != null) {
          skippedCount++;
          continue;
        }

        // 创建模拟的音频文件用于预加载
        // 在实际实现中，这里应该调用AudioGenerationEngine生成真实音频
        final mockAudioFile = AudioFile(
          filePath: '/tmp/preload_cache/${contentHash}.mp3',
          contentHash: contentHash,
          config: defaultConfig,
          fileSize: 30000 + (text.length * 100), // 模拟文件大小
          duration: Duration(seconds: 2 + (text.length ~/ 10)), // 模拟时长
          createdAt: DateTime.now(),
          metadata: {'preloaded': true, 'text': text},
        );

        // 创建模拟音频文件
        final file = File(mockAudioFile.filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes([0xFF, 0xFB, 0x90, 0x00]); // 简单的MP3头

        await cacheAudio(mockAudioFile);
        preloadedCount++;

      } catch (e) {
        print('⚠️ 预加载失败: $text, $e');
      }
    }

    print('✅ 预加载完成: ${preloadedCount}个新增, ${skippedCount}个跳过');
  }

  /// 生成内容哈希（公开用于测试）
  String generateContentHash(String content) {
    return _generateContentHash(content);
  }

  /// 生成内容哈希
  String _generateContentHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// 清理过期缓存
  Future<void> cleanupExpiredCache() async {
    if (!_initialized) await initialize();

    final cutoffTime = DateTime.now().subtract(_config.cacheExpiration);
    final expiredKeys = <String>[];

    // 检查磁盘缓存中的过期条目
    for (final entry in _diskCache.entries) {
      if (entry.createdAt.isBefore(cutoffTime)) {
        expiredKeys.add(entry.cacheKey);
      }
    }

    // 删除过期条目
    for (final key in expiredKeys) {
      await _diskCache.remove(key);
      _memoryCache.remove(key);
      _totalEvictions++;
    }

    _lastCleanup = DateTime.now();
    print('🧹 清理了 ${expiredKeys.length} 个过期缓存条目');
  }

  /// 检查并执行清理
  Future<void> _checkAndCleanup() async {
    final totalSize = _diskCache.getTotalSize();
    final maxSizeBytes = _config.maxDiskCacheSize * 1024 * 1024;

    // 检查是否超过条目数限制或大小限制
    if (_diskCache.size > _config.maxCacheEntries || totalSize > maxSizeBytes) {
      await _performLRUEviction();
    }

    // 定期清理过期缓存
    final timeSinceLastCleanup = DateTime.now().difference(_lastCleanup);
    if (timeSinceLastCleanup.inHours > 24) {
      await cleanupExpiredCache();
    }
  }

  /// 执行LRU淘汰
  Future<void> _performLRUEviction() async {
    final entries = _diskCache.entries;
    if (entries.isEmpty) return;

    // 按最后访问时间排序
    entries.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

    // 计算需要淘汰的数量 - 淘汰到目标容量以下
    int targetSize = (_config.maxCacheEntries * 0.8).round(); // 淘汰到80%容量
    int currentSize = entries.length;
    
    if (currentSize <= targetSize) return;

    // 淘汰最旧的条目
    final evictionCount = currentSize - targetSize;
    final toEvict = entries.take(evictionCount).toList();

    for (final entry in toEvict) {
      await _diskCache.remove(entry.cacheKey);
      _memoryCache.remove(entry.cacheKey);
      _totalEvictions++;
    }

    print('🗑️ LRU淘汰了 ${toEvict.length} 个缓存条目');
  }

  /// 从缓存条目创建AudioFile对象
  AudioFile _createAudioFileFromEntry(AudioCacheEntry entry) {
    return AudioFile(
      filePath: entry.filePath,
      contentHash: entry.contentHash,
      config: entry.config,
      fileSize: entry.fileSize,
      duration: const Duration(seconds: 3), // 默认时长，实际应该从metadata读取
      createdAt: entry.createdAt,
      metadata: entry.metadata,
    );
  }

  /// 获取缓存统计
  CacheStatistics getStatistics() {
    final totalRequests = _totalHits + _totalMisses;
    final hitRate = totalRequests > 0 ? _totalHits / totalRequests : 0.0;

    return CacheStatistics(
      totalEntries: _diskCache.size,
      memoryEntries: _memoryCache.size,
      diskEntries: _diskCache.size,
      hitRate: hitRate,
      totalSize: _diskCache.getTotalSize(),
      lastCleanup: _lastCleanup,
      totalHits: _totalHits,
      totalMisses: _totalMisses,
      totalEvictions: _totalEvictions,
    );
  }

  /// 设置缓存配置
  void setCacheConfig(CacheConfig config) {
    _config = config;
    print('✅ 缓存配置已更新');
  }

  /// 获取当前配置
  CacheConfig get config => _config;

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    if (!_initialized) await initialize();

    _memoryCache.clear();
    await _diskCache.clear();
    
    // 重置统计信息
    _totalHits = 0;
    _totalMisses = 0;
    _totalEvictions = 0;
    _lastCleanup = DateTime.now();
    
    print('🧹 所有缓存已清空');
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_initialized) {
      _memoryCache.clear();
      _initialized = false;
      print('✅ 缓存管理系统资源已释放');
    }
  }
}