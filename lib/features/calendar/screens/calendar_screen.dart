import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/calendar_service.dart';
import '../services/fcm_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';

/// 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  final FcmNotificationService _notificationService = FcmNotificationService();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  String? _currentUserId; // TODO: 실제 사용자 ID로 교체 (B 담당과 협업)
  String? _selectedCategory; // 선택된 카테고리 필터 (null이면 모든 일정)

  final List<String> _categories = [
    '면접',
    '시험',
    '서류제출',
    '프로젝트',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    // TODO: 실제 사용자 인증 연동 (B 담당과 협업)
    _currentUserId = 'test_user_12345'; // 테스트용
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      // MainScreen에서 이미 Scaffold를 제공하므로 body만 반환
      return const Center(
        child: Text('로그인이 필요합니다.'),
      );
    }

    // MainScreen에서 이미 Scaffold와 AppBar를 제공하므로 body만 반환
    // actions는 MainScreen에서 처리하거나 FloatingActionButton으로 대체 가능
    return Column(
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
              onTap: _showFilterDialog,
              child: Row(
                children: [
                  Text(
                    _selectedCategory ?? '모든 일정',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          // 일정 추가 버튼
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '일정 추가',
            onPressed: _showAddScheduleScreen,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
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
                          // 일정이 있는 날짜에 닷 표시 (필터 적용)
                          if (!isPrevMonth && !isNextMonth)
                            StreamBuilder<List<Schedule>>(
                              stream: _calendarService.getSchedulesByUser(_currentUserId!),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final schedules = snapshot.data!;
                                  // 필터 적용: 선택된 카테고리와 일치하는 일정만 확인
                                  final filteredSchedules = _selectedCategory == null
                                      ? schedules
                                      : schedules.where((schedule) {
                                          return schedule.category == _selectedCategory;
                                        }).toList();
                                  
                                  final hasSchedule = filteredSchedules.any((schedule) {
                                    return _isSameDay(schedule.startDate, cellDate);
                                  });
                                  if (hasSchedule) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
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

  String _getWeekday(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[date.weekday % 7];
  }

  /// 필터 다이얼로그 표시
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 필터'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 모든 일정 옵션
            ListTile(
              title: const Text('모든 일정'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            // 카테고리 옵션들
            ..._categories.map((category) {
              return ListTile(
                title: Text(category),
                leading: Radio<String?>(
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
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
        var selectedDateSchedules = schedules.where((schedule) {
          return _isSameDay(schedule.startDate, _selectedDate);
        }).toList();
        
        // 카테고리 필터 적용
        if (_selectedCategory != null) {
          selectedDateSchedules = selectedDateSchedules.where((schedule) {
            return schedule.category == _selectedCategory;
          }).toList();
        }
        
        // 알림 켜진 일정을 상단에 정렬
        selectedDateSchedules.sort((a, b) {
          if (a.hasNotification && !b.hasNotification) return -1;
          if (!a.hasNotification && b.hasNotification) return 1;
          return 0;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택된 날짜 및 요일 표시
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_selectedDate.day}일',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getWeekday(_selectedDate),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate.weekday == 7
                          ? Colors.red
                          : _selectedDate.weekday == 6
                              ? Colors.blue
                              : Colors.black87,
                    ),
                  ),
                ],
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
    // 오늘 날짜 기준으로 D-Day 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    final daysUntil = scheduleDate.difference(today).inDays;
    
    String deadlineText = '';
    Color deadlineColor = Colors.red;

    if (daysUntil < 0) {
      // 이미 지난 일정
      deadlineText = 'D+${-daysUntil}';
      deadlineColor = Colors.grey;
    } else if (daysUntil == 0) {
      // 오늘인 일정
      deadlineText = 'D-DAY';
      deadlineColor = Colors.red;
    } else {
      // 남은 일정
      deadlineText = 'D-$daysUntil';
      deadlineColor = daysUntil <= 3 ? Colors.red : Colors.orange;
    }

    // 시간 포맷팅 (한글 오전/오후 형식)
    final hour = schedule.startDate.hour;
    final minute = schedule.startDate.minute;
    final period = hour >= 12 ? '오후' : '오전';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeText = '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showScheduleDetail(schedule),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 왼쪽: D-day 표시
              Container(
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
              const SizedBox(width: 12),
              // 시작 시간
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              // 작대기 구분선
              const Text(
                '|',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              // 제목 (Expanded로 남은 공간 차지)
              Expanded(
                child: Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 오른쪽 끝: 알림 토글
              IconButton(
                icon: Icon(
                  schedule.hasNotification ? Icons.notifications : Icons.notifications_off,
                  color: schedule.hasNotification ? Colors.blue : Colors.grey,
                ),
                onPressed: () => _toggleNotification(schedule),
                tooltip: schedule.hasNotification ? '알림 끄기' : '알림 켜기',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 알림 토글
  Future<void> _toggleNotification(Schedule schedule) async {
    try {
      final newNotificationState = !schedule.hasNotification;
      await _calendarService.toggleNotification(
        schedule.id,
        newNotificationState,
      );
      
      if (newNotificationState) {
        // 알림 켜기 - 일정 시간에 알림 예약 (로컬 알림)
        _scheduleNotification(schedule);
      } else {
        // 알림 끄기 - 예약된 알림 취소
        _cancelNotification(schedule.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 설정 변경 실패: $e')),
        );
      }
    }
  }

  /// 알림 예약 (로컬 알림)
  Future<void> _scheduleNotification(Schedule schedule) async {
    try {
      await _notificationService.scheduleScheduleNotification(schedule);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 예약 실패: $e')),
        );
      }
    }
  }

  /// 알림 취소
  Future<void> _cancelNotification(String scheduleId) async {
    try {
      await _notificationService.cancelScheduleNotification(scheduleId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 취소 실패: $e')),
        );
      }
    }
  }

  void _showAddScheduleScreen() {
    Navigator.pushNamed(
      context,
      RouteNames.scheduleDetail,
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
      RouteNames.scheduleDetail,
      arguments: {
        'userId': _currentUserId!,
        'calendarService': _calendarService,
        'schedule': schedule,
        'selectedDate': null,
      },
    );
  }
}
