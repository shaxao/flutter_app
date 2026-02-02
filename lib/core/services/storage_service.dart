import 'package:hive_flutter/hive_flutter.dart';

/// 本地存储服务 - 使用 Hive
class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();
  
  late Box _scheduleBox;
  late Box _reminderBox;
  late Box _settingsBox;
  late Box _cacheBox;
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    // 打开数据盒子
    _scheduleBox = await Hive.openBox('schedules');
    _reminderBox = await Hive.openBox('reminders');
    _settingsBox = await Hive.openBox('settings');
    _cacheBox = await Hive.openBox('cache');
    
    _initialized = true;
  }
  
  // 排班数据
  Future<void> saveSchedule(String id, Map<String, dynamic> schedule) async {
    await _scheduleBox.put(id, schedule);
  }
  
  Map<String, dynamic>? getSchedule(String id) {
    final data = _scheduleBox.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  List<Map<String, dynamic>> getAllSchedules() {
    return _scheduleBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  
  Future<void> deleteSchedule(String id) async {
    await _scheduleBox.delete(id);
  }
  
  Future<void> clearSchedules() async {
    await _scheduleBox.clear();
  }
  
  // 提醒数据
  Future<void> saveReminder(String id, Map<String, dynamic> reminder) async {
    await _reminderBox.put(id, reminder);
  }
  
  Map<String, dynamic>? getReminder(String id) {
    final data = _reminderBox.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  List<Map<String, dynamic>> getAllReminders() {
    return _reminderBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  
  Future<void> deleteReminder(String id) async {
    await _reminderBox.delete(id);
  }
  
  Future<void> clearReminders() async {
    await _reminderBox.clear();
  }
  
  // 设置数据
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }
  
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }
  
  // 缓存数据
  Future<void> saveCache(String key, dynamic value, {Duration? expiry}) async {
    final data = {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await _cacheBox.put(key, data);
  }
  
  T? getCache<T>(String key) {
    final data = _cacheBox.get(key);
    if (data == null) return null;
    
    final cacheData = Map<String, dynamic>.from(data);
    final timestamp = cacheData['timestamp'] as int;
    final expiry = cacheData['expiry'] as int?;
    
    // 检查是否过期
    if (expiry != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        _cacheBox.delete(key);
        return null;
      }
    }
    
    return cacheData['value'] as T?;
  }
  
  Future<void> deleteCache(String key) async {
    await _cacheBox.delete(key);
  }
  
  Future<void> clearCache() async {
    await _cacheBox.clear();
  }
  
  // 数据同步状态
  Future<void> markSynced(String type, String id) async {
    final syncKey = 'sync_${type}_$id';
    await saveSetting(syncKey, DateTime.now().toIso8601String());
  }
  
  bool isSynced(String type, String id) {
    final syncKey = 'sync_${type}_$id';
    return getSetting<String>(syncKey) != null;
  }
  
  Future<void> markDirty(String type, String id) async {
    final syncKey = 'sync_${type}_$id';
    await deleteSetting(syncKey);
  }
  
  // 获取需要同步的数据
  List<String> getDirtySchedules() {
    final allSchedules = getAllSchedules();
    return allSchedules
        .where((schedule) => !isSynced('schedule', schedule['id']))
        .map((schedule) => schedule['id'] as String)
        .toList();
  }
  
  List<String> getDirtyReminders() {
    final allReminders = getAllReminders();
    return allReminders
        .where((reminder) => !isSynced('reminder', reminder['id']))
        .map((reminder) => reminder['id'] as String)
        .toList();
  }
  
  // 数据统计
  int get scheduleCount => _scheduleBox.length;
  int get reminderCount => _reminderBox.length;
  int get cacheSize => _cacheBox.length;
  
  // 清理所有数据
  Future<void> clearAllData() async {
    await Future.wait([
      _scheduleBox.clear(),
      _reminderBox.clear(),
      _settingsBox.clear(),
      _cacheBox.clear(),
    ]);
  }
}