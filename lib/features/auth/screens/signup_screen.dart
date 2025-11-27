import 'package:flutter/material.dart';
import 'package:jobline/features/community/screens/category_select_screen.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isButtonEnabled() {
    return nicknameController.text.isNotEmpty &&
        birthDateController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        idController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  String? _validateId(String? value) {
    if (value == null || value.isEmpty) return '아이디를 입력해주세요';
    if (value.length < 2) return '아이디는 2글자 이상이어야 합니다';
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) return '영어만 사용 가능합니다';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요';
    if (value.length < 5) return '비밀번호는 5자리 이상이어야 합니다';
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) return '특수문자 1개 이상 포함';
    return null;
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? helperText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          validator: validator,
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              helperText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        const SizedBox(height: 25),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원가입',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}), // 입력 변화 시 버튼 활성화 갱신
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: '닉네임',
                controller: nicknameController,
                hintText: '취뽀',
                validator: (value) =>
                value!.isEmpty ? '닉네임을 입력하세요' : null,
              ),
              _buildInputField(
                label: '생년월일',
                controller: birthDateController,
                hintText: 'ex)031024',
                validator: (value) =>
                value!.isEmpty ? '생년월일을 입력하세요' : null,
              ),
              _buildInputField(
                label: '이메일',
                controller: emailController,
                hintText: 'ex)you@example.com',
                validator: (value) =>
                value!.isEmpty ? '이메일을 입력하세요' : null,
              ),
              _buildInputField(
                label: '아이디',
                controller: idController,
                hintText: 'ex)bbo',
                helperText: '*조건 : 2글자 이상, 영어만 가능',
                validator: _validateId,
              ),
              _buildInputField(
                label: '비밀번호',
                controller: passwordController,
                hintText: 'ex)12345!',
                helperText: '*조건 : 5자리 이상, 특수문자 1개 이상 포함',
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 50),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // 가입취소 → 이전 화면
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('가입취소'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isButtonEnabled()
                            ? () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategorySelectScreen(),
                              ),
                            );
                          }
                        }
                            : null,
                        child: const Text('다음'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonEnabled()
                              ? Colors.blue.shade600
                              : Colors.grey.shade400,
                        ),
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
