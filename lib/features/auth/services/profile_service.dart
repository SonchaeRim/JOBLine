import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 현재 로그인된 UID
  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인 상태 아님");
    return user.uid;
  }

  // 프로필 이미지 업로드 후 Firestore에 URL 저장
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final ref = _storage.ref().child('user_profiles/$uid/profile.jpg');
      // Firebase Storage 업로드
      await ref.putFile(imageFile);

      // 다운로드 URL 가져오기
      final downloadUrl = await ref.getDownloadURL();

      // Firestore users 문서 업데이트
      await _db.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      // 내가 속한 채팅방들의 memberPhotoUrls도 함께 갱신
      final rooms = await _db
          .collection('chat_rooms')
          .where('memberIds', arrayContains: uid)
          .get();

      for (final doc in rooms.docs) {
        await doc.reference.update({
          'memberPhotoUrls.$uid': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return downloadUrl;
    } catch (e) {
      throw Exception("프로필 이미지 업로드 실패: $e");
    }
  }

  // Firestore에 저장된 내 프로필 정보 가져오기
  Future<Map<String, dynamic>?> getMyProfile() async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // 특정 UID 유저 정보 가져오기
  Future<Map<String, dynamic>?> getUserProfile(String targetUid) async {
    final doc = await _db.collection('users').doc(targetUid).get();
    return doc.data();
  }
}
