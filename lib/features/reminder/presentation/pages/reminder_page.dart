import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb support
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/voice_reminder_provider.dart';
import '../../domain/models/voice_reminder.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceReminderProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<VoiceReminderProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                                  '提醒列表',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 1.5,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 2,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '智能提醒系统',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.primary,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildActionButton(
                                  icon: Icons.upload_file,
                                  onTap: () =>
                                      _showBatchImportDialog(context, provider),
                                ),
                                const SizedBox(width: 12),
                                if (provider.reminders.isNotEmpty)
                                  _buildActionButton(
                                    icon: Icons.delete_sweep,
                                    isDestructive: true,
                                    onTap: () =>
                                        _showDeleteAllDialog(context, provider),
                                  ),
                                const SizedBox(width: 12),
                                _buildActionButton(
                                  icon: Icons.add,
                                  isPrimary: true,
                                  onTap: () =>
                                      _showAddReminderDialog(context, provider),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // System Status Panel
                        _buildSystemStatusPanel(provider),

                        const SizedBox(height: 24),

                        // Test Section
                        _buildTestSection(provider),
                      ],
                    ),
                  ),
                ),

                // Reminders List
                if (provider.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child:
                            CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    ),
                  )
                else if (provider.reminders.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_outlined,
                              size: 48,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无待办任务',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                letterSpacing: 1.5,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '初始化新的提醒协议。',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder = provider.sortedReminders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:
                                _buildReminderCard(context, provider, reminder),
                          );
                        },
                        childCount: provider.sortedReminders.length,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isPrimary = false,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    Color iconColor;
    Color borderColor;
    Color? backgroundColor;

    if (isPrimary) {
      iconColor = Colors.white;
      borderColor = AppTheme.primary;
      backgroundColor = AppTheme.primary;
    } else if (isDestructive) {
      iconColor = AppTheme.primary;
      borderColor = AppTheme.primary;
      backgroundColor = Colors.transparent;
    } else {
      iconColor = AppTheme.textPrimary;
      borderColor = AppTheme.border;
      backgroundColor = Colors.transparent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor:
            isPrimary ? AppTheme.primaryLight : AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildSystemStatusPanel(VoiceReminderProvider provider) {
    final status = provider.serviceStatus;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '系统状态',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '同步: ${DateTime.now().toString().substring(11, 16)}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textDisabled,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatusChip(
                '核心: ${status['isInitialized'] ? '在线' : '离线'}',
                status['isInitialized'] ? AppTheme.textPrimary : AppTheme.error,
              ),
              _buildStatusChip(
                '调度器: ${status['isSchedulerRunning'] ? '运行中' : '空闲'}',
                status['isSchedulerRunning']
                    ? AppTheme.textPrimary
                    : AppTheme.textDisabled,
              ),
              _buildStatusChip(
                'TTS: ${status['ttsAvailable'] ? '就绪' : '不可用'}',
                status['ttsAvailable']
                    ? AppTheme.textPrimary
                    : AppTheme.textDisabled,
              ),
              _buildStatusChip(
                '推送: ${status['notificationsAvailable'] ? '已启用' : '已禁用'}',
                status['notificationsAvailable']
                    ? AppTheme.textPrimary
                    : AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '活跃线程: ${status['scheduledCount']}',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
            color: color == AppTheme.error ? AppTheme.error : AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(VoiceReminderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '诊断',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTestButton(
                  '测试语音',
                  () => provider.testVoice('系统语音诊断序列已启动。'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTestButton(
                  '测试推送',
                  () => provider.testSystemNotification(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: const BorderSide(color: AppTheme.border),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context,
      VoiceReminderProvider provider, VoiceReminder reminder) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: reminder.enabled
              ? AppTheme.border
              : AppTheme.border.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reminder.time,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: reminder.enabled
                            ? AppTheme.textPrimary
                            : AppTheme.textDisabled,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildReminderTypeChip(reminder.reminderType),
                    if (!reminder.enabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighlight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'DISABLED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reminder.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: reminder.enabled
                        ? AppTheme.textSecondary
                        : AppTheme.textDisabled,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Switch(
                value: reminder.enabled,
                onChanged: (value) => provider.toggleReminder(reminder),
                activeColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withOpacity(0.3),
                inactiveThumbColor: AppTheme.textDisabled,
                inactiveTrackColor: AppTheme.surfaceHighlight,
              ),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: AppTheme.textSecondary),
                color: AppTheme.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditReminderDialog(context, provider, reminder);
                      break;
                    case 'copy':
                      _copyReminderContent(reminder.content);
                      break;
                    case 'delete':
                      _showDeleteReminderDialog(context, provider, reminder);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _buildPopupItem('edit', '编辑', Icons.edit_outlined),
                  _buildPopupItem('copy', '复制', Icons.copy_outlined),
                  _buildPopupItem('delete', '删除', Icons.delete_outline,
                      isDestructive: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, String label, IconData icon,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isDestructive ? AppTheme.primary : AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDestructive ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTypeChip(ReminderType type) {
    String label;
    switch (type) {
      case ReminderType.system:
        label = '系统';
        break;
      case ReminderType.aiVoice:
        label = 'AI';
        break;
      case ReminderType.customAudio:
        label = '音频';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.textSecondary),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _showAddReminderDialog(
      BuildContext context, VoiceReminderProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _ReminderDialog(
        provider: provider,
        title: '新建提醒',
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context,
      VoiceReminderProvider provider, VoiceReminder reminder) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _ReminderDialog(
        provider: provider,
        title: '编辑提醒',
        reminder: reminder,
      ),
    );
  }

  void _showBatchImportDialog(
      BuildContext context, VoiceReminderProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _BatchImportDialog(provider: provider),
    );
  }

  void _showDeleteReminderDialog(BuildContext context,
      VoiceReminderProvider provider, VoiceReminder reminder) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.primary, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text('删除确认',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.primary)),
        content: Text('永久删除提醒 "${reminder.content}"?',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteReminder(reminder.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(
      BuildContext context, VoiceReminderProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.primary, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text('PURGE ALL',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.primary)),
        content: const Text(
            'This will delete ALL reminders. This action is irreversible.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteAllReminders();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('CONFIRM PURGE'),
          ),
        ],
      ),
    );
  }

  void _copyReminderContent(String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('COPIED: $content'),
        backgroundColor: AppTheme.surfaceHighlight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final VoiceReminderProvider provider;
  final String title;
  final VoiceReminder? reminder;

  const _ReminderDialog({
    required this.provider,
    required this.title,
    this.reminder,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog>
    with SingleTickerProviderStateMixin {
  final _timeController = TextEditingController();
  final _contentController = TextEditingController();

  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  ReminderType _reminderType = ReminderType.aiVoice;
  String _voiceModel = 'tts-1';

  // Ringtone Selection
  String? _audioFilePath;
  bool _isPreset = true;
  bool _isPlaying = false;
  String? _playingPath;

  // Fade In
  bool _useFadeIn = false;
  int _fadeInDuration = 5;

  TimeOfDay? _selectedTime;

  final List<Map<String, String>> _presetRingtones = [
    {'name': '经典闹钟', 'path': 'assets/audio/classic_alarm.mp3'},
    {'name': '清晨鸟鸣', 'path': 'assets/audio/morning_birds.mp3'},
    {'name': '轻柔雨声', 'path': 'assets/audio/gentle_rain.mp3'},
    {'name': '宇宙流动', 'path': 'assets/audio/cosmic_flow.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.reminder != null) {
      final reminder = widget.reminder!;
      _timeController.text = reminder.time;
      _contentController.text = reminder.content;
      _reminderType = reminder.reminderType;
      _voiceModel = reminder.voiceModel ?? 'tts-1';
      _audioFilePath = reminder.audioFilePath;
      _isPreset = reminder.isPreset;
      _useFadeIn = reminder.useFadeIn;
      _fadeInDuration = reminder.fadeInDuration;

      if (_reminderType == ReminderType.customAudio) {
        _tabController.index = _isPreset ? 0 : 1;
      }

      final timeParts = reminder.time.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    } else {
      _audioFilePath = _presetRingtones.first['path'];
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    _timeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: 32),

              // Time Input
              _buildSectionTitle('时间'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _timeController.text.isEmpty
                            ? '选择时间'
                            : _timeController.text,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content Input
              _buildSectionTitle('内容'),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: '例如：下午2点开会',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Reminder Type
              _buildSectionTitle('类型'),
              const SizedBox(height: 12),
              ...ReminderType.values.map((type) => RadioListTile<ReminderType>(
                    title: Text(type.displayName,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary)),
                    subtitle: Text(type.description,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    value: type,
                    groupValue: _reminderType,
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) =>
                        setState(() => _reminderType = value!),
                  )),

              // Voice Model (for AI Voice)
              if (_reminderType == ReminderType.aiVoice) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('语音模型'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _voiceModel,
                  dropdownColor: AppTheme.surface,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: widget.provider.ttsModels
                      .map((model) => DropdownMenuItem(
                            value: model.id,
                            child: Text(model.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _voiceModel = value!),
                ),
              ],

              // Audio Selection (for Custom Audio)
              if (_reminderType == ReminderType.customAudio) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('铃声'),
                const SizedBox(height: 12),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primary,
                  tabs: const [
                    Tab(text: '系统'),
                    Tab(text: '上传'),
                  ],
                ),

                SizedBox(
                  height: 200, // Fixed height for list
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // System Presets
                      ListView.builder(
                        itemCount: _presetRingtones.length,
                        itemBuilder: (context, index) {
                          final ringtone = _presetRingtones[index];
                          final isSelected =
                              _isPreset && _audioFilePath == ringtone['path'];
                          final isPlayingThis =
                              _isPlaying && _playingPath == ringtone['path'];

                          return ListTile(
                            title: Text(ringtone['name']!,
                                style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary)),
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                            trailing: IconButton(
                              icon: Icon(isPlayingThis
                                  ? Icons.stop_circle
                                  : Icons.play_circle_fill),
                              color: AppTheme.primary,
                              onPressed: () => _previewAudio(ringtone['path']!),
                            ),
                            onTap: () {
                              setState(() {
                                _isPreset = true;
                                _audioFilePath = ringtone['path'];
                              });
                            },
                          );
                        },
                      ),

                      // Local Upload
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_audioFilePath != null && !_isPreset) ...[
                              Icon(Icons.audio_file,
                                  size: 48, color: AppTheme.primary),
                              const SizedBox(height: 8),
                              Text(
                                _audioFilePath!.split('/').last,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _previewAudio(_audioFilePath!),
                                    icon: Icon(_isPlaying
                                        ? Icons.stop
                                        : Icons.play_arrow),
                                    label: Text(_isPlaying ? 'STOP' : 'PLAY'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _selectAudioFile,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('RESELECT'),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Icon(Icons.cloud_upload_outlined,
                                  size: 64, color: AppTheme.textSecondary),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _selectAudioFile,
                                child: const Text('UPLOAD FILE'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'MP3, M4A, OGG (≤ 5MB)',
                                style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fade In Option
                const Divider(color: AppTheme.border),
                SwitchListTile(
                  title: Text('FADE IN',
                      style: GoogleFonts.inter(color: AppTheme.textPrimary)),
                  subtitle: Text('Volume increases 0-100% over duration',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  value: _useFadeIn,
                  activeColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.surfaceHighlight,
                  onChanged: (value) => setState(() => _useFadeIn = value),
                ),
                if (_useFadeIn)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text('Duration: ',
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary)),
                        Expanded(
                          child: Slider(
                            value: _fadeInDuration.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '${_fadeInDuration}s',
                            activeColor: AppTheme.primary,
                            onChanged: (value) =>
                                setState(() => _fadeInDuration = value.toInt()),
                          ),
                        ),
                        Text('${_fadeInDuration}s',
                            style:
                                GoogleFonts.inter(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _audioPlayer.stop();
                      Navigator.pop(context);
                    },
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveReminder,
                    child: Text(
                        widget.reminder != null ? 'SAVE CHANGES' : 'CREATE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        _timeController.text =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'ogg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件大小限制: 5MB')),
          );
          return;
        }

        String? uploadedPath;
        if (kIsWeb) {
          if (file.bytes != null) {
            uploadedPath =
                await widget.provider.uploadAudioBytes(file.bytes!, file.name);
          }
        } else {
          final filePath = file.path;
          if (filePath != null) {
            uploadedPath =
                await widget.provider.uploadAudioFile(File(filePath));
          }
        }

        if (uploadedPath != null) {
          setState(() {
            _audioFilePath = uploadedPath;
            _isPreset = false;
            _tabController.index = 1;
          });

          // Auto preview
          _previewAudio(uploadedPath);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _previewAudio(String path) async {
    try {
      if (_isPlaying && _playingPath == path) {
        await _audioPlayer.stop();
        setState(() {
          _playingPath = null;
        });
      } else {
        await _audioPlayer.stop(); // Stop previous

        // Handle asset vs local file
        if (path.startsWith('assets/')) {
          await _audioPlayer
              .play(AssetSource(path.replaceFirst('assets/', '')));
        } else {
          await _audioPlayer.play(DeviceFileSource(path));
        }

        setState(() {
          _playingPath = path;
        });

        // Stop after 10 seconds (preview limit)
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isPlaying && _playingPath == path) {
            _audioPlayer.stop();
          }
        });
      }
    } catch (e) {
      print('Preview error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview failed: $e')),
      );
    }
  }

  void _saveReminder() async {
    if (_timeController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有字段')),
      );
      return;
    }

    if (_reminderType == ReminderType.customAudio && _audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个音频文件')),
      );
      return;
    }

    // Check permission
    final hasPermission =
        await NotificationService.instance.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要权限'),
            content: const Text('语音提醒需要通知权限。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  NotificationService.instance.requestPermission();
                },
                child: const Text('启用'),
              ),
            ],
          ),
        );
      }
    }

    final reminder = VoiceReminder(
      id: widget.reminder?.id,
      time: _timeController.text,
      content: _contentController.text,
      reminderType: _reminderType,
      voiceModel: _reminderType == ReminderType.aiVoice ? _voiceModel : null,
      audioFilePath:
          _reminderType == ReminderType.customAudio ? _audioFilePath : null,
      isPreset: _isPreset,
      useFadeIn: _useFadeIn,
      fadeInDuration: _fadeInDuration,
    );

    if (widget.reminder != null) {
      widget.provider.updateReminder(reminder);
    } else {
      widget.provider.createReminder(reminder);
    }

    Navigator.pop(context);
  }
}

class _BatchImportDialog extends StatefulWidget {
  final VoiceReminderProvider provider;

  const _BatchImportDialog({required this.provider});

  @override
  State<_BatchImportDialog> createState() => _BatchImportDialogState();
}

class _BatchImportDialogState extends State<_BatchImportDialog> {
  final _textController = TextEditingController();
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('批量导入',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Text('格式: 每行"内容 时间"',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '会议 14:00\n健身 18:30',
                style: GoogleFonts.firaCode(
                    fontSize: 12, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '在此输入提醒...',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isImporting ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isImporting ? null : _importReminders,
                  child: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('导入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importReminders() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final result =
          await widget.provider.batchImportReminders(_textController.text);

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('IMPORT RESULT',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Success: ${result.imported}',
                  style: TextStyle(color: AppTheme.success)),
              Text('Failed: ${result.failed}',
                  style: TextStyle(color: AppTheme.error)),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Errors:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                ...result.errors.map((error) => Text('• $error',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      setState(() => _isImporting = false);
    }
  }
}
