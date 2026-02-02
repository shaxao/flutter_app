import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 设置项状态
  double _voiceSpeed = 0.5;
  double _voiceVolume = 1.0;
  bool _enableVibration = true;
  bool _enableNotifications = true;
  String _selectedLanguage = 'zh-CN';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildVoiceSettings(),
          const SizedBox(height: 24),
          _buildReminderSettings(),
          const SizedBox(height: 24),
          _buildAppSettings(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        '设置',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VoiceFlow 设置',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '个性化您的语音助手体验',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceSettings() {
    return _buildSettingsSection(
      title: '语音设置',
      icon: Icons.record_voice_over_rounded,
      color: const Color(0xFF3B82F6),
      children: [
        _buildSliderSetting(
          title: '语音速度',
          subtitle: '调整语音播报的速度',
          value: _voiceSpeed,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          onChanged: (value) => setState(() => _voiceSpeed = value),
          valueLabel: '${(_voiceSpeed * 10).round()}/10',
        ),
        _buildSliderSetting(
          title: '音量大小',
          subtitle: '调整语音播报的音量',
          value: _voiceVolume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) => setState(() => _voiceVolume = value),
          valueLabel: '${(_voiceVolume * 100).round()}%',
        ),
        _buildDropdownSetting(
          title: '语言选择',
          subtitle: '选择语音播报的语言',
          value: _selectedLanguage,
          items: const [
            {'value': 'zh-CN', 'label': '中文 (简体)'},
            {'value': 'zh-TW', 'label': '中文 (繁体)'},
            {'value': 'en-US', 'label': 'English (US)'},
            {'value': 'ja-JP', 'label': '日本語'},
          ],
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
      ],
    );
  }
  
  Widget _buildReminderSettings() {
    return _buildSettingsSection(
      title: '提醒设置',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFFF59E0B),
      children: [
        _buildSwitchSetting(
          title: '启用通知',
          subtitle: '允许应用发送通知提醒',
          value: _enableNotifications,
          onChanged: (value) => setState(() => _enableNotifications = value),
        ),
        _buildSwitchSetting(
          title: '震动反馈',
          subtitle: '提醒时启用震动反馈',
          value: _enableVibration,
          onChanged: (value) => setState(() => _enableVibration = value),
        ),
        _buildTapSetting(
          title: '勿扰时段',
          subtitle: '设置不接收提醒的时间段',
          onTap: () => _showDoNotDisturbSettings(),
        ),
        _buildTapSetting(
          title: '默认提前时间',
          subtitle: '设置提醒的默认提前时间',
          onTap: () => _showDefaultReminderTime(),
        ),
      ],
    );
  }
  
  Widget _buildAppSettings() {
    return _buildSettingsSection(
      title: '应用设置',
      icon: Icons.apps_rounded,
      color: const Color(0xFF10B981),
      children: [
        _buildTapSetting(
          title: '数据备份',
          subtitle: '备份您的提醒和待办数据',
          onTap: () => _showBackupOptions(),
        ),
        _buildTapSetting(
          title: '数据恢复',
          subtitle: '从备份恢复您的数据',
          onTap: () => _showRestoreOptions(),
        ),
        _buildTapSetting(
          title: '清除数据',
          subtitle: '清除所有应用数据',
          onTap: () => _showClearDataDialog(),
        ),
      ],
    );
  }
  
  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: '关于应用',
      icon: Icons.info_rounded,
      color: const Color(0xFF6B7280),
      children: [
        _buildTapSetting(
          title: 'VoiceFlow',
          subtitle: '版本 1.0.0 (Build 1)',
          onTap: () => _showAboutDialog(),
        ),
        _buildTapSetting(
          title: '使用帮助',
          subtitle: '查看应用使用指南',
          onTap: () => _showHelpDialog(),
        ),
        _buildTapSetting(
          title: '反馈建议',
          subtitle: '向我们提供反馈和建议',
          onTap: () => _showFeedbackDialog(),
        ),
        _buildTapSetting(
          title: '隐私政策',
          subtitle: '查看隐私政策和服务条款',
          onTap: () => _showPrivacyPolicy(),
        ),
      ],
    );
  }
  
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF475569),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              Text(
                valueLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF475569),
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Text(
              item['label']!,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildTapSetting({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF475569),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }
  
  // 对话框和设置方法
  void _showDoNotDisturbSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('勿扰时段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('开始时间'),
              subtitle: const Text('22:00'),
              trailing: const Icon(Icons.access_time),
              onTap: () {
                // TODO: 时间选择器
              },
            ),
            ListTile(
              title: const Text('结束时间'),
              subtitle: const Text('08:00'),
              trailing: const Icon(Icons.access_time),
              onTap: () {
                // TODO: 时间选择器
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '在勿扰时段内，应用将不会发送语音提醒',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showDefaultReminderTime() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('默认提前时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('5分钟前'),
              value: 5,
              groupValue: 15, // 默认选中15分钟
              onChanged: (value) {},
            ),
            RadioListTile<int>(
              title: const Text('15分钟前'),
              value: 15,
              groupValue: 15,
              onChanged: (value) {},
            ),
            RadioListTile<int>(
              title: const Text('30分钟前'),
              value: 30,
              groupValue: 15,
              onChanged: (value) {},
            ),
            RadioListTile<int>(
              title: const Text('1小时前'),
              value: 60,
              groupValue: 15,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据备份'),
        content: const Text('数据备份功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showRestoreOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据恢复'),
        content: const Text('数据恢复功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除数据'),
        content: const Text('确定要清除所有应用数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现清除数据功能
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'VoiceFlow',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        Text(
          'VoiceFlow 是一款专业的智能语音助手应用，专注于语音提醒和待办事项管理。',
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const Text('使用帮助功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('反馈建议'),
        content: const Text('反馈建议功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const Text('隐私政策功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}