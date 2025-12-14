/// XP 관리 서비스 - XP 추가, 조회, 등급 계산 및 로그 관리
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rank.dart';

class XpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스
  final String _usersCollection = 'users'; // 사용자 컬렉션 이름
  final String _xpLogsCollection = 'xp_logs'; // XP 로그 컬렉션 이름

  /// XP 추가 및 등급 업데이트
  Future<void> addXp({
    required String userId,
    required String action,
    int? amount,
    String? referenceId,
  }) async {
    try {
      final xpAmount = amount ?? 0;

      if (xpAmount <= 0) return;

      final userDoc = _firestore.collection(_usersCollection).doc(userId);
      final userData = await userDoc.get();

      int currentXp = 0;
      if (userData.exists) {
        currentXp = (userData.data()?['totalXp'] as int?) ?? 0;
      }

      final newXp = currentXp + xpAmount;
      final newRank = RankUtil.getRank(newXp).name;

      await userDoc.set({
        'totalXp': newXp,
        'rank': newRank,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection(_xpLogsCollection).add({
        'userId': userId,
        'action': action,
        'amount': xpAmount,
        'totalXp': newXp,
        'referenceId': referenceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('XP 추가 실패: $e');
    }
  }

  /// 사용자의 현재 XP와 등급 조회
  Future<Map<String, dynamic>> getUserXp(String userId) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!userDoc.exists) {
        return {
          'totalXp': 0,
          'rank': RankUtil.getRank(0).name,
        };
      }

      final data = userDoc.data()!;
      final totalXp = (data['totalXp'] as int?) ?? 0;
      final rank = (data['rank'] as String?) ?? RankUtil.getRank(totalXp).name;

      if (data['rank'] == null) {
        await userDoc.reference.update({'rank': rank});
      }

      return {
        'totalXp': totalXp,
        'rank': rank,
      };
    } catch (e) {
      throw Exception('XP 조회 실패: $e');
    }
  }

  /// 사용자의 XP 실시간 스트림 조회
  Stream<Map<String, dynamic>> getUserXpStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'totalXp': 0,
          'rank': RankUtil.getRank(0).name,
        };
      }

      final data = doc.data()!;
      final totalXp = (data['totalXp'] as int?) ?? 0;
      final rank = (data['rank'] as String?) ?? RankUtil.getRank(totalXp).name;

      if (data['rank'] == null) {
        doc.reference.update({'rank': rank}).catchError((e) {
          // 업데이트 실패는 무시
        });
      }

      return {
        'totalXp': totalXp,
        'rank': rank,
      };
    });
  }

  /// 사용자의 XP 변경 로그 조회
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
                'createdAt': (data['createdAt'] as Timestamp).toDate(),
              };
            })
            .toList());
  }
}

