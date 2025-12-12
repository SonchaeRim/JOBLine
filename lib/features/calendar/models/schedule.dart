import 'package:cloud_firestore/cloud_firestore.dart';

/// 일정 데이터 모델
class Schedule {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;      // 항상 로컬(Asia/Seoul) 기준
  final DateTime? endDate;       // 항상 로컬
  final String ownerId;
  final DateTime createdAt;      // 항상 로컬
  final DateTime updatedAt;      // 항상 로컬
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
  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final createdAtTs = data['createdAt'] as Timestamp?;
    final updatedAtTs = data['updatedAt'] as Timestamp?;
    final startDateTs = data['startDate'] as Timestamp?;
    final endDateTs   = data['endDate']   as Timestamp?;

    final now = DateTime.now();

    // Firestore Timestamp.toDate()는 보통 UTC DateTime을 반환하니까
    // 앱 안에서는 무조건 .toLocal() 해서 로컬 시간으로만 들고 다닌다.
    DateTime _toLocal(Timestamp? ts) {
      if (ts == null) return now;
      final d = ts.toDate();
      return d.isUtc ? d.toLocal() : d;
    }

    final startDateLocal   = startDateTs != null ? _toLocal(startDateTs) : now;
    final endDateLocal     = endDateTs   != null ? _toLocal(endDateTs)   : null;
    final createdAtLocal   = createdAtTs != null ? _toLocal(createdAtTs) : now;
    final updatedAtLocal   = updatedAtTs != null ? _toLocal(updatedAtTs) : now;

    return Schedule(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      startDate: startDateLocal,
      endDate: endDateLocal,
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: createdAtLocal,
      updatedAt: updatedAtLocal,
      isDeadline: data['isDeadline'] as bool? ?? false,
      category: data['category'] as String?,
      hasNotification: data['hasNotification'] as bool? ?? false,
    );
  }

  /// Schedule → Firestore
  Map<String, dynamic> toFirestore() {
    // 👉 규칙: 모델 안의 DateTime은 항상 “로컬 시간”이라고 가정하고
    // 저장할 땐 그냥 .toLocal()만 한 번 호출해서 넘긴다.
    // (local → toLocal()은 변화 없음, utc → local은 한 번만 보정)

    final startLocal   = startDate.toLocal();
    final endLocal     = endDate?.toLocal();
    final createdLocal = createdAt.toLocal();
    final updatedLocal = updatedAt.toLocal();

    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startLocal),
      'endDate': endLocal != null ? Timestamp.fromDate(endLocal) : null,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdLocal),
      'updatedAt': Timestamp.fromDate(updatedLocal),
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
