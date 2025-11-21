import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

/// 캘린더 및 일정 관리 서비스
class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'schedules'; // Firestore 컬렉션 이름

  /// 일정 생성
  Future<String> createSchedule(Schedule schedule) async {
    try {
      final docRef = await _firestore.collection(_collection).add(
        schedule.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('일정 생성 실패: $e');
    }
  }

  /// 일정 수정
  Future<void> updateSchedule(String scheduleId, Schedule schedule) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).update(
        schedule.copyWith(
          id: scheduleId,
          updatedAt: DateTime.now(),
        ).toFirestore(),
      );
    } catch (e) {
      throw Exception('일정 수정 실패: $e');
    }
  }

  /// 일정 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).delete();
    } catch (e) {
      throw Exception('일정 삭제 실패: $e');
    }
  }

  /// 사용자의 모든 일정 가져오기
  Stream<List<Schedule>> getSchedulesByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Schedule.fromFirestore(doc))
            .toList());
  }

  /// 특정 날짜 범위의 일정 가져오기
  Stream<List<Schedule>> getSchedulesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Schedule.fromFirestore(doc))
            .toList());
  }

  /// 특정 날짜의 일정 가져오기
  Future<List<Schedule>> getSchedulesByDate(
    String userId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startDate', descending: false)
        .get();

    return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
  }

  /// 마감일이 D-1인 일정 가져오기 (알림용)
  Future<List<Schedule>> getDeadlineSchedules(String userId) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfTomorrow =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('isDeadline', isEqualTo: true)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow))
        .get();

    return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
  }
}

