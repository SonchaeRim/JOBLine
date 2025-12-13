import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/certification.dart';
import '../../xp/services/xp_service.dart';
import '../../xp/models/xp_rule.dart';

/// 인증 결과 관리 서비스
class ProofService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'certifications'; // Firestore 컬렉션 이름
  final XpService _xpService = XpService();

  /// 인증 유형에 따라 XP 계산 (public 메서드로 노출)
  int calculateCertificationXp(Certification certification) {
    if (certification.certificationType == null) {
      return 0;
    }

    final type = certification.certificationType!;
    
    // otherActivity와 exhibition은 certificationDetails가 없어도 기본 XP 지급
    if (type == CertificationType.otherActivity) {
      return XpRule.otherActivityXp;
    }
    if (type == CertificationType.exhibition) {
      return XpRule.exhibitionParticipationXp;
    }
    
    // 나머지 타입은 certificationDetails가 필요
    if (certification.certificationDetails == null) {
      return 0;
    }
    
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
        return XpRule.exhibitionParticipationXp;

      case CertificationType.otherActivity:
        // 기타 활동
        return XpRule.otherActivityXp;
    }
  }

  /// 인증 결과 등록
  Future<String> createCertification(Certification certification) async {
    try {
      // XP 계산 (인증 유형에 따라)
      int calculatedXp = certification.xpEarned;
      if (calculatedXp == 0 && certification.certificationType != null) {
        calculatedXp = calculateCertificationXp(certification);
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
        reviewStatus: certification.reviewStatus,
        xpEarned: calculatedXp,
        certificationType: certification.certificationType,
        certificationDetails: certification.certificationDetails,
      );

      // 인증 결과 저장
      final docRef = await _firestore.collection(_collection).add(
        certificationWithXp.toFirestore(),
      );

      // XP 부여 (승인된 경우에만)
      if (certification.reviewStatus == ReviewStatus.approved && calculatedXp > 0) {
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
  /// [xpAmount] 관리자가 직접 지정한 XP (null이면 자동 계산)
  Future<void> approveCertification(String certificationId, {int? xpAmount}) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      // 이미 승인된 경우 스킵
      if (certification.reviewStatus == ReviewStatus.approved) {
        return;
      }

      // XP 결정: 관리자가 지정한 값이 있으면 사용, 없으면 자동 계산
      int finalXp;
      if (xpAmount != null) {
        finalXp = xpAmount;
      } else {
        // 자동 계산
        finalXp = certification.xpEarned;
        if (finalXp == 0 && certification.certificationType != null) {
          finalXp = calculateCertificationXp(certification);
        }
      }

      // 승인 상태 업데이트 및 XP 부여
      await _firestore.collection(_collection).doc(certificationId).update({
        'isApproved': true,
        'reviewStatus': ReviewStatus.approved.name,
        'xpEarned': finalXp,
      });

      // XP 부여
      if (finalXp > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_approved',
          amount: finalXp,
          referenceId: certificationId,
        );
      }
    } catch (e) {
      throw Exception('인증 승인 실패: $e');
    }
  }

  /// 인증 거부 처리 (관리자가 거부할 때)
  Future<void> rejectCertification(String certificationId) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      // 이미 거부된 경우 스킵
      if (certification.reviewStatus == ReviewStatus.rejected) {
        return;
      }

      // 이미 승인되어 XP가 지급된 경우 XP 차감
      if (certification.reviewStatus == ReviewStatus.approved && certification.xpEarned > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_rejected',
          amount: -certification.xpEarned,
          referenceId: certificationId,
        );
      }

      // 거부 상태 업데이트
      await _firestore.collection(_collection).doc(certificationId).update({
        'isApproved': false,
        'reviewStatus': ReviewStatus.rejected.name,
        'xpEarned': 0,
      });
    } catch (e) {
      throw Exception('인증 거부 실패: $e');
    }
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

  /// 특정 인증 상세 정보 가져오기 (Stream)
  Stream<DocumentSnapshot> getCertificationStream(String certificationId) {
    return _firestore.collection(_collection).doc(certificationId).snapshots();
  }

  /// 검토할 항목이 있는 유저 목록 가져오기 (관리자용)
  /// 각 유저별로 pending 또는 rejected 상태의 인증 개수를 포함
  Future<List<Map<String, dynamic>>> getUsersWithPendingCertifications() async {
    try {
      // 검토 중이거나 거부된 인증들을 모두 가져오기
      final pendingSnapshot = await _firestore
          .collection(_collection)
          .where('reviewStatus', whereIn: ['pending', 'rejected'])
          .get();

      // 유저별로 그룹화하여 개수 계산
      final Map<String, int> userPendingCounts = {};
      final Set<String> userIds = {};

      for (var doc in pendingSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        if (userId != null) {
          userIds.add(userId);
          userPendingCounts[userId] = (userPendingCounts[userId] ?? 0) + 1;
        }
      }

      // 유저 정보 가져오기
      final List<Map<String, dynamic>> usersWithCounts = [];
      
      for (var userId in userIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            usersWithCounts.add({
              'userId': userId,
              'nickname': userData['nickname'] ?? '사용자',
              'email': userData['email'] ?? '',
              'pendingCount': userPendingCounts[userId] ?? 0,
            });
          } else {
            // 유저 정보가 없어도 인증이 있으면 표시
            usersWithCounts.add({
              'userId': userId,
              'nickname': '사용자',
              'email': '',
              'pendingCount': userPendingCounts[userId] ?? 0,
            });
          }
        } catch (e) {
          // 유저 정보 가져오기 실패해도 계속 진행
          usersWithCounts.add({
            'userId': userId,
            'nickname': '사용자',
            'email': '',
            'pendingCount': userPendingCounts[userId] ?? 0,
          });
        }
      }

      // 검토할 항목이 많은 순으로 정렬
      usersWithCounts.sort((a, b) => (b['pendingCount'] as int).compareTo(a['pendingCount'] as int));

      return usersWithCounts;
    } catch (e) {
      throw Exception('유저 목록 가져오기 실패: $e');
    }
  }

  /// 인증 삭제
  Future<void> deleteCertification(String certificationId) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      // Storage에서 이미지 삭제
      if (certification.imageUrl != null && certification.imageUrl!.isNotEmpty) {
        try {
          // imageUrl에서 경로 추출 (예: https://firebasestorage.googleapis.com/v0/b/.../photo_proofs/...)
          final imageUrl = certification.imageUrl!;
          // URL에서 경로 부분 추출
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          
          // 'photo_proofs' 또는 'challenge_proofs' 경로 찾기
          int photoProofsIndex = -1;
          for (int i = 0; i < pathSegments.length; i++) {
            if (pathSegments[i] == 'photo_proofs' || pathSegments[i] == 'challenge_proofs') {
              photoProofsIndex = i;
              break;
            }
          }
          
          if (photoProofsIndex >= 0 && photoProofsIndex < pathSegments.length - 1) {
            // 'photo_proofs' 또는 'challenge_proofs' 이후의 경로 구성
            final storagePath = pathSegments.sublist(photoProofsIndex).join('/');
            final storageRef = FirebaseStorage.instance.ref().child(storagePath);
            await storageRef.delete();
          } else {
            // URL에서 직접 경로를 추출할 수 없는 경우, 전체 URL을 사용
            final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          }
        } catch (storageError) {
          // Storage 삭제 실패해도 계속 진행 (이미지가 이미 삭제되었을 수 있음)
          print('Storage 이미지 삭제 실패 (무시): $storageError');
        }
      }
      
      // 이미 승인되어 XP가 지급된 경우 XP 차감
      if (certification.reviewStatus == ReviewStatus.approved && certification.xpEarned > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_deleted',
          amount: -certification.xpEarned,
          referenceId: certificationId,
        );
      }

      // 인증 문서 삭제
      await _firestore.collection(_collection).doc(certificationId).delete();
    } catch (e) {
      throw Exception('인증 삭제 실패: $e');
    }
  }

  /// 인증 수정
  Future<void> updateCertification(String certificationId, Certification certification) async {
    try {
      // XP 재계산
      int calculatedXp = certification.xpEarned;
      if (calculatedXp == 0 && certification.certificationType != null) {
        calculatedXp = calculateCertificationXp(certification);
      }

      // 기존 인증 정보 가져오기
      final oldCertDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!oldCertDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }
      final oldCert = Certification.fromFirestore(oldCertDoc);

      // 수정된 인증 객체 생성
      final updatedCert = Certification(
        id: certificationId,
        challengeId: certification.challengeId,
        userId: certification.userId,
        imageUrl: certification.imageUrl,
        description: certification.description,
        proofDate: certification.proofDate,
        createdAt: oldCert.createdAt, // 생성일은 유지
        isApproved: certification.isApproved,
        reviewStatus: ReviewStatus.pending, // 수정 시 다시 검토 중 상태로
        xpEarned: calculatedXp,
        certificationType: certification.certificationType,
        certificationDetails: certification.certificationDetails,
      );

      // 기존에 승인되어 XP가 지급된 경우 XP 차감
      if (oldCert.reviewStatus == ReviewStatus.approved && oldCert.xpEarned > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_updated',
          amount: -oldCert.xpEarned,
          referenceId: certificationId,
        );
      }

      // 인증 정보 업데이트
      await _firestore.collection(_collection).doc(certificationId).update(
        updatedCert.toFirestore(),
      );

      // 수정 후 다시 승인되면 XP 부여 (승인 시점에 처리)
    } catch (e) {
      throw Exception('인증 수정 실패: $e');
    }
  }

}