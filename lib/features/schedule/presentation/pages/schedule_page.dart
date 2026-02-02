import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

/// 排班页面 - 日历视图 + 班次管理
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 模拟数据
  final Map<DateTime, List<Map<String, dynamic>>> _schedules = {
    DateTime(2026, 2, 1): [
      {'type': '早班', 'time': '08:00-16:00', 'status': 'confirmed'},
    ],
    DateTime(2026, 2, 2): [
      {'type': '晚班', 'time': '16:00-24:00', 'status': 'pending'},
    ],
    DateTime(2026, 2, 3): [
      {'type': '休息', 'time': '全天', 'status': 'confirmed'},
    ],
  };
  
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(child: _buildScheduleList()),
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
        '排班管理',
        style: GoogleFonts.karla(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: 导出排班
          },
          icon: const Icon(Icons.file_download),
        ),
        IconButton(
          onPressed: () {
            // TODO: 设置
          },
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }
  
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getSchedulesForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        // 样式配置
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: GoogleFonts.karla(color: const Color(0xFF475569)),
          holidayTextStyle: GoogleFonts.karla(color: const Color(0xFFEF4444)),
          
          // 选中日期样式
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.karla(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          
          // 今天样式
          todayDecoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: GoogleFonts.karla(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          
          // 事件标记
          markerDecoration: const BoxDecoration(
            color: Color(0xFFF97316),
            shape: BoxShape.circle,
          ),
        ),
        
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.karla(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF3B82F6),
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: Color(0xFF3B82F6),
          ),
        ),
        
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.karla(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
          weekendStyle: GoogleFonts.karla(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }
  
  Widget _buildScheduleList() {
    final selectedSchedules = _getSchedulesForDay(_selectedDay ?? DateTime.now());
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Text(
                '${_selectedDay?.month}月${_selectedDay?.day}日 排班',
                style: GoogleFonts.karla(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (selectedSchedules.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selectedSchedules.length} 个班次',
                    style: GoogleFonts.karla(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (selectedSchedules.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                itemCount: selectedSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = selectedSchedules[index];
                  return _buildScheduleItem(schedule);
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无排班',
            style: GoogleFonts.karla(
              fontSize: 16,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加班次',
            style: GoogleFonts.karla(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final type = schedule['type'] as String;
    final time = schedule['time'] as String;
    final status = schedule['status'] as String;
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'confirmed':
        statusColor = const Color(0xFF10B981);
        statusText = '已确认';
        break;
      case 'pending':
        statusColor = const Color(0xFFFBBF24);
        statusText = '待确认';
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusText = '未知';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: GoogleFonts.karla(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.karla(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.karla(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editSchedule(schedule);
                  break;
                case 'delete':
                  _deleteSchedule(schedule);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: const Icon(
              Icons.more_vert,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _addSchedule,
      backgroundColor: const Color(0xFFF97316),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
  
  List<Map<String, dynamic>> _getSchedulesForDay(DateTime day) {
    return _schedules[DateTime(day.year, day.month, day.day)] ?? [];
  }
  
  void _addSchedule() {
    // TODO: 显示添加排班对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加排班'),
        content: Text('添加排班功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _editSchedule(Map<String, dynamic> schedule) {
    // TODO: 编辑排班
    print('编辑排班: $schedule');
  }
  
  void _deleteSchedule(Map<String, dynamic> schedule) {
    // TODO: 删除排班
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除排班'),
        content: Text('确定要删除这个班次吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 执行删除
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}