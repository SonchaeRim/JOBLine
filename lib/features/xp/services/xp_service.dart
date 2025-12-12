import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rank.dart';

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
      // amount가 지정되지 않으면 0 (항상 amount를 지정해야 함)
      final xpAmount = amount ?? 0;

      if (xpAmount <= 0) return;

      // 사용자 문서 가져오기
      final userDoc = _firestore.collection(_usersCollection).doc(userId);
      final userData = await userDoc.get();

      int currentXp = 0;
      if (userData.exists) {
        currentXp = (userData.data()?['totalXp'] as int?) ?? 0;
      }

      final newXp = currentXp + xpAmount;
      final newRank = RankUtil.getRank(newXp).name;

      // 사용자 XP 업데이트
      await userDoc.set({
        'totalXp': newXp,
        'rank': newRank,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // XP 로그 기록
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

  /// 사용자의 현재 XP와 등급 가져오기
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

      // rank 필드가 없으면 추가
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
          'rank': RankUtil.getRank(0).name,
        };
      }

      final data = doc.data()!;
      final totalXp = (data['totalXp'] as int?) ?? 0;
      final rank = (data['rank'] as String?) ?? RankUtil.getRank(totalXp).name;

      // rank 필드가 없으면 백그라운드에서 추가 (스트림 내부에서는 await 불가)
      if (data['rank'] == null) {
        doc.reference.update({'rank': rank}).catchError((e) {
          // 업데이트 실패는 무시 (다음 스트림 업데이트에서 다시 시도)
        });
      }

      return {
        'totalXp': totalXp,
        'rank': rank,
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
                'createdAt': (data['createdAt'] as Timestamp).toDate(),
              };
            })
            .toList());
  }
}

