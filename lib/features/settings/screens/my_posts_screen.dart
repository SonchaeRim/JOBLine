import 'package:flutter/material.dart';
import 'package:jobline/features/board/models/post.dart';
import 'package:jobline/features/board/services/board_service.dart';
import '../../../routes/route_names.dart';

/// 내가 쓴 게시물 화면
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _svc = BoardService();

  String _fmtDate(DateTime dt) {
    // PostListScreen에서 사용된 간단한 날짜 형식 재사용
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    // 1. BoardService에서 내가 쓴 게시물 Stream 가져오기
    final stream = _svc.watchMyPosts();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내가 쓴 게시물',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Post>>(
          stream: stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator()); // 로딩 중
            }
            if (snap.hasError) {
              return Center(child: Text('게시물 로드 중 에러: ${snap.error}')); // 에러 발생
            }

            final posts = snap.data ?? []; // 3. 게시물 데이터

            if (posts.isEmpty) {
              return const Center(
                child: Text('작성한 게시물이 없습니다.'), // 게시물 없음
              );
            }
            return ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                final timeText = _fmtDate(post.createdAt);
                final commentCount = post.commentCount;

                return ListTile(
                  title: Text(
                    post.title, // Post 모델에서 title 사용
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
                          post.content, // Post 모델에서 content 사용
                          maxLines: 1, // 한 줄만 표시하도록 변경
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              timeText,
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
                    // TODO: 게시글 상세 화면으로 이동 (RouteNames.postDetail 사용)
                    Navigator.pushNamed(
                      context,
                      RouteNames.postDetail,
                      arguments: post.id,
                    );
                  },
                );
              },
            );
          },
      ),
    );
  }
}
