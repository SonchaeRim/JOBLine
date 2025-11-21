
//이메일/비밀번호/닉네임 입력 폼

import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 폼 입력 컨트롤러들
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 입력 필드 라벨과 텍스트 필드를 포함하는 재사용 가능한 위젯
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? helperText,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 (닉네임, 생년월일 등)
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // 텍스트 필드
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
        ),
        // 조건 텍스트 (아이디/비밀번호)
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              helperText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        const SizedBox(height: 25), // 다음 섹션과의 간격
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JL',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      // 스크롤 가능
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닉네임
              _buildInputField(
                label: '닉네임',
                controller: nicknameController,
                hintText: '취뽀',
              ),

              // 생년월일
              _buildInputField(
                label: '생년월일',
                controller: birthDateController,
                hintText: 'ex)031024',
              ),

              // 이메일 필드와 '확인' 버튼
              const Text(
                '이메일',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이메일 입력
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'ex)you@example.com',
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // '확인' 버튼
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // 이메일 중복 확인 로직
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        elevation: 0,
                      ),
                      child: const Text('확인', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 아이디 필드
              _buildInputField(
                label: '아이디',
                controller: idController,
                hintText: 'ex)bbo',
                helperText: '*조건 : 2글자 이상, 영어만 가능',
              ),

              // 비밀번호 필드
              _buildInputField(
                label: '비밀번호',
                controller: passwordController,
                hintText: 'ex)12345!',
                helperText: '*조건 : 5자리 이상, 특수기호 1개 이상 포함',
                obscureText: true, // 비밀번호 가리기
              ),

              const SizedBox(height: 50),

              // 하단 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // '가입취소' 버튼 (왼쪽)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 가입 취소 로직
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800, // 어두운 색상
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('가입취소', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // '다음' 버튼 (오른쪽)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // 다음 단계 로직
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600, // 파란색
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('다음', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
