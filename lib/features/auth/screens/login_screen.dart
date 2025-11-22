//이메일/비밀번호 TextField + 로그인 버튼 + "회원가입" 이동 버튼

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  //textfield처럼 입력 받고 화면 상태가 변할 때 사용
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); //비공개(_)함수
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false; //비번 숨김처리
  bool _isLoginChecked = false; //자동로그인 체크

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
                onPressed: () {
                  //이동 로직
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
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('자동 로그인', style: TextStyle(fontSize: 14)), // 텍스트 추가
            Checkbox(
              value: _isLoginChecked,
              onChanged: (bool? newValue) {
                setState(() {
                  _isLoginChecked = newValue ?? false; // 상태 업데이트
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        const SizedBox(height: 50),

        ],
        ),
      ),
    );
  }
}

