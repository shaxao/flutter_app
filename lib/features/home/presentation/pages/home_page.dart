import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reminder/presentation/pages/reminder_page.dart';
import '../../../todo/presentation/pages/todo_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

/// VoiceFlow 首页 - 极简黑白红设计
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
      backgroundColor: AppTheme.background,
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
        return const SettingsPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOICEFLOW',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        letterSpacing: 2.0, // Wide spacing for premium feel
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 2,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '智能语音助手',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Overview Card
                _buildOverviewCard(),

                const SizedBox(height: 48),

                // Quick Actions Title
                Text(
                  '快捷操作',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.5,
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

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.mic_none_outlined, color: AppTheme.primary, size: 32),
              Text(
                '今日概览',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '系统运行中',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '语音指令准备就绪',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              _buildStat('5', '提醒'),
              const SizedBox(width: 48),
              _buildStat('3', '任务'),
              const SizedBox(width: 48),
              _buildStat('2h', '下一个'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          '语音',
          Icons.mic_none,
          () => setState(() => _selectedIndex = 1),
        ),
        _buildActionCard(
          '任务',
          Icons.check_box_outlined,
          () => setState(() => _selectedIndex = 2),
        ),
        _buildActionCard(
          '录音',
          Icons.graphic_eq,
          _showVoiceRecording,
        ),
        _buildActionCard(
          '设置',
          Icons.settings_outlined,
          () => setState(() => _selectedIndex = 3),
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.surfaceHighlight,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.textPrimary, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.grid_view, 0),
            _buildNavItem(Icons.mic_none, 1),
            _buildNavItem(Icons.check_box_outlined, 2),
            _buildNavItem(Icons.settings_outlined, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => setState(() => _selectedIndex = index),
      icon: Icon(
        icon,
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        size: 24,
      ),
      style: IconButton.styleFrom(
        hoverColor: AppTheme.surfaceHighlight,
      ),
    );
  }

  void _showVoiceRecording() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const _VoiceRecordingDialog(),
    );
  }
}

class _VoiceRecordingDialog extends StatefulWidget {
  const _VoiceRecordingDialog();

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
        // Mock save after delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.primary, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        padding: const EdgeInsets.all(48),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isRecording ? '正在录音...' : '准备就绪',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: _isRecording ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRecording
                            ? AppTheme.primary
                                .withOpacity(1.0 - _controller.value * 0.5)
                            : AppTheme.textSecondary,
                        width: 2,
                      ),
                      color: _isRecording
                          ? AppTheme.primary.withOpacity(0.2)
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          shape: _isRecording
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius:
                              _isRecording ? BorderRadius.circular(2) : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
