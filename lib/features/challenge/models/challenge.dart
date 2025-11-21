import 'package:cloud_firestore/cloud_firestore.dart';

/// 챌린지 데이터 모델
class Challenge {
  final String id;
  final String title;
  final String description;
  final String? imageUrl; // 챌린지 대표 이미지
  final int durationDays; // 챌린지 기간 (일)
  final int targetCount; // 목표 인증 횟수
  final int xpReward; // 완료 시 보상 XP
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final bool isActive; // 활성화 여부
  final String? category; // 챌린지 카테고리

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.durationDays,
    required this.targetCount,
    required this.xpReward,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.isActive = true,
    this.category,
  });

  /// Firestore DocumentSnapshot에서 Challenge 객체 생성
  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String?,
      durationDays: data['durationDays'] as int,
      targetCount: data['targetCount'] as int,
      xpReward: data['xpReward'] as int,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      category: data['category'] as String?,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'durationDays': durationDays,
      'targetCount': targetCount,
      'xpReward': xpReward,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'category': category,
    };
  }

  /// 챌린지가 현재 진행 중인지 확인
  bool get isOngoing {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}

