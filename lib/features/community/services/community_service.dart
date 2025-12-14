import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community.dart';

class CommunityService {
  final _db = FirebaseFirestore.instance;

  /// 커뮤니티 전체 가져오기 (1회)
  Future<List<Community>> fetchCommunities() async {
    final qs = await _db.collection('communities').get();
    return qs.docs.map((d) => Community.fromDoc(d.id, d.data())).toList();
  }

  /// 사용자의 mainCommunityId 읽기
  Future<String?> getMainCommunityId(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['mainCommunityId'] as String?;
  }

  /// 사용자의 mainCommunityId 저장/변경
  Future<void> setMainCommunityId(String uid, String communityId) {
    return _db.collection('users').doc(uid).set(
      {'mainCommunityId': communityId},
      SetOptions(merge: true),
    );
  }
}
