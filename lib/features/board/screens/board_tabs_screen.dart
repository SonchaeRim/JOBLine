import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';
// 라우트 준비 전이니 import는 잠시 보류해도 됨
// import '../../../routes/route_names.dart';

class BoardTabsScreen extends StatelessWidget {
  const BoardTabsScreen({super.key});

  static const boards = [
    {'id': 'free',   'title': '자유게시판',          'icon': Icons.push_pin},
    {'id': 'study',  'title': '스터디/프로젝트 게시판', 'icon': Icons.push_pin},
    {'id': 'job',    'title': '취준생 게시판',        'icon': Icons.push_pin},
    {'id': 'review', 'title': '기업 후기 게시판',      'icon': Icons.push_pin},
    {'id': 'spec',   'title': '스펙 게시판',          'icon': Icons.push_pin},
  ];

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('JL'), // 상단 JL 로고/타이틀
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text('게시판 목록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: boards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final b = boards[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.postList, // ✅ 하드코드 문자열 대신 상수 사용
                        arguments: {'boardId': b['id'], 'title': b['title']},
                      );
                    },


                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(b['icon'] as IconData, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(b['title'] as String,
                                style: const TextStyle(fontSize: 16)),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
