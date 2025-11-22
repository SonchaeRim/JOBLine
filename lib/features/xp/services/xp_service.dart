import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/xp_rule.dart';

/// XP 관리 서비스
class XpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users'; // Firestore 컬렉션 이름
  final String _xpLogsCollection = 'xp_logs'; // Firestore 컬렉션 이름

  /// XP 추가
  Future<void> addXp({
    required String userId,
    required String action,
    int? amount,
    String? referenceId,
  }) async {
    try {
      // 액션별 기본 XP 가져오기
      final xpAmount = amount ?? XpRule.getXpForAction(action);

      if (xpAmount <= 0) return;

      // 사용자 문서 가져오기
      final userDoc = _firestore.collection(_usersCollection).doc(userId);
      final userData = await userDoc.get();

      int currentXp = 0;
      if (userData.exists) {
        currentXp = (userData.data()?['totalXp'] as int?) ?? 0;
      }

      final newXp = currentXp + xpAmount;
      final newLevel = XpRule.calculateLevel(newXp);

      // 사용자 XP 업데이트
      await userDoc.set({
        'totalXp': newXp,
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // XP 로그 기록
      await _firestore.collection(_xpLogsCollection).add({
        'userId': userId,
        'action': action,
        'amount': xpAmount,
        'totalXp': newXp,
        'level': newLevel,
        'referenceId': referenceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('XP 추가 실패: $e');
    }
  }

  /// 사용자의 현재 XP와 레벨 가져오기
  Future<Map<String, dynamic>> getUserXp(String userId) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!userDoc.exists) {
        return {
          'totalXp': 0,
          'level': 0,
          'xpToNextLevel': 100,
          'progress': 0.0,
        };
      }

      final data = userDoc.data()!;
      final totalXp = (data['totalXp'] as int?) ?? 0;
      final level = (data['level'] as int?) ?? 0;

      return {
        'totalXp': totalXp,
        'level': level,
        'xpToNextLevel': XpRule.getXpToNextLevel(totalXp),
        'progress': XpRule.getLevelProgress(totalXp),
      };
    } catch (e) {
      throw Exception('XP 조회 실패: $e');
    }
  }

  /// 사용자의 XP 스트림
  Stream<Map<String, dynamic>> getUserXpStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'totalXp': 0,
          'level': 0,
          'xpToNextLevel': 100,
          'progress': 0.0,
        };
      }

      final data = doc.data()!;
      final totalXp = (data['totalXp'] as int?) ?? 0;

      return {
        'totalXp': totalXp,
        'level': (data['level'] as int?) ?? 0,
        'xpToNextLevel': XpRule.getXpToNextLevel(totalXp),
        'progress': XpRule.getLevelProgress(totalXp),
      };
    });
  }

  /// 사용자의 XP 로그 가져오기
  Stream<List<Map<String, dynamic>>> getXpLogs(String userId, {int limit = 50}) {
    return _firestore
        .collection(_xpLogsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'action': data['action'],
                'amount': data['amount'],
                'totalXp': data['totalXp'],
                'level': data['level'],
                'createdAt': (data['createdAt'] as Timestamp).toDate(),
              };
            })
            .toList());
  }
}

