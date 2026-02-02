import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API 服务 - 与现有后端集成
class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();
  
  late final Dio _dio;
  String? _baseUrl;
  String? _token;
  
  Future<void> initialize({String? baseUrl}) async {
    _baseUrl = baseUrl ?? await _getStoredBaseUrl() ?? 'https://service.muhuo.site';
    
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        print('🌐 API Request: ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ API Error: ${error.message}');
        print('❌ Error Type: ${error.type}');
        if (error.response != null) {
          print('❌ Response Status: ${error.response?.statusCode}');
          print('❌ Response Data: ${error.response?.data}');
        }
        handler.next(error);
      },
    ));
    
    // 测试连接
    try {
      print('🔍 Testing connection to: $_baseUrl');
      await healthCheck();
      print('✅ API 连接测试成功');
    } catch (e) {
      print('⚠️ API 连接测试失败，但继续初始化: $e');
    }
  }
  
  Future<String?> _getStoredBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url');
  }
  
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    _dio.options.baseUrl = url;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }
  
  void setToken(String token) {
    _token = token;
  }
  
  // 排班相关 API
  Future<List<Map<String, dynamic>>> getSchedules({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get('/api/schedules', queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      
      return List<Map<String, dynamic>>.from(response.data['schedules'] ?? []);
    } catch (e) {
      print('获取排班失败: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> createSchedule(Map<String, dynamic> schedule) async {
    try {
      final response = await _dio.post('/api/schedules', data: schedule);
      return response.data;
    } catch (e) {
      print('创建排班失败: $e');
      return null;
    }
  }
  
  Future<bool> updateSchedule(int id, Map<String, dynamic> schedule) async {
    try {
      await _dio.put('/api/schedules/$id', data: schedule);
      return true;
    } catch (e) {
      print('更新排班失败: $e');
      return false;
    }
  }
  
  Future<bool> deleteSchedule(int id) async {
    try {
      await _dio.delete('/api/schedules/$id');
      return true;
    } catch (e) {
      print('删除排班失败: $e');
      return false;
    }
  }
  
  // 提醒相关 API
  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final response = await _dio.get('/api/reminders');
      return List<Map<String, dynamic>>.from(response.data['reminders'] ?? []);
    } catch (e) {
      print('获取提醒失败: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> createReminder(Map<String, dynamic> reminder) async {
    try {
      final response = await _dio.post('/api/reminders', data: reminder);
      return response.data;
    } catch (e) {
      print('创建提醒失败: $e');
      return null;
    }
  }
  
  // 菜单相关 API
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final response = await _dio.get('/api/menu');
      return List<Map<String, dynamic>>.from(response.data['items'] ?? []);
    } catch (e) {
      print('获取菜单失败: $e');
      return [];
    }
  }
  
  // 考勤相关 API
  Future<Map<String, dynamic>?> clockIn() async {
    try {
      final response = await _dio.post('/api/attendance/clock-in');
      return response.data;
    } catch (e) {
      print('打卡失败: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> clockOut() async {
    try {
      final response = await _dio.post('/api/attendance/clock-out');
      return response.data;
    } catch (e) {
      print('下班打卡失败: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get('/api/attendance', queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      
      return List<Map<String, dynamic>>.from(response.data['records'] ?? []);
    } catch (e) {
      print('获取考勤记录失败: $e');
      return [];
    }
  }
  
  // 健康检查
  Future<bool> healthCheck() async {
    try {
      print('🏥 开始健康检查: $_baseUrl/health');
      final response = await _dio.get('/health');
      final isHealthy = response.statusCode == 200;
      print(isHealthy ? '✅ 服务器健康检查通过' : '⚠️ 服务器健康检查失败');
      return isHealthy;
    } catch (e) {
      print('❌ 健康检查异常: $e');
      // 尝试备用检查路径
      try {
        print('🔄 尝试备用健康检查路径: $_baseUrl/');
        final response = await _dio.get('/');
        final isHealthy = response.statusCode == 200;
        print(isHealthy ? '✅ 备用健康检查通过' : '⚠️ 备用健康检查失败');
        return isHealthy;
      } catch (e2) {
        print('❌ 备用健康检查也失败: $e2');
        return false;
      }
    }
  }
  
  // 通用 HTTP 方法
  String get baseUrl => _baseUrl ?? 'http://localhost:5000';
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.patch(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.delete(path, data: data, queryParameters: queryParameters);
  }
}