import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../routes/route_names.dart';
import '../../board/services/board_service.dart';
import '../../board/models/post.dart';

class BoardSection extends StatelessWidget {
  final String userId;
  BoardSection({super.key, required this.userId});

  final _svc = BoardService();

  static const boards = [
    {'id': 'free',   'title': '자유 게시판'},
    {'id': 'study',  'title': '스터디 / 프로젝트 게시판'},
    {'id': 'job',    'title': '취준생 게시판'},
    {'id': 'review', 'title': '기업 후기 게시판'},
    {'id': 'spec',   'title': '스펙 게시판'},
  ];

  Stream<String?> _mainCommunityIdStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['mainCommunityId'] as String?);
  }

  String _preview(Post p) {
    // 홈에서는 “최신글 제목” 위주로 보여주고,
    // 제목이 비면 content 앞부분으로 대체
    if (p.title.trim().isNotEmpty) return p.title.trim();
    if (p.content.trim().isNotEmpty) return p.content.trim();
    return '최신 게시글이 없습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<String?>(
        stream: _mainCommunityIdStream(),
        builder: (context, snap) {
          final communityId = snap.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '게시판',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: boards.asMap().entries.map((entry) {
                    final i = entry.key;
                    final b = entry.value;
                    final boardId = b['id']!;
                    final title = b['title']!;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            // 게시판(리스트)로 이동
                            Navigator.pushNamed(
                              context,
                              RouteNames.postList,
                              arguments: {
                                'boardId': boardId,
                                'title': title,
                                'communityId': communityId, // null일 수도 있음
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: (communityId == null || communityId.trim().isEmpty)
                                      ? const Text(
                                    '커뮤니티를 설정해 주세요',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  )
                                      : StreamBuilder<List<Post>>(
                                    stream: _svc.watchPosts(
                                      boardId,
                                      communityId: communityId,
                                      limit: 1, // ✅ 최신글 1개
                                    ),
                                    builder: (context, postSnap) {
                                      if (postSnap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text(
                                          '불러오는 중...',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        );
                                      }
                                      if (postSnap.hasError) {
                                        return Text(
                                          '에러: ${postSnap.error}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        );
                                      }

                                      final list = postSnap.data ?? [];
                                      if (list.isEmpty) {
                                        return const Text(
                                          '최신 게시글이 없습니다.',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        );
                                      }

                                      return Text(
                                        _preview(list.first),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF666666),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (i != boards.length - 1)
                          Divider(height: 1, color: Colors.grey.shade200),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
