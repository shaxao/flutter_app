import 'package:flutter/material.dart';
import '../core/services/network_service.dart';
import '../core/services/api_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isNetworkConnected = false;
  bool _isServerConnected = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnections();
  }

  Future<void> _checkConnections() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // 检查网络连接
      final networkConnected = await NetworkService.instance.checkConnection();
      
      // 检查服务器连接
      final serverConnected = await ApiService.instance.healthCheck();

      setState(() {
        _isNetworkConnected = networkConnected;
        _isServerConnected = serverConnected;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isNetworkConnected = false;
        _isServerConnected = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wifi,
                size: 20,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              const Text(
                '连接状态',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (_isChecking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _checkConnections,
                  icon: const Icon(Icons.refresh, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 网络连接状态
          _buildStatusRow(
            icon: Icons.language,
            label: '网络连接',
            isConnected: _isNetworkConnected,
            isChecking: _isChecking,
          ),
          
          const SizedBox(height: 8),
          
          // 服务器连接状态
          _buildStatusRow(
            icon: Icons.cloud,
            label: '服务器连接',
            isConnected: _isServerConnected,
            isChecking: _isChecking,
            subtitle: 'service.muhuo.site',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool isConnected,
    required bool isChecking,
    String? subtitle,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isChecking) {
      statusColor = const Color(0xFF94A3B8);
      statusText = '检查中...';
      statusIcon = Icons.hourglass_empty;
    } else if (isConnected) {
      statusColor = const Color(0xFF10B981);
      statusText = '正常';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusText = '异常';
      statusIcon = Icons.error;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}