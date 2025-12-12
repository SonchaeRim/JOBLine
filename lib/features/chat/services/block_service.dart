import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// 내가 차단한 유저 uid 목록
  Future<Set<String>> getMyBlockedSet() async {
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data();
    final blocked = List<String>.from(data?['blocked'] as List? ?? const []);
    return blocked.toSet();
  }

  Future<void> blockUser(String targetUid) async {
    await _db.collection('users').doc(_uid).update({
      'blocked': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> unblockUser(String targetUid) async {
    await _db.collection('users').doc(_uid).update({
      'blocked': FieldValue.arrayRemove([targetUid]),
    });
  }
}
