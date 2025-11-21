import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';

/// 챌린지 관리 서비스
class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'challenges'; // Firestore 컬렉션 이름

  /// 활성화된 챌린지 목록 가져오기
  Stream<List<Challenge>> getActiveChallenges() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  /// 특정 챌린지 가져오기
  Future<Challenge?> getChallengeById(String challengeId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(challengeId).get();
      if (doc.exists) {
        return Challenge.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('챌린지 조회 실패: $e');
    }
  }

  /// 사용자가 참여 중인 챌린지 목록 가져오기 (인증 기록 기반)
  Future<List<Challenge>> getUserChallenges(String userId) async {
    // certifications 컬렉션에서 사용자의 인증 기록을 가져와서
    // 참여 중인 챌린지 ID 목록을 추출
    final certSnapshot = await _firestore
        .collection('certifications')
        .where('userId', isEqualTo: userId)
        .get();

    final challengeIds = certSnapshot.docs
        .map((doc) => doc.data()['challengeId'] as String)
        .toSet()
        .toList();

    if (challengeIds.isEmpty) return [];

    // 챌린지 정보 가져오기
    final challenges = <Challenge>[];
    for (final id in challengeIds) {
      final challenge = await getChallengeById(id);
      if (challenge != null && challenge.isOngoing) {
        challenges.add(challenge);
      }
    }

    return challenges;
  }
}

