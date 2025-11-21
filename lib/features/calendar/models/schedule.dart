import 'package:cloud_firestore/cloud_firestore.dart';

/// 일정 데이터 모델
class Schedule {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String ownerId; // 일정 소유자 사용자 ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeadline; // 마감일 여부 (D-1 알림용)
  final String? category; // 일정 카테고리 (예: "면접", "서류제출", "시험" 등)

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
  });

  /// Firestore DocumentSnapshot에서 Schedule 객체 생성
  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String?,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      ownerId: data['ownerId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isDeadline: data['isDeadline'] as bool? ?? false,
      category: data['category'] as String?,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeadline': isDeadline,
      'category': category,
    };
  }

  /// Schedule 객체 복사 (수정 시 사용)
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
    );
  }
}

