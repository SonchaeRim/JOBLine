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

  // Future를 상태로 들고 있으면 setState로 쉽게 새로고침 가능
  late Future<List<Post>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.fetchPosts(
      widget.boardId,
      communityId: widget.communityId,
      limit: 50,
    );
  }

  // 커뮤니티가 바뀌거나 boardId가 바뀌면 다시 로드
  @override
  void didUpdateWidget(covariant PostListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed =
        oldWidget.boardId != widget.boardId ||
            oldWidget.communityId != widget.communityId;

    if (changed) {
      _future = _svc.fetchPosts(
        widget.boardId,
        communityId: widget.communityId,
        limit: 50,
      );
      setState(() {});
    }
  }

  void _reload() {
    _future = _svc.fetchPosts(
      widget.boardId,
      communityId: widget.communityId,
      limit: 50,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(widget.title)),
      body: FutureBuilder<List<Post>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('에러: ${snap.error}'));
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('글이 없습니다.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              return ListTile(
                title: Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  p.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('댓글 ${p.commentCount}개'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.pushNamed(
            context,
            RouteNames.postEditor,
            arguments: {
              'boardId': widget.boardId,
              'postId': null,
            },
          );

          // 글 작성 후 true로 pop하면 목록 새로고침
          if (changed == true) {
            _reload();
          }
        },
        label: const Text('✍️ 게시글 작성하기'),
      ),
    );
  }
}
