import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../routes/route_names.dart';

class BoardTabsScreen extends StatelessWidget {
  const BoardTabsScreen({super.key});

  static const boards = [
    {'id': 'free',   'title': '자유게시판',            'icon': Icons.push_pin},
    {'id': 'study',  'title': '스터디/프로젝트 게시판',  'icon': Icons.push_pin},
    {'id': 'job',    'title': '취준생 게시판',          'icon': Icons.push_pin},
    {'id': 'review', 'title': '기업 후기 게시판',        'icon': Icons.push_pin},
    {'id': 'spec',   'title': '스펙 게시판',            'icon': Icons.push_pin},
  ];

  // 유저 문서에서 mainCommunityId를 실시간으로 구독
  Stream<String?> _mainCommunityIdStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<String?>.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      final v = data['mainCommunityId'];
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return StreamBuilder<String?>(
      stream: _mainCommunityIdStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final communityId = snap.data;

        if (communityId == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 12),
                Text(
                  '메인 커뮤니티가 설정되지 않았습니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text('회원가입 후 커뮤니티 선택을 완료해 주세요.'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'JL',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '게시판 목록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // 현재 커뮤니티 표시
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_rounded, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          '현재 커뮤니티',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      communityId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 회색 박스 카드들
              Expanded(
                child: ListView.separated(
                  itemCount: boards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final b = boards[i];
                    final boardId = b['id'] as String;
                    final title = b['title'] as String;
                    final icon = b['icon'] as IconData;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.postList,
                          arguments: {
                            'boardId': boardId,
                            'title': title,
                            'communityId': communityId,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black54),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
