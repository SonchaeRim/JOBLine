// lib/features/auth/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // print 대신 log를 사용하거나 디버그 용도로 사용 가능

/// Firebase 인증(Auth) 및 Firestore 데이터베이스 관련 작업을 처리하는 서비스 클래스
class AuthService {
  // 1. Firebase Auth 인스턴스 초기화 (Firebase Auth 연동 및 초기 설정)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 2. Firestore 인스턴스 초기화 (Firestore에 users 컬렉션 설계 기반)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 사용자 정보를 스트림으로 제공하는 Getter
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 로그인된 사용자의 UID를 가져오는 Getter
  String? get currentUserId => _auth.currentUser?.uid;

  // 이메일/비밀번호 회원가입 함수
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name, // 사용자 이름 (회원가입 시 필수로 받음)
    required String nickname, // 사용자 닉네임 (회원가입 시 필수로 받음)
  }) async {
    try {
      // 1. Firebase Auth에 사용자 생성
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. 회원가입/최초 로그인 시 users/{uid} 문서 생성 (Firestore)
        // Firestore의 users 컬렉션에 사용자 UID를 문서 ID로 하여 데이터 저장
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': name,
          'nickname': nickname,
          'birth': '', // 이미지에서 본 빈 필드 초기화
          'pwd': '', // 비밀번호 해시는 Auth에 저장되므로, 여기는 빈 문자열로 초기화
          'createdAt': Timestamp.now(), // 생성 시각 추가 (선택 사항)
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Auth 관련 에러 처리 (예: 이미 존재하는 이메일, 약한 비밀번호 등)
      debugPrint("회원가입 오류: ${e.code} - ${e.message}");
      rethrow; // 에러를 호출한 곳으로 다시 던져서 UI에 표시하도록 처리
    } catch (e) {
      // 기타 예상치 못한 에러 처리
      debugPrint("회원가입 중 알 수 없는 오류 발생: $e");
      rethrow;
    }
  }

  // 이메일/비밀번호 로그인 함수
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 참고: 로그인은 Auth만 사용하며, Firestore 문서 생성은 회원가입 시점에만 합니다.
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // 로그인 관련 에러 처리 (예: 잘못된 비밀번호, 존재하지 않는 사용자 등)
      debugPrint("로그인 오류: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("로그인 중 알 수 없는 오류 발생: $e");
      rethrow;
    }
  }

  // 로그아웃 함수-
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("로그아웃 오류: $e");
      rethrow;
    }
  }

  // 닉네임/프로필 이미지 변경 시 users/{uid} 업데이트 함수
  Future<void> updateUserData({
    String? name,
    String? nickname,
    String? birth,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      // 로그인되지 않은 상태에서 업데이트를 시도하는 경우
      throw Exception("로그인된 사용자가 없습니다.");
    }

    // 변경할 필드만 담는 맵 생성
    Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (nickname != null) updateData['nickname'] = nickname;
    if (birth != null) updateData['birth'] = birth;

    // 만약 업데이트할 데이터가 없다면 종료
    if (updateData.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).update(updateData);
      debugPrint("사용자 데이터 업데이트 성공: $updateData");
    } on FirebaseException catch (e) {
      debugPrint("Firestore 업데이트 오류: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("데이터 업데이트 중 알 수 없는 오류 발생: $e");
      rethrow;
    }
  }

  Future<String?> getEmailByUsername(String username) async {
    try {
      // Firestore의 'users' 컬렉션에서 'name' 필드가 입력된 username과 일치하는 문서를 찾음
      QuerySnapshot result = await _firestore.collection('users')
          .where('name', isEqualTo: username) // SignUpScreen에서 idController.text를 'name' 필드에 저장했음
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        // 해당 아이디를 가진 문서에서 이메일 필드를 반환
        return result.docs.first.get('email');
      }
      return null; // 일치하는 아이디가 없음
    } catch (e) {
      debugPrint("아이디 조회 오류: $e");
      return null;
    }
  }
}