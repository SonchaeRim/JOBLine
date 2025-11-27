import 'package:flutter/material.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final TextEditingController oldPwController = TextEditingController();
  final TextEditingController newPwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  String? _errorText;

  // 비밀번호 조건 체크 (5자리 이상, 특수문자 1개 이상)
  bool _validatePassword(String password) {
    final specialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return password.length >= 5 && specialChar.hasMatch(password);
  }

  void _onConfirmPressed() {
    final newPw = newPwController.text;
    final confirmPw = confirmPwController.text;

    setState(() {
      if (!_validatePassword(newPw)) {
        _errorText = "비밀번호 조건을 충족하지 않습니다.";
      } else if (newPw != confirmPw) {
        _errorText = "새 비밀번호와 확인이 일치하지 않습니다.";
      } else {
        _errorText = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호 변경 완료!")),
        );
      }
    });
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _onConfirmPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('확인', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_errorText == null) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('변경 완료', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
