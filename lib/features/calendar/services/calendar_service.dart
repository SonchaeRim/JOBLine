/// 캘린더 및 일정 관리 서비스 - 일정 CRUD 및 날짜별 조회
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스
  final String _collection = 'schedules'; // 일정 컬렉션 이름

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
          updatedAt: DateTime.now().toUtc(),
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

  /// 특정 날짜 범위의 일정 조회
  Stream<List<Schedule>> getSchedulesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final startDateUtc = startDate.isUtc ? startDate : startDate.toUtc();
    final endDateUtc = endDate.isUtc ? endDate : endDate.toUtc();
    
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDateUtc))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDateUtc))
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Schedule.fromFirestore(doc))
            .toList());
  }

  /// 특정 날짜의 일정 조회
  Future<List<Schedule>> getSchedulesByDate(
    String userId,
    DateTime date,
  ) async {
    final startOfDayLocal = DateTime(date.year, date.month, date.day);
    final endOfDayLocal = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final startOfDayUtc = startOfDayLocal.toUtc();
    final endOfDayUtc = endOfDayLocal.toUtc();

    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDayUtc))
        .orderBy('startDate', descending: false)
        .get();

    return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
  }

  /// D-1 마감일 일정 조회 (알림용)
  Future<List<Schedule>> getDeadlineSchedules(String userId) async {
    final tomorrowLocal = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrowLocal = DateTime(tomorrowLocal.year, tomorrowLocal.month, tomorrowLocal.day);
    final endOfTomorrowLocal =
        DateTime(tomorrowLocal.year, tomorrowLocal.month, tomorrowLocal.day, 23, 59, 59);
    final startOfTomorrowUtc = startOfTomorrowLocal.toUtc();
    final endOfTomorrowUtc = endOfTomorrowLocal.toUtc();

    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('isDeadline', isEqualTo: true)
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrowUtc))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrowUtc))
        .get();

    return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
  }

  /// 일정 알림 토글
  Future<void> toggleNotification(String scheduleId, bool hasNotification) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).update({
        'hasNotification': hasNotification,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('알림 설정 변경 실패: $e');
    }
  }
}

