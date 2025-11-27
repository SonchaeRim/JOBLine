import 'package:flutter/material.dart';

/// 내가 쓴 게시물 화면 (임시)
class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 게시물 데이터 가져오기
    final List<Map<String, String>> posts = [
      {'title': '게시글 제목 1', 'content': '게시글 내용...', 'date': '2024-01-15'},
      {'title': '게시글 제목 2', 'content': '게시글 내용...', 'date': '2024-01-10'},
    ];

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
      body: posts.isEmpty
          ? const Center(
              child: Text('작성한 게시물이 없습니다.'),
            )
          : ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(
                    post['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        post['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['date'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: 게시글 상세 화면으로 이동
                  },
                );
              },
            ),
    );
  }
}
