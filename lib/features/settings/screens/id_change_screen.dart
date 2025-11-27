import 'package:flutter/material.dart';

/// 아이디 변경 화면 (임시)
class IdChangeScreen extends StatelessWidget {
  const IdChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '아이디 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 아이디',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '현재 아이디 표시',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabled: false,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              '새 아이디',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '새 아이디를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '*조건 : 4자리 이상, 영문/숫자만 사용 가능',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 아이디 변경 로직
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('변경 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
