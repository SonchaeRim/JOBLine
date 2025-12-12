//이메일/비밀번호 TextField + 로그인 버튼 + "회원가입" 이동 버튼

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobline/features/auth/screens/signup_screen.dart';
import '../../../routes/route_names.dart';
import '../../auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  //textfield처럼 입력 받고 화면 상태가 변할 때 사용
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); //비공개(_)함수
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false; //비번 숨김처리
  bool _isLoginChecked = false; //자동로그인 체크

  static const String _autoLoginKey = 'isAutoLoginChecked';
  @override
  void initState() {
    super.initState();
    _loadAutoLoginState(); // 위젯 초기화 시 저장된 상태 로드
  }

  // 저장된 자동 로그인 체크 상태를 로드
  Future<void> _loadAutoLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isChecked = prefs.getBool(_autoLoginKey) ?? false;

    if (mounted) {
      setState(() {
        _isLoginChecked = isChecked;
      });
      // 앱 시작 시 자동 로그인 체크가 되어 있다면 바로 로그인 시도
      if (isChecked) {
         _attemptAutoLogin();
      }
    }
  }

  // 자동 로그인 체크 상태를 SharedPreferences에 저장
  Future<void> _saveAutoLoginState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, value);
  }

  // 자동 로그인 시도 (Firebase Auth의 현재 사용자 확인)
  Future<void> _attemptAutoLogin() async {
    // FirebaseAuth.instance.currentUser는 이미 로그인된 사용자 정보를 가지고 있습니다.
    if (FirebaseAuth.instance.currentUser != null && _isLoginChecked) {
      // SharedPreferences에 저장된 사용자 정보(ID/Email)가 있다면 추가 확인 가능
      // 현재는 단순히 Auth 상태만 확인하고 이동합니다.
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text("jl")),
      body: SingleChildScrollView( //오버플로우 방지
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 150),
            const Text(
              'JL',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
            const SizedBox(height: 50),
            //아이디 입력
            TextField(
              controller: idController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: "아이디",
                filled: true,
              fillColor: Colors.white,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
          ) ,
        ),
          const SizedBox(height:10),

          //비밀번호 입력
          TextField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: "비밀번호",
              filled: true,
              fillColor: Colors.white,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                color: Colors.grey
            ) ,
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible; //상태 업데이트
                  });
                },
              ),
            ),
          ),
          const SizedBox(height:30),
          //로그인 버튼
            SizedBox(
              width: double.infinity, //버튼 너비 넓게
                height: 50,
              child: ElevatedButton(
                onPressed: () async { // 비동기 함수(async)
                  // 폼 유효성 검사를 대신할 간단한 입력 확인
                  if (idController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
                    );
                    return;
                  }
                  // 1. 아이디를 사용하여 Firestore에서 이메일 주소를 찾습니다.
                  String? email = await _authService.getEmailByUsername(idController.text);

                  if (email == null) {
                    // 아이디가 Firestore에 없는 경우
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('존재하지 않는 아이디입니다.')),
                      );
                    }
                    return;
                  }
                  try {
                    // 1. 로그인 시도 (Firebase Auth)
                    await _authService.signInWithEmail(
                      email: email,
                      password: passwordController.text,
                    );

                    // 2. 로그인 성공 시 처리
                    if (context.mounted) {
                      // MainScreen 또는 홈 화면으로 이동 (RouteNames.home 사용)
                      // pushReplacementNamed를 사용하여 로그인 화면 스택 제거
                      Navigator.pushReplacementNamed(context, RouteNames.home);
                    }

                  } on FirebaseException catch (e) {
                    // 3. Firebase 관련 오류 처리 (잘못된 비밀번호, 사용자 없음 등)
                    if (context.mounted) {
                      String errorMessage = '로그인 실패';
                      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
                        errorMessage = '아이디 또는 비밀번호가 일치하지 않습니다.';
                      } else {
                        errorMessage = e.message ?? '알 수 없는 오류가 발생했습니다.';
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    }
                  } catch (e) {
                    // 4. 기타 알 수 없는 오류 처리
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('예기치 않은 오류가 발생했습니다.')),
                      );
                    }
                  }
               },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('로그인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height:10),

          //회원가입 버튼
        SizedBox(
          width: double.infinity, //버튼 너비 넓게
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              //이동 로직
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('회원가입',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('자동 로그인', style: TextStyle(fontSize: 14)), // 텍스트 추가
            Checkbox(
              value: _isLoginChecked,
              onChanged: (bool? newValue) {
                final checked = newValue ?? false;
                setState(() {
                  _isLoginChecked = checked; // 상태 업데이트
                  });
                  _saveAutoLoginState(checked);
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        const SizedBox(height: 20),
        ],
        ),
      ),
    );
  }
}