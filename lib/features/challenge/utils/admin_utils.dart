/// 관리자 유틸리티 - 관리자 권한 확인
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스

  /// 현재 사용자가 관리자인지 확인
  static Future<bool> isAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final role = userData?['role'] as String?;
      
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }
}