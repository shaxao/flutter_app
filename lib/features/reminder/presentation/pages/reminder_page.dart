import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/voice_reminder_provider.dart';
import '../../domain/models/voice_reminder.dart';

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
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Consumer<VoiceReminderProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '语音提醒',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '智能语音提醒系统',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildActionButton(
                                  icon: Icons.upload_file,
                                  color: Colors.blue,
                                  onTap: () => _showBatchImportDialog(context, provider),
                                ),
                                const SizedBox(width: 8),
                                if (provider.reminders.isNotEmpty)
                                  _buildActionButton(
                                    icon: Icons.delete_sweep,
                                    color: Colors.red,
                                    onTap: () => _showDeleteAllDialog(context, provider),
                                  ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.add,
                                  color: Colors.green,
                                  onTap: () => _showAddReminderDialog(context, provider),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // System Status Panel
                        _buildSystemStatusPanel(provider),
                        
                        const SizedBox(height: 16),
                        
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
                        child: CircularProgressIndicator(),
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
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无提醒任务',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击右上角 + 号添加新的语音提醒',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder = provider.sortedReminders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReminderCard(context, provider, reminder),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildSystemStatusPanel(VoiceReminderProvider provider) {
    final status = provider.serviceStatus;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '系统运行状态',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '上次检查: ${DateTime.now().toString().substring(11, 16)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                '服务${status['isInitialized'] ? '正常' : '异常'}',
                status['isInitialized'] ? Colors.green : Colors.red,
              ),
              _buildStatusChip(
                '调度器${status['isSchedulerRunning'] ? '运行中' : '未启动'}',
                status['isSchedulerRunning'] ? Colors.purple : Colors.grey,
              ),
              _buildStatusChip(
                'TTS${status['ttsAvailable'] ? '可用' : '不可用'}',
                status['ttsAvailable'] ? Colors.blue : Colors.orange,
              ),
              _buildStatusChip(
                '通知${status['notificationsAvailable'] ? '正常' : '异常'}',
                status['notificationsAvailable'] ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '已调度提醒: ${status['scheduledCount']} 个',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTestSection(VoiceReminderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up, color: Colors.green[600], size: 16),
              const SizedBox(width: 8),
              Text(
                '语音播报与推送测试',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTestButton(
                  '语音测试',
                  Colors.green,
                  () => provider.testVoice('语音测试：系统语音功能正常工作'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTestButton(
                  '推送测试',
                  Colors.blue,
                  () => provider.testSystemNotification(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '如果无法听到声音，请检查设备音量设置。系统将优先使用本地 TTS。',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[600]?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, VoiceReminderProvider provider, VoiceReminder reminder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!reminder.enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '已禁用',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    _buildReminderTypeChip(reminder.reminderType),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Switch(
                value: reminder.enabled,
                onChanged: (value) => provider.toggleReminder(reminder),
                activeColor: const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
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
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  const PopupMenuItem(value: 'copy', child: Text('复制内容')),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTypeChip(ReminderType type) {
    Color color;
    String label;
    
    switch (type) {
      case ReminderType.system:
        color = Colors.blue;
        label = '通知';
        break;
      case ReminderType.aiVoice:
        color = Colors.purple;
        label = 'AI';
        break;
      case ReminderType.customAudio:
        color = Colors.orange;
        label = '音频';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, VoiceReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        provider: provider,
        title: '新建提醒',
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context, VoiceReminderProvider provider, VoiceReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        provider: provider,
        title: '编辑提醒',
        reminder: reminder,
      ),
    );
  }

  void _showBatchImportDialog(BuildContext context, VoiceReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _BatchImportDialog(provider: provider),
    );
  }

  void _showDeleteReminderDialog(BuildContext context, VoiceReminderProvider provider, VoiceReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除提醒'),
        content: Text('确定要删除提醒"${reminder.content}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteReminder(reminder.id!);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, VoiceReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除所有提醒'),
        content: const Text('确定要删除所有提醒吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteAllReminders();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyReminderContent(String content) {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: $content')),
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

class _ReminderDialogState extends State<_ReminderDialog> {
  final _timeController = TextEditingController();
  final _contentController = TextEditingController();
  ReminderType _reminderType = ReminderType.aiVoice;
  String _voiceModel = 'tts-1';
  String? _audioFilePath;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final reminder = widget.reminder!;
      _timeController.text = reminder.time;
      _contentController.text = reminder.content;
      _reminderType = reminder.reminderType;
      _voiceModel = reminder.voiceModel ?? 'tts-1';
      _audioFilePath = reminder.audioFilePath;
      
      final timeParts = reminder.time.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Input
            const Text('提醒时间', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    Text(_timeController.text.isEmpty ? '点击选择时间' : _timeController.text),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Content Input
            const Text('提醒内容', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '例如：蜗牛 14点',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Reminder Type
            const Text('提醒方式', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...ReminderType.values.map((type) => RadioListTile<ReminderType>(
              title: Text(type.displayName),
              subtitle: Text(type.description, style: const TextStyle(fontSize: 12)),
              value: type,
              groupValue: _reminderType,
              onChanged: (value) => setState(() => _reminderType = value!),
            )),
            
            // Voice Model (for AI Voice)
            if (_reminderType == ReminderType.aiVoice) ...[
              const SizedBox(height: 16),
              const Text('语音模型', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _voiceModel,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: widget.provider.ttsModels.map((model) => DropdownMenuItem(
                  value: model.id,
                  child: Text(model.name),
                )).toList(),
                onChanged: (value) => setState(() => _voiceModel = value!),
              ),
            ],
            
            // Audio File (for Custom Audio)
            if (_reminderType == ReminderType.customAudio) ...[
              const SizedBox(height: 16),
              const Text('音频文件', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectAudioFile,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_audioFilePath != null ? Icons.check_circle : Icons.upload_file),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _audioFilePath != null ? '✓ 音频已上传' : '点击上传音频文件',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _saveReminder,
          child: Text(widget.reminder != null ? '保存' : '添加'),
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final filePath = await widget.provider.uploadAudioFile(file);
        setState(() {
          _audioFilePath = filePath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e')),
      );
    }
  }

  void _saveReminder() {
    if (_timeController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写时间和内容')),
      );
      return;
    }

    if (_reminderType == ReminderType.customAudio && _audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请上传音频文件')),
      );
      return;
    }

    final reminder = VoiceReminder(
      id: widget.reminder?.id,
      time: _timeController.text,
      content: _contentController.text,
      reminderType: _reminderType,
      voiceModel: _reminderType == ReminderType.aiVoice ? _voiceModel : null,
      audioFilePath: _reminderType == ReminderType.customAudio ? _audioFilePath : null,
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
    return AlertDialog(
      title: const Text('批量导入提醒'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('格式：每行一个"事项 时间"，如：'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '蜗牛 14点\n面包 15:30\n检查库存 9点半',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '蜗牛 14点\n面包 15:30',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _isImporting ? null : _importReminders,
          child: _isImporting 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('导入'),
        ),
      ],
    );
  }

  Future<void> _importReminders() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final result = await widget.provider.batchImportReminders(_textController.text);
      
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入结果'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('成功导入: ${result.imported} 个'),
              Text('失败: ${result.failed} 个'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('错误详情:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.map((error) => Text('• $error', style: const TextStyle(fontSize: 12))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    } finally {
      setState(() => _isImporting = false);
    }
  }
}