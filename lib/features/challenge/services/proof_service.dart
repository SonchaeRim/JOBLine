import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification.dart';
import '../../xp/services/xp_service.dart';
import '../../xp/models/xp_rule.dart';

/// 인증 결과 관리 서비스
class ProofService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'certifications'; // Firestore 컬렉션 이름
  final XpService _xpService = XpService();

  /// 인증 유형에 따라 XP 계산
  int _calculateCertificationXp(Certification certification) {
    if (certification.certificationType == null || 
        certification.certificationDetails == null) {
      return 0;
    }

    final type = certification.certificationType!;
    final details = certification.certificationDetails!;

    switch (type) {
      case CertificationType.license:
        // 자격증
        final licenseType = details['licenseType'] as String?; // 'national', 'national_professional', 'private'
        if (licenseType == 'national') {
          final category = details['category'] as String?; // 'technical' or 'service'
          final grade = details['grade'] as String?;
          return XpRule.getNationalLicenseXp(category ?? '', grade ?? '');
        } else if (licenseType == 'national_professional') {
          final grade = details['grade'] as String?;
          return XpRule.getNationalProfessionalLicenseXp(grade ?? '');
        } else if (licenseType == 'private') {
          final privateType = details['privateType'] as String?; // 'national_approved' or 'registered'
          final grade = details['grade'] as String?;
          return XpRule.getPrivateLicenseXp(privateType ?? '', grade ?? '');
        }
        return 0;

      case CertificationType.publicServiceExam:
        // 공무원 시험
        final examType = details['examType'] as String?;
        return XpRule.getPublicServiceExamXp(examType ?? '');

      case CertificationType.languageExam:
        // 외국어 시험
        final examType = details['examType'] as String?;
        final score = details['score'] ?? details['grade'];
        
        if (examType == '한국사') {
          final grade = score?.toString() ?? '';
          return XpRule.getKoreanHistoryExamXp(grade);
        } else if (examType == 'TOEIC' || 
                   examType == 'TOEIC_Speaking' || 
                   examType == 'TOEFL' || 
                   examType == 'OPIC' || 
                   examType == 'TEPS' || 
                   examType == 'IELTS') {
          return XpRule.getEnglishExamXp(examType ?? '', score);
        } else {
          // 기타 외국어 시험
          final grade = score?.toString() ?? '';
          return XpRule.getOtherLanguageExamXp(examType ?? '', grade);
        }

      case CertificationType.contest:
        // 공모전·대회
        final scale = details['scale'] as String?; // 'international', 'national', 'local'
        final result = details['result'] as String?; // '대상', '입상', '입선', '참가'
        return XpRule.getContestXp(scale ?? '', result ?? '');

      case CertificationType.exhibition:
        // 전시회·공연
        return XpRule.actionXp['exhibition_participation'] ?? 10;

      case CertificationType.otherActivity:
        // 기타 활동
        return XpRule.actionXp['other_activity'] ?? 10;
    }
  }

  /// 인증 결과 등록
  Future<String> createCertification(Certification certification) async {
    try {
      // XP 계산 (인증 유형에 따라)
      int calculatedXp = certification.xpEarned;
      if (calculatedXp == 0 && certification.certificationType != null) {
        calculatedXp = _calculateCertificationXp(certification);
      }

      // 계산된 XP로 인증 객체 업데이트
      final certificationWithXp = Certification(
        id: certification.id,
        challengeId: certification.challengeId,
        userId: certification.userId,
        imageUrl: certification.imageUrl,
        description: certification.description,
        proofDate: certification.proofDate,
        createdAt: certification.createdAt,
        isApproved: certification.isApproved,
        xpEarned: calculatedXp,
        certificationType: certification.certificationType,
        certificationDetails: certification.certificationDetails,
      );

      // 인증 결과 저장
      final docRef = await _firestore.collection(_collection).add(
        certificationWithXp.toFirestore(),
      );

      // XP 부여 (승인된 경우에만)
      if (certification.isApproved && calculatedXp > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_approved',
          amount: calculatedXp,
          referenceId: docRef.id,
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('인증 등록 실패: $e');
    }
  }

  /// 인증 승인 처리 (관리자가 승인할 때)
  Future<void> approveCertification(String certificationId) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      // 이미 승인된 경우 스킵
      if (certification.isApproved) {
        return;
      }

      // XP 계산
      int calculatedXp = certification.xpEarned;
      if (calculatedXp == 0 && certification.certificationType != null) {
        calculatedXp = _calculateCertificationXp(certification);
      }

      // 승인 상태 업데이트 및 XP 부여
      await _firestore.collection(_collection).doc(certificationId).update({
        'isApproved': true,
        'xpEarned': calculatedXp,
      });

      // XP 부여
      if (calculatedXp > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_approved',
          amount: calculatedXp,
          referenceId: certificationId,
        );
      }
    } catch (e) {
      throw Exception('인증 승인 실패: $e');
    }
  }

  /// 사용자의 특정 챌린지 인증 목록 가져오기
  Stream<List<Certification>> getCertificationsByChallenge(
    String userId,
    String challengeId,
  ) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('proofDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Certification.fromFirestore(doc))
            .toList());
  }

  /// 사용자의 모든 인증 목록 가져오기
  Stream<List<Certification>> getUserCertifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('proofDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Certification.fromFirestore(doc))
            .toList());
  }

  /// 특정 챌린지의 인증 횟수 가져오기
  Future<int> getCertificationCount(String userId, String challengeId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .where('isApproved', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }

  /// 챌린지 완료 여부 확인 및 XP 보상
  Future<void> checkChallengeCompletion(
    String userId,
    String challengeId,
    int targetCount,
    int completionXp,
  ) async {
    final certCount = await getCertificationCount(userId, challengeId);

    // 목표 달성 시 완료 보상 XP 부여
    if (certCount >= targetCount) {
      // 이미 완료 보상을 받았는지 확인 (xp_logs에서 확인)
      final xpLogsSnapshot = await _firestore
          .collection('xp_logs')
          .where('userId', isEqualTo: userId)
          .where('action', isEqualTo: 'challenge_complete')
          .where('referenceId', isEqualTo: challengeId)
          .get();

      // 완료 보상을 아직 받지 않았다면 부여
      if (xpLogsSnapshot.docs.isEmpty) {
        await _xpService.addXp(
          userId: userId,
          action: 'challenge_complete',
          amount: completionXp,
          referenceId: challengeId,
        );
      }
    }
  }
}