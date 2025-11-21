import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// 유저의 mainCommunityId 읽기
  Future<String?> getMainCommunityId(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['mainCommunityId'] as String?;
  }

  /// 유저의 mainCommunityId 저장/변경
  Future<void> setMainCommunityId(String uid, String communityId) async {
    await _userDoc(uid)
        .set({'mainCommunityId': communityId}, SetOptions(merge: true));
  }
}
