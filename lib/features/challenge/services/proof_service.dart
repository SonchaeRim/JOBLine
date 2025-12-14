/// 인증 결과 관리 서비스 - 인증 생성, 승인, 거부, 삭제 및 XP 계산 처리
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/certification.dart';
import '../../xp/services/xp_service.dart';
import '../../xp/models/xp_rule.dart';

class ProofService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스
  final String _collection = 'certifications'; // 인증 컬렉션 이름
  final XpService _xpService = XpService(); // XP 서비스

  /// 인증 유형에 따라 XP 계산
  int calculateCertificationXp(Certification certification) {
    if (certification.certificationType == null) {
      return 0;
    }

    final type = certification.certificationType!;
    
    if (type == CertificationType.otherActivity) {
      return XpRule.otherActivityXp;
    }
    if (type == CertificationType.exhibition) {
      return XpRule.exhibitionParticipationXp;
    }
    
    if (certification.certificationDetails == null) {
      return 0;
    }
    
    final details = certification.certificationDetails!;

    switch (type) {
      case CertificationType.license:
        final licenseType = details['licenseType'] as String?;
        if (licenseType == 'national') {
          final category = details['category'] as String?;
          final grade = details['grade'] as String?;
          return XpRule.getNationalLicenseXp(category ?? '', grade ?? '');
        } else if (licenseType == 'national_professional') {
          final grade = details['grade'] as String?;
          return XpRule.getNationalProfessionalLicenseXp(grade ?? '');
        } else if (licenseType == 'private') {
          final privateType = details['privateType'] as String?;
          final grade = details['grade'] as String?;
          return XpRule.getPrivateLicenseXp(privateType ?? '', grade ?? '');
        }
        return 0;

      case CertificationType.publicServiceExam:
        final examType = details['examType'] as String?;
        return XpRule.getPublicServiceExamXp(examType ?? '');

      case CertificationType.languageExam:
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
          final grade = score?.toString() ?? '';
          return XpRule.getOtherLanguageExamXp(examType ?? '', grade);
        }

      case CertificationType.contest:
        final scale = details['scale'] as String?;
        final result = details['result'] as String?;
        return XpRule.getContestXp(scale ?? '', result ?? '');

      case CertificationType.exhibition:
        return XpRule.exhibitionParticipationXp;

      case CertificationType.otherActivity:
        return XpRule.otherActivityXp;
    }
  }

  /// 인증 결과 등록
  Future<String> createCertification(Certification certification) async {
    try {
      int calculatedXp = certification.xpEarned;
      if (calculatedXp == 0 && certification.certificationType != null) {
        calculatedXp = calculateCertificationXp(certification);
      }

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

      final docRef = await _firestore.collection(_collection).add(
        certificationWithXp.toFirestore(),
      );

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

  /// 인증 승인 처리 및 XP 부여
  Future<void> approveCertification(String certificationId, {int? xpAmount}) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      if (certification.reviewStatus == ReviewStatus.approved) {
        return;
      }

      int finalXp;
      if (xpAmount != null) {
        finalXp = xpAmount;
      } else {
        finalXp = certification.xpEarned;
        if (finalXp == 0 && certification.certificationType != null) {
          finalXp = calculateCertificationXp(certification);
        }
      }

      await _firestore.collection(_collection).doc(certificationId).update({
        'isApproved': true,
        'reviewStatus': ReviewStatus.approved.name,
        'xpEarned': finalXp,
      });

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

  /// 인증 거부 처리 및 XP 차감
  Future<void> rejectCertification(String certificationId, {String? rejectionReason}) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      if (certification.reviewStatus == ReviewStatus.rejected) {
        return;
      }

      if (certification.reviewStatus == ReviewStatus.approved && certification.xpEarned > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_rejected',
          amount: -certification.xpEarned,
          referenceId: certificationId,
        );
      }

      final updateData = {
        'isApproved': false,
        'reviewStatus': ReviewStatus.rejected.name,
        'xpEarned': 0,
      };
      
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        updateData['rejectionReason'] = rejectionReason;
      }
      
      await _firestore.collection(_collection).doc(certificationId).update(updateData);
    } catch (e) {
      throw Exception('인증 거부 실패: $e');
    }
  }

  /// 사용자의 모든 인증 목록 조회
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

  /// 특정 인증 상세 정보 스트림 조회
  Stream<DocumentSnapshot> getCertificationStream(String certificationId) {
    return _firestore.collection(_collection).doc(certificationId).snapshots();
  }

  /// 검토 대기 중인 인증이 있는 사용자 목록 조회 (관리자용)
  Future<List<Map<String, dynamic>>> getUsersWithPendingCertifications() async {
    try {
      final pendingSnapshot = await _firestore
          .collection(_collection)
          .where('reviewStatus', isEqualTo: 'pending')
          .get();

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
            usersWithCounts.add({
              'userId': userId,
              'nickname': '사용자',
              'email': '',
              'pendingCount': userPendingCounts[userId] ?? 0,
            });
          }
        } catch (e) {
          usersWithCounts.add({
            'userId': userId,
            'nickname': '사용자',
            'email': '',
            'pendingCount': userPendingCounts[userId] ?? 0,
          });
        }
      }

      usersWithCounts.sort((a, b) => (b['pendingCount'] as int).compareTo(a['pendingCount'] as int));

      return usersWithCounts;
    } catch (e) {
      throw Exception('유저 목록 가져오기 실패: $e');
    }
  }

  /// 인증 삭제 및 관련 이미지와 XP 정리
  Future<void> deleteCertification(String certificationId) async {
    try {
      final certDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!certDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }

      final certification = Certification.fromFirestore(certDoc);
      
      if (certification.imageUrl != null && certification.imageUrl!.isNotEmpty) {
        try {
          final imageUrl = certification.imageUrl!;
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          
          int photoProofsIndex = -1;
          for (int i = 0; i < pathSegments.length; i++) {
            if (pathSegments[i] == 'photo_proofs' || pathSegments[i] == 'challenge_proofs') {
              photoProofsIndex = i;
              break;
            }
          }
          
          if (photoProofsIndex >= 0 && photoProofsIndex < pathSegments.length - 1) {
            final storagePath = pathSegments.sublist(photoProofsIndex).join('/');
            final storageRef = FirebaseStorage.instance.ref().child(storagePath);
            await storageRef.delete();
          } else {
            final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          }
        } catch (storageError) {
          // Storage 삭제 실패는 무시
        }
      }
      
      if (certification.reviewStatus == ReviewStatus.approved && certification.xpEarned > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_deleted',
          amount: -certification.xpEarned,
          referenceId: certificationId,
        );
      }

      await _firestore.collection(_collection).doc(certificationId).delete();
    } catch (e) {
      throw Exception('인증 삭제 실패: $e');
    }
  }

  /// 인증 정보 수정 및 재검토 상태로 변경
  Future<void> updateCertification(String certificationId, Certification certification) async {
    try {
      int calculatedXp = certification.xpEarned;
      if (calculatedXp == 0 && certification.certificationType != null) {
        calculatedXp = calculateCertificationXp(certification);
      }

      final oldCertDoc = await _firestore.collection(_collection).doc(certificationId).get();
      if (!oldCertDoc.exists) {
        throw Exception('인증 문서를 찾을 수 없습니다.');
      }
      final oldCert = Certification.fromFirestore(oldCertDoc);

      final updatedCert = Certification(
        id: certificationId,
        challengeId: certification.challengeId,
        userId: certification.userId,
        imageUrl: certification.imageUrl,
        description: certification.description,
        proofDate: certification.proofDate,
        createdAt: oldCert.createdAt,
        isApproved: certification.isApproved,
        reviewStatus: ReviewStatus.pending,
        xpEarned: calculatedXp,
        certificationType: certification.certificationType,
        certificationDetails: certification.certificationDetails,
      );

      if (oldCert.reviewStatus == ReviewStatus.approved && oldCert.xpEarned > 0) {
        await _xpService.addXp(
          userId: certification.userId,
          action: 'certification_updated',
          amount: -oldCert.xpEarned,
          referenceId: certificationId,
        );
      }

      await _firestore.collection(_collection).doc(certificationId).update(
        updatedCert.toFirestore(),
      );
    } catch (e) {
      throw Exception('인증 수정 실패: $e');
    }
  }

}