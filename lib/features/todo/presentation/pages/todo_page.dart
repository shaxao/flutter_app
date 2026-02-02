import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 待办事项页面
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // 模拟待办数据
  final List<Map<String, dynamic>> _todos = [
    {
      'id': '1',
      'title': '完成项目报告',
      'description': '整理本月工作总结和下月计划',
      'priority': 'high',
      'completed': false,
      'dueDate': DateTime.now().add(const Duration(days: 1)),
      'tags': ['工作', '重要'],
    },
    {
      'id': '2',
      'title': '回复客户邮件',
      'description': '处理今日收到的客户咨询邮件',
      'priority': 'medium',
      'completed': false,
      'dueDate': DateTime.now().add(const Duration(hours: 4)),
      'tags': ['工作'],
    },
    {
      'id': '3',
      'title': '买菜做饭',
      'description': '去超市买菜，准备晚餐',
      'priority': 'low',
      'completed': true,
      'dueDate': DateTime.now().subtract(const Duration(hours: 2)),
      'tags': ['生活'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildTodoList()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        '待办事项',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: 语音添加待办
          },
          icon: const Icon(Icons.mic_rounded),
          tooltip: '语音添加',
        ),
        IconButton(
          onPressed: () {
            // TODO: 设置
          },
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final pendingCount = _todos.where((todo) => !todo['completed']).length;
    final completedCount = _todos.where((todo) => todo['completed']).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
              Icons.checklist_rounded,
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
                  '我的待办',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingCount 个待完成 • $completedCount 个已完成',
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

  Widget _buildTodoList() {
    final pendingTodos = _todos.where((todo) => !todo['completed']).toList();
    final completedTodos = _todos.where((todo) => todo['completed']).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingTodos.isNotEmpty) ...[
            Text(
              '待完成 (${pendingTodos.length})',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            ...pendingTodos.map((todo) => _buildTodoItem(todo)),
          ],
          
          if (completedTodos.isNotEmpty) ...[
            if (pendingTodos.isNotEmpty) const SizedBox(height: 24),
            Text(
              '已完成 (${completedTodos.length})',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            ...completedTodos.map((todo) => _buildTodoItem(todo)),
          ],
        ],
      ),
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> todo) {
    final completed = todo['completed'] as bool;
    final priority = todo['priority'] as String;
    final title = todo['title'] as String;
    final description = todo['description'] as String?;
    final tags = List<String>.from(todo['tags'] ?? []);
    final dueDate = todo['dueDate'] as DateTime?;

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = const Color(0xFFEF4444);
        break;
      case 'medium':
        priorityColor = const Color(0xFFF59E0B);
        break;
      case 'low':
        priorityColor = const Color(0xFF10B981);
        break;
      default:
        priorityColor = const Color(0xFF94A3B8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? const Color(0xFFE2E8F0) : priorityColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 完成状态
          GestureDetector(
            onTap: () => _toggleTodo(todo['id']),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? priorityColor : Colors.transparent,
                border: Border.all(
                  color: priorityColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: completed
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: completed ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: completed ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ],
                if (dueDate != null || tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (dueDate != null) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: completed ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(dueDate),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: completed ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                      if (dueDate != null && tags.isNotEmpty) const SizedBox(width: 12),
                      ...tags.map((tag) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: completed 
                              ? const Color(0xFFE2E8F0) 
                              : priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: completed ? const Color(0xFF94A3B8) : priorityColor,
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // 操作按钮
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editTodo(todo);
                  break;
                case 'delete':
                  _deleteTodo(todo['id']);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert_rounded,
              color: completed ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _addTodo,
      backgroundColor: const Color(0xFF10B981),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天后';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时后';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟后';
    } else if (difference.inSeconds > 0) {
      return '即将到期';
    } else {
      return '已过期';
    }
  }

  void _toggleTodo(String id) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo['id'] == id);
      if (index != -1) {
        _todos[index]['completed'] = !_todos[index]['completed'];
      }
    });
  }

  void _addTodo() {
    showDialog(
      context: context,
      builder: (context) => _TodoDialog(),
    );
  }

  void _editTodo(Map<String, dynamic> todo) {
    showDialog(
      context: context,
      builder: (context) => _TodoDialog(todo: todo),
    );
  }

  void _deleteTodo(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办'),
        content: const Text('确定要删除这个待办事项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _todos.removeWhere((todo) => todo['id'] == id);
              });
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TodoDialog extends StatefulWidget {
  final Map<String, dynamic>? todo;
  
  const _TodoDialog({this.todo});

  @override
  State<_TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<_TodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'medium';
  DateTime? _selectedDate;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!['title'] ?? '';
      _descriptionController.text = widget.todo!['description'] ?? '';
      _selectedPriority = widget.todo!['priority'] ?? 'medium';
      _selectedDate = widget.todo!['dueDate'];
      _tags.addAll(List<String>.from(widget.todo!['tags'] ?? []));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              widget.todo != null ? '编辑待办' : '添加待办',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '待办标题',
                hintText: '输入待办事项标题',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 描述输入
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '详细描述 (可选)',
                hintText: '输入详细描述',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 优先级选择
            Text(
              '优先级',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityChip('low', '低', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildPriorityChip('medium', '中', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildPriorityChip('high', '高', const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 16),
            
            // 截止日期
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '截止日期: ${_selectedDate!.month}/${_selectedDate!.day}'
                        : '未设置截止日期',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text('选择日期'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 标签
            Text(
              '标签',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  deleteIconColor: const Color(0xFF6B7280),
                )),
                ActionChip(
                  label: const Text('+ 添加标签'),
                  onPressed: _addTag,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.todo != null ? '保存' : '添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(
            hintText: '输入标签名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_tagController.text.isNotEmpty) {
                setState(() => _tags.add(_tagController.text));
                _tagController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _saveTodo() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入待办标题')),
      );
      return;
    }

    // TODO: 保存到数据库
    final todoData = {
      'id': widget.todo?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _titleController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'priority': _selectedPriority,
      'completed': widget.todo?['completed'] ?? false,
      'dueDate': _selectedDate,
      'tags': _tags,
      'createdAt': widget.todo?['createdAt'] ?? DateTime.now(),
    };

    Navigator.pop(context, todoData);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.todo != null ? '待办已更新' : '待办已添加'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
}