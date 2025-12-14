import 'package:flutter/material.dart';
import 'package:jobline/features/board/models/comment.dart';
import 'package:jobline/features/board/services/board_service.dart';
import 'package:jobline/routes/route_names.dart';

// UI에 필요한 댓글 + 게시글 제목 정보를 담는 임시 클래스
class MyCommentItem {
  final Comment comment;
  final String postId;
  final String postTitle;

  MyCommentItem(
      {required this.comment, required this.postId, required this.postTitle});
}

/// 내가 쓴 댓글 화면
class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({super.key});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  final _svc = BoardService();

  // FutureBuilder를 위한 Future 변수 (댓글 목록과 제목 로드를 한 번에 처리)
  late final Future<List<MyCommentItem>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _loadMyCommentsWithPostTitles();
  }

  // 날짜 포맷팅 헬퍼 함수
  String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  // 댓글 목록을 가져오고, 각 댓글의 게시글 제목을 추가로 가져오는 로직
  Future<List<MyCommentItem>> _loadMyCommentsWithPostTitles() async {
    // 1. 댓글 Stream을 단일 List<Comment> Future로 변환
    // (Stream의 첫 번째 이벤트만 기다린 후 종료)
    final List<Comment> comments = await _svc.watchMyComments().first;

    if (comments.isEmpty) return [];

    // 2. 필요한 모든 게시글 ID 목록 추출 (중복 제거)
    // Comment 모델에 postId 필드가 추가되어 있어야 작동합니다.
    final postIds = comments.map((c) => c.postId).toSet();

    // 3. 모든 게시글 제목을 동시에 가져오기 (Future.wait 사용)
    final Map<String, String> postTitles = {};

    // BoardService.getPostById를 사용하여 게시글 정보를 병렬로 가져옴
    final postFutures = postIds.map((id) => _svc.getPostById(id));
    final posts = await Future.wait(postFutures);

    for (var post in posts) {
      if (post != null) {
        postTitles[post.id] = post.title;
      }
    }

    // 4. Comment와 PostTitle을 결합하여 MyCommentItem 리스트 생성
    return comments.map((comment) {
      final postId = comment.postId;
      final postTitle = postTitles[postId] ?? '(원글 삭제됨 또는 찾을 수 없음)'; // 제목이 없으면 처리
      return MyCommentItem(
        comment: comment,
        postId: postId,
        postTitle: postTitle,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내가 쓴 댓글',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<MyCommentItem>>(
        future: _commentsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('댓글 로드 중 에러: ${snap.error}'));
          }

          final comments = snap.data ?? [];

          if (comments.isEmpty) {
            return const Center(
              child: Text('작성한 댓글이 없습니다.'),
            );
          }

          return ListView.separated(
            itemCount: comments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = comments[index];
              final comment = item.comment;
              // Comment 모델에 createdAt 필드가 DateTime 타입으로 있다고 가정합니다.
              final timeText = comment.createdAt != null ? _fmtDate(comment.createdAt) : '';

              return ListTile(
                title: Text(
                  item.postTitle, // 게시글 제목 표시
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      comment.content, // 댓글 내용 표시
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  // 해당 게시글 상세 화면으로 이동
                  Navigator.pushNamed(
                    context,
                    RouteNames.postDetail,
                    arguments: item.postId,
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