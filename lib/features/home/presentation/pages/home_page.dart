import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../reminder/presentation/pages/reminder_page.dart';
import '../../../todo/presentation/pages/todo_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

/// VoiceFlow 首页 - 专注于语音提醒和待办事项
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const ReminderPage();
      case 2:
        return const TodoPage();
      case 3:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }
  
  Widget _buildHomePage() {
    return CustomScrollView(
      slivers: [
        // Hero Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VoiceFlow 大标题
                Text(
                  'VoiceFlow',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.02,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '智能语音助手',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 32),
                
                // 今日概览卡片
                _buildTodayOverview(),
                
                const SizedBox(height: 24),
                
                // 快捷操作
                Text(
                  '快捷操作',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTodayOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mic_rounded,
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
                      '今日概览',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '语音助手为您服务',
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
          const SizedBox(height: 20),
          
          // 统计信息
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.notifications_active_rounded,
                  label: '今日提醒',
                  value: '5',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  label: '已完成',
                  value: '3',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule_rounded,
                  label: '下一个',
                  value: '2h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.mic_rounded,
        'label': '语音提醒',
        'color': const Color(0xFF3B82F6),
        'onTap': () => setState(() => _selectedIndex = 1),
      },
      {
        'icon': Icons.checklist_rounded,
        'label': '待办事项',
        'color': const Color(0xFF10B981),
        'onTap': () => setState(() => _selectedIndex = 2),
      },
      {
        'icon': Icons.record_voice_over_rounded,
        'label': '语音录制',
        'color': const Color(0xFFF59E0B),
        'onTap': () => _showVoiceRecording(),
      },
      {
        'icon': Icons.settings_rounded,
        'label': '设置',
        'color': const Color(0xFF8B5CF6),
        'onTap': () => setState(() => _selectedIndex = 3),
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: action['onTap'] as VoidCallback,
        );
      },
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsPage() {
    return const SettingsPage();
  }
  
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, '首页', 0),
              _buildNavItem(Icons.mic_rounded, '提醒', 1),
              _buildNavItem(Icons.checklist_rounded, '待办', 2),
              _buildNavItem(Icons.person_rounded, '我的', 3),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8);
    
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showVoiceRecording() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _VoiceRecordingModal(),
    );
  }
}

class _VoiceRecordingModal extends StatefulWidget {
  @override
  State<_VoiceRecordingModal> createState() => _VoiceRecordingModalState();
}

class _VoiceRecordingModalState extends State<_VoiceRecordingModal>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isProcessing = false;
  String _recordedText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 拖拽指示器
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // 标题
          Text(
            '语音录制',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRecording 
                ? '正在录制，请说话...' 
                : _isProcessing 
                    ? '正在处理录音...'
                    : '点击下方按钮开始录制',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF475569),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // 录音按钮
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isRecording
                                ? [const Color(0xFFEF4444), const Color(0xFFF87171)]
                                : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording 
                                  ? const Color(0xFFEF4444) 
                                  : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // 录音结果
          if (_recordedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '识别结果:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recordedText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _recordedText.isNotEmpty ? _saveRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '保存',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      if (_isRecording) {
        _stopRecording();
      } else {
        _startRecording();
      }
    });
  }

  void _startRecording() {
    _isRecording = true;
    _pulseController.repeat(reverse: true);
    
    // 模拟录音过程
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _isRecording = false;
    _isProcessing = true;
    _pulseController.stop();
    
    // 模拟语音识别处理
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
        _recordedText = '明天上午9点提醒我开会'; // 模拟识别结果
      });
    });
  }

  void _saveRecording() {
    // TODO: 保存录音结果，可以创建提醒或待办
    Navigator.pop(context);
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('语音备忘已保存'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}