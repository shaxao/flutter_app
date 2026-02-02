import 'dart:io';
import 'package:flutter/foundation.dart';

/// 网络连接服务
class NetworkService {
  static final NetworkService instance = NetworkService._();
  NetworkService._();
  
  bool _isConnected = false;
  String _connectionStatus = '检查中...';
  
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  
  /// 检查网络连接
  Future<bool> checkConnection() async {
    if (kIsWeb) {
      // Web 环境下假设有网络连接
      _isConnected = true;
      _connectionStatus = '网络连接正常';
      return true;
    }
    
    try {
      _connectionStatus = '正在检查网络连接...';
      
      // 尝试连接到可靠的服务器
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isConnected = true;
        _connectionStatus = '网络连接正常';
        print('✅ 网络连接检查通过');
        return true;
      }
    } catch (e) {
      print('❌ 网络连接检查失败: $e');
    }
    
    _isConnected = false;
    _connectionStatus = '网络连接异常';
    return false;
  }
  
  /// 检查特定服务器连接
  Future<bool> checkServerConnection(String host) async {
    if (kIsWeb) {
      return true; // Web 环境下无法直接检查
    }
    
    try {
      _connectionStatus = '正在检查服务器连接...';
      
      // 从 URL 中提取主机名
      final uri = Uri.parse(host.startsWith('http') ? host : 'https://$host');
      final hostname = uri.host;
      
      print('🔍 检查服务器连接: $hostname');
      
      final result = await InternetAddress.lookup(hostname);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _connectionStatus = '服务器连接正常';
        print('✅ 服务器连接检查通过: $hostname');
        return true;
      }
    } catch (e) {
      print('❌ 服务器连接检查失败: $e');
    }
    
    _connectionStatus = '服务器连接异常';
    return false;
  }
  
  /// 获取网络状态描述
  String getNetworkStatusDescription() {
    if (_isConnected) {
      return '🟢 网络连接正常';
    } else {
      return '🔴 网络连接异常';
    }
  }
}