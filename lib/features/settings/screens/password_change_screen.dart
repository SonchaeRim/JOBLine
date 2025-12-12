import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser; // 현재 로그인된 사용자 정보
  final TextEditingController oldPwController = TextEditingController();
  final TextEditingController newPwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;

  // 비밀번호 조건 체크 (5자리 이상, 특수문자 1개 이상)
  bool _validatePassword(String password) {
    final specialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return password.length >= 5 && specialChar.hasMatch(password);
  }

  void _onConfirmPressed() async {
    final oldPw = oldPwController.text.trim();
    final newPw = newPwController.text.trim();
    final confirmPw = confirmPwController.text.trim();

    // 1. 유효성 검사
    setState(() {
      if (oldPw.isEmpty) {
        _errorText = "기존 비밀번호를 입력해주세요.";
      } else if (!_validatePassword(newPw)) {
        _errorText = "비밀번호 조건을 충족하지 않습니다.";
      } else if (newPw != confirmPw) {
        _errorText = "새 비밀번호와 확인이 일치하지 않습니다.";
      } else if (oldPw == newPw) {
        _errorText = "기존 비밀번호와 새 비밀번호가 동일합니다.";
      } else {
        _errorText = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호 변경 완료!")),
        );
      }
    });

    if (_errorText != null) return; // 오류가 있으면 종료

    try {
      // 2. 재인증 (Re-authenticate): 기존 비밀번호가 맞는지 확인
      AuthCredential credential = EmailAuthProvider.credential(
        email: _currentUser!.email!, // 현재 로그인된 사용자의 이메일 사용
        password: oldPw,
      );

      await _currentUser!.reauthenticateWithCredential(credential);

      // 3. 비밀번호 업데이트 (Update Password)
      await _currentUser!.updatePassword(newPw);

      // 성공 처리 및 화면 종료
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
        );
        Navigator.pop(context); // 이전 화면으로 돌아가기
      }

    } on FirebaseAuthException catch (e) {
      // 4. Firebase 오류 처리 (재인증 실패 시)
      String message;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = '기존 비밀번호가 일치하지 않습니다.';
      } else if (e.code == 'requires-recent-login') {
        message = '보안상 재로그인이 필요합니다. 앱을 다시 시작하여 로그인해주세요.';
      } else {
        message = '비밀번호 변경에 실패했습니다: ${e.message}';
      }

      setState(() {
        _errorText = message;
      });

    } catch (e) {
      setState(() {
        _errorText = "알 수 없는 오류가 발생했습니다: $e";
      });
    } finally {
      setState(() {
        _isLoading = false; // 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 입력 필드 영역 (스크롤 가능)
          Padding(
            padding: const EdgeInsets.only(bottom: 100), // 버튼 공간 확보
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '기존 비밀번호',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: oldPwController,
                    decoration: InputDecoration(
                      hintText: 'ex)12345!',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    '새 비밀번호',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newPwController,
                    decoration: InputDecoration(
                      hintText: 'ex)54321!!',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '*조건 : 5자리 이상, 특수기호 1개 이상 포함',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    '새 비밀번호 확인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmPwController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),

                  // 오류 메시지
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 버튼 영역 (하단 고정)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white, // 배경색 설정
              padding: const EdgeInsets.all(20),
              child:ElevatedButton(
                onPressed: _isLoading ? null : _onConfirmPressed, // 로딩 중에는 버튼 비활성화
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                      ),
                  )
                          : const Text(
                            '변경 완료',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
