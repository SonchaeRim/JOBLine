import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 사용자 차단 관련 서비스
class BlockService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// 내가 차단한 유저 uid Set으로 가져오기
  Future<Set<String>> getMyBlockedSet() async {
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data();
    final blocked = List<String>.from(data?['blocked'] as List? ?? const []);
    return blocked.toSet();
  }

  /// targetUid 차단
  Future<void> blockUser(String targetUid) async {
    await _db.collection('users').doc(_uid).update({
      'blocked': FieldValue.arrayUnion([targetUid]),
    });
  }

  /// targetUid 차단 해제
  Future<void> unblockUser(String targetUid) async {
    await _db.collection('users').doc(_uid).update({
      'blocked': FieldValue.arrayRemove([targetUid]),
    });
  }
}
