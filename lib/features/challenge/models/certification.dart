import 'package:cloud_firestore/cloud_firestore.dart';

/// 인증 유형
enum CertificationType {
  license, // 자격증
  publicServiceExam, // 공무원 시험
  languageExam, // 외국어 시험
  contest, // 공모전·대회
  exhibition, // 전시회·공연
  otherActivity, // 기타 활동
}

/// 검토 상태
enum ReviewStatus {
  pending, // 검토 중
  approved, // 인증 완료
  rejected, // 인증 실패
}

/// 인증 결과 데이터 모델 (certification)
class Certification {
  final String id;
  final String challengeId; // 인증 고유 ID
  final String userId; // 인증한 사용자 ID
  final String? imageUrl; // 인증 이미지 URL (나중에 Storage 연동)
  final String? description; // 인증 설명/텍스트 (자격증 이름 등)
  final DateTime proofDate; // 인증 날짜
  final DateTime createdAt;
  final bool isApproved; // 승인 여부 (관리자 승인 또는 자동 승인) - 하위 호환성 유지
  final ReviewStatus reviewStatus; // 검토 상태
  final int xpEarned; // 이 인증으로 획득한 XP
  
  // 인증 유형 및 상세 정보 (XP 계산에 사용)
  final CertificationType? certificationType; // 인증 유형
  final Map<String, dynamic>? certificationDetails; // 인증 상세 정보 (자격증 종류, 등급, 시험 점수 등)

  Certification({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.imageUrl,
    this.description,
    required this.proofDate,
    required this.createdAt,
    this.isApproved = true, // 기본값은 자동 승인 - 하위 호환성 유지
    this.reviewStatus = ReviewStatus.pending, // 기본값은 검토 중
    this.xpEarned = 0,
    this.certificationType,
    this.certificationDetails,
  });

  /// Firestore DocumentSnapshot에서 Certification 객체 생성
  factory Certification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    CertificationType? type;
    if (data['certificationType'] != null) {
      type = CertificationType.values.firstWhere(
        (e) => e.name == data['certificationType'],
        orElse: () => CertificationType.otherActivity,
      );
    }
    
    ReviewStatus reviewStatus = ReviewStatus.pending;
    if (data['reviewStatus'] != null) {
      reviewStatus = ReviewStatus.values.firstWhere(
        (e) => e.name == data['reviewStatus'],
        orElse: () => ReviewStatus.pending,
      );
    } else if (data['isApproved'] != null) {
      // 하위 호환성: isApproved로부터 reviewStatus 추론
      reviewStatus = (data['isApproved'] as bool)
          ? ReviewStatus.approved
          : ReviewStatus.pending;
    }
    
    return Certification(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String?,
      proofDate: (data['proofDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isApproved: data['isApproved'] as bool? ?? true,
      reviewStatus: reviewStatus,
      xpEarned: data['xpEarned'] as int? ?? 0,
      certificationType: type,
      certificationDetails: data['certificationDetails'] as Map<String, dynamic>?,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'imageUrl': imageUrl,
      'description': description,
      'proofDate': Timestamp.fromDate(proofDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isApproved': isApproved,
      'reviewStatus': reviewStatus.name,
      'xpEarned': xpEarned,
      'certificationType': certificationType?.name,
      'certificationDetails': certificationDetails,
    };
  }
}

