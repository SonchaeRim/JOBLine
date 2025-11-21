import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostListScreen extends StatelessWidget {
  final String boardId;
  final String title;
  const PostListScreen({super.key, required this.boardId, required this.title});

  Future<List<Map<String, dynamic>>> _fetch() async {
    final qs = await FirebaseFirestore.instance
        .collection('posts')
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .get();
    return qs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetch(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('에러: ${snap.error}'));
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('글이 없습니다.'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              return ListTile(
                title: Text(p['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(p['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  // TODO: post_detail_screen으로 이동
                  // Navigator.pushNamed(context, RouteNames.postDetail, arguments: p['id']);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: post_editor_screen으로 이동
        },
        label: const Text('✍️ 게시글 작성하기'),
      ),
    );
  }
}
