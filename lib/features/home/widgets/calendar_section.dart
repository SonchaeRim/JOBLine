import 'package:flutter/material.dart';
import '../../calendar/models/schedule.dart';
import '../../calendar/services/calendar_service.dart';
import 'schedule_card.dart';

/// 캘린더 섹션 위젯 (다가오는 일정 표시)
class CalendarSection extends StatelessWidget {
  final String userId;
  final ValueChanged<int>? onTabChanged;

  const CalendarSection({
    super.key,
    required this.userId,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final CalendarService calendarService = CalendarService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '캘린더',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 캘린더 탭으로 이동
                  onTabChanged?.call(1);
                },
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Schedule>>(
            stream: calendarService.getSchedulesByUser(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      '일정을 불러올 수 없습니다.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              final schedules = snapshot.data ?? [];
              final now = DateTime.now();
              
              // 오늘 이후의 일정만 필터링하고 최대 10개까지
              final upcomingSchedules = schedules
                  .where((schedule) {
                    final scheduleDate = schedule.startDate.toLocal();
                    final scheduleDateOnly = DateTime(
                      scheduleDate.year,
                      scheduleDate.month,
                      scheduleDate.day,
                    );
                    final todayOnly = DateTime(now.year, now.month, now.day);
                    return scheduleDateOnly.isAfter(todayOnly) ||
                        scheduleDateOnly.isAtSameMomentAs(todayOnly);
                  })
                  .take(10)
                  .toList();

              if (upcomingSchedules.isEmpty) {
                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      '다가오는 일정이 없습니다.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = upcomingSchedules[index];
                    return ScheduleCard(schedule: schedule);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

