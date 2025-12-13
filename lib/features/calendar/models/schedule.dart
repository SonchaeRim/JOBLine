import 'package:cloud_firestore/cloud_firestore.dart';

/// 일정 데이터 모델
/// 
/// 모든 DateTime은 UTC로 저장하고, 표시할 때만 로컬 시간으로 변환합니다.
class Schedule {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;      // UTC 기준으로 저장
  final DateTime? endDate;       // UTC 기준으로 저장
  final String ownerId;
  final DateTime createdAt;      // UTC 기준으로 저장
  final DateTime updatedAt;      // UTC 기준으로 저장
  final bool isDeadline;
  final String? category;
  final bool hasNotification;

  Schedule({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeadline = false,
    this.category,
    this.hasNotification = false,
  });

  /// Firestore → Schedule
  /// Firestore의 Timestamp는 UTC로 저장되어 있으므로 UTC DateTime으로 변환
  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final createdAtTs = data['createdAt'] as Timestamp?;
    final updatedAtTs = data['updatedAt'] as Timestamp?;
    final startDateTs = data['startDate'] as Timestamp?;
    final endDateTs   = data['endDate']   as Timestamp?;

    final now = DateTime.now().toUtc();

    // Firestore Timestamp.toDate()는 UTC DateTime을 반환
    // UTC로 유지 (표시할 때만 로컬로 변환)
    DateTime _toUtc(Timestamp? ts) {
      if (ts == null) return now;
      final d = ts.toDate();
      return d.isUtc ? d : d.toUtc();
    }

    final startDateUtc   = startDateTs != null ? _toUtc(startDateTs) : now;
    final endDateUtc     = endDateTs   != null ? _toUtc(endDateTs)   : null;
    final createdAtUtc   = createdAtTs != null ? _toUtc(createdAtTs) : now;
    final updatedAtUtc   = updatedAtTs != null ? _toUtc(updatedAtTs) : now;

    return Schedule(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      startDate: startDateUtc,
      endDate: endDateUtc,
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: createdAtUtc,
      updatedAt: updatedAtUtc,
      isDeadline: data['isDeadline'] as bool? ?? false,
      category: data['category'] as String?,
      hasNotification: data['hasNotification'] as bool? ?? false,
    );
  }

  /// Schedule → Firestore
  /// 모델 내부의 DateTime은 UTC이므로 그대로 저장
  /// Timestamp.fromDate()는 UTC DateTime을 UTC Timestamp로 변환
  Map<String, dynamic> toFirestore() {
    // DateTime을 명시적으로 UTC로 변환하여 저장
    // (이미 UTC여도 안전하게 변환)
    final startUtc   = startDate.isUtc ? startDate : startDate.toUtc();
    final endUtc     = endDate != null ? (endDate!.isUtc ? endDate! : endDate!.toUtc()) : null;
    final createdUtc = createdAt.isUtc ? createdAt : createdAt.toUtc();
    final updatedUtc = updatedAt.isUtc ? updatedAt : updatedAt.toUtc();

    // Timestamp.fromDate()는 UTC DateTime을 UTC Timestamp로 변환
    // Firestore에 저장될 때는 항상 UTC로 저장됨
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startUtc),
      'endDate': endUtc != null ? Timestamp.fromDate(endUtc) : null,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdUtc),
      'updatedAt': Timestamp.fromDate(updatedUtc),
      'isDeadline': isDeadline,
      'category': category,
      'hasNotification': hasNotification,
    };
  }

  Schedule copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeadline,
    String? category,
    bool? hasNotification,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeadline: isDeadline ?? this.isDeadline,
      category: category ?? this.category,
      hasNotification: hasNotification ?? this.hasNotification,
    );
  }
}
