import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import '../services/board_service.dart';
import '../models/post.dart';

class PostListScreen extends StatefulWidget {
  final String boardId;
  final String title;
  final String? communityId;

  const PostListScreen({
    super.key,
    required this.boardId,
    required this.title,
    this.communityId,
  });

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _svc = BoardService();

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // StreamBuilder는 widget 값 바뀌면 자동으로 새 query로 rebuild됨
    // 여기서 따로 fetch/refresh 필요 없음
  }

  String _fmtDate(DateTime dt) {
    // 간단 표시 (원하면 “n분 전”으로 바꿔줄게)
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  bool _match(Post p, String q) {
    if (q.isEmpty) return true;
    final qq = q.toLowerCase();

    final t = p.title.toLowerCase();
    final c = p.content.toLowerCase();
    // authorName 필드가 Post 모델에 있으면 여기 같이 검색 가능
    final a = (p.authorName ?? '').toLowerCase();

    return t.contains(qq) || c.contains(qq) || a.contains(qq);
  }

  @override
  Widget build(BuildContext context) {
    final stream = _svc.watchPosts(
      widget.boardId,
      communityId: widget.communityId,
      limit: 50,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // ===== 검색 바 =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: '글 제목, 내용, 작성자 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: (_searchCtrl.text.isEmpty)
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // ===== 리스트 =====
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('에러: ${snap.error}'));
                }

                final all = snap.data ?? [];
                final items = all.where((p) => _match(p, _query)).toList();

                if (items.isEmpty) {
                  return const Center(child: Text('글이 없습니다.'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = items[i];

                    // createdAt이 null일 수도 있는 프로젝트면 여기 방어해줘야 함
                    final timeText = _fmtDate(p.createdAt);

                    final commentCount = p.commentCount; // 여기서 바로 표시
                    final likeCount = p.likeCount ?? 0;  // likeCount 없으면 0 처리

                    return ListTile(
                      title: Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${p.authorName ?? "익명"} · $timeText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '댓글 $commentCount개',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.postDetail,
                          arguments: p.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            RouteNames.postEditor,
            arguments: {
              'boardId': widget.boardId,
              'postId': null,
            },
          );
          // StreamBuilder라서 여기서 _reload() 같은 거 필요 없음 (자동 반영)
        },
        label: const Text('✍️ 게시글 작성하기'),
      ),
    );
  }
}
