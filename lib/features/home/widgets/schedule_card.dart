import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../calendar/models/schedule.dart';
import '../../../core/theme/app_colors.dart';

/// 일정 카드 위젯
class ScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const ScheduleCard({
    super.key,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleDate = schedule.startDate.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDay = DateTime(
      scheduleDate.year,
      scheduleDate.month,
      scheduleDate.day,
    );
    final daysLeft = scheduleDay.difference(today).inDays;

    // 날짜 포맷: M.dd
    final dateFormat = DateFormat('M.dd', 'ko_KR');
    final formattedDate = dateFormat.format(scheduleDate);
    
    // 시간 포맷: a h:mm (AM/PM h:mm)
    final timeFormat = DateFormat('a h:mm', 'ko_KR');
    final formattedTime = timeFormat.format(scheduleDate);
    
    // D-Day 표시 텍스트
    final dayText = daysLeft == 0 ? 'D-Day' : 'D-$daysLeft';

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.category ?? '일정',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dayText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: daysLeft <= 7 ? Colors.red : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

