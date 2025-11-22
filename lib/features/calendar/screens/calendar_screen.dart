import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/calendar_service.dart';
import 'schedule_detail_screen.dart';
import '../../../core/theme/app_colors.dart';

/// 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  String? _currentUserId; // TODO: 실제 사용자 ID로 교체 (B 담당과 협업)
  final String _filter = '모든 공고'; // 필터 옵션

  @override
  void initState() {
    super.initState();
    // TODO: 실제 사용자 인증 연동 (B 담당과 협업)
    _currentUserId = 'test_user_12345'; // 테스트용
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('캘린더'),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddScheduleScreen(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 및 달력 헤더
          _buildHeader(),
          // 달력 그리드
          _buildCalendarGrid(),
          const Divider(height: 1),
          // 선택된 날짜의 일정 리스트
          Expanded(
            child: _buildScheduleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 캘린더 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'JL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 필터 옵션
          Expanded(
            child: InkWell(
              onTap: () {
                // TODO: 필터 선택 다이얼로그
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('필터 기능은 준비 중입니다.')),
                );
              },
              child: Row(
                children: [
                  Text(
                    _filter,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_up, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; // 일요일 = 0
    final daysInMonth = lastDayOfMonth.day;
    
    // 이전 달의 마지막 날들
    final prevMonthLastDay = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    final prevMonthDays = <int>[];
    for (int i = firstDayOfWeek - 1; i >= 0; i--) {
      prevMonthDays.add(prevMonthLastDay - i);
    }
    
    // 다음 달의 첫 날들
    final nextMonthDays = <int>[];
    final totalCells = firstDayOfWeek + daysInMonth;
    final remainingCells = 42 - totalCells; // 6주 * 7일
    for (int i = 1; i <= remainingCells; i++) {
      nextMonthDays.add(i);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 월 선택 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_currentMonth.month}월',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      // TODO: 월 선택 다이얼로그
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month - 1,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: day == '일'
                          ? Colors.red
                          : day == '토'
                              ? Colors.blue
                              : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 달력 그리드
          ...List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final cellIndex = weekIndex * 7 + dayIndex;
                final isPrevMonth = cellIndex < firstDayOfWeek;
                final isNextMonth = cellIndex >= firstDayOfWeek + daysInMonth;
                
                int day;
                DateTime cellDate;
                if (isPrevMonth) {
                  day = prevMonthDays[dayIndex];
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month - 1, day);
                } else if (isNextMonth) {
                  day = nextMonthDays[cellIndex - (firstDayOfWeek + daysInMonth)];
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month + 1, day);
                } else {
                  day = cellIndex - firstDayOfWeek + 1;
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                }
                
                final isSelected = _isSameDay(cellDate, _selectedDate);
                final isSunday = dayIndex == 0;
                final isSaturday = dayIndex == 6;
                
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = cellDate;
                      });
                    },
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.grey.shade300
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isPrevMonth || isNextMonth
                                ? Colors.grey.shade400
                                : isSunday
                                    ? Colors.red
                                    : isSaturday
                                        ? Colors.blue
                                        : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildScheduleList() {
    return StreamBuilder<List<Schedule>>(
      stream: _calendarService.getSchedulesByUser(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('오류: ${snapshot.error}'),
          );
        }

        final schedules = snapshot.data ?? [];
        final selectedDateSchedules = schedules.where((schedule) {
          return _isSameDay(schedule.startDate, _selectedDate);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택된 날짜 표시
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_selectedDate.day}일',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            // 일정 리스트
            Expanded(
              child: selectedDateSchedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '이 날짜에는 일정이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedDateSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = selectedDateSchedules[index];
                        return _buildScheduleItem(schedule);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    final daysUntil = _selectedDate.difference(schedule.startDate).inDays;
    String deadlineText = '';
    Color deadlineColor = Colors.red;

    if (daysUntil < 0) {
      deadlineText = 'D$daysUntil';
    } else if (daysUntil == 0) {
      deadlineText = 'D-DAY';
    } else {
      deadlineText = 'D+$daysUntil';
      deadlineColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: Text(
          schedule.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: deadlineColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            deadlineText,
            style: TextStyle(
              fontSize: 12,
              color: deadlineColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showScheduleDetail(schedule),
      ),
    );
  }

  void _showAddScheduleScreen() {
    Navigator.pushNamed(
      context,
      '/schedule-detail',
      arguments: {
        'userId': _currentUserId!,
        'calendarService': _calendarService,
        'schedule': null,
        'selectedDate': _selectedDate,
      },
    );
  }

  void _showScheduleDetail(Schedule schedule) {
    Navigator.pushNamed(
      context,
      '/schedule-detail',
      arguments: {
        'userId': _currentUserId!,
        'calendarService': _calendarService,
        'schedule': schedule,
        'selectedDate': null,
      },
    );
  }
}
