import 'package:flutter/material.dart';

/// 커뮤니티 변경 화면 (임시)
class CommunityChangeScreen extends StatelessWidget {
  const CommunityChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 커뮤니티 목록 가져오기
    final List<String> communities = [
      '개발/IT',
      '디자인/예술',
      '공기업/공무원',
      '마케팅',
      '기획',
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '커뮤니티 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          return ListTile(
            title: Text(community),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showConfirmDialog(context, community);
            },
          );
        },
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String communityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커뮤니티 변경'),
        content: Text('$communityName 커뮤니티로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 커뮤니티 변경 로직
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 화면 닫기
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }
}
