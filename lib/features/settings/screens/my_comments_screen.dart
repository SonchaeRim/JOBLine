import 'package:flutter/material.dart';

/// 내가 쓴 댓글 화면 (임시)
class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 댓글 데이터 가져오기
    final List<Map<String, String>> comments = [
      {'content': '댓글 내용 1', 'postTitle': '게시글 제목 1', 'date': '2024-01-15'},
      {'content': '댓글 내용 2', 'postTitle': '게시글 제목 2', 'date': '2024-01-10'},
    ];

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
      body: comments.isEmpty
          ? const Center(
              child: Text('작성한 댓글이 없습니다.'),
            )
          : ListView.separated(
              itemCount: comments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  title: Text(
                    comment['postTitle'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        comment['content'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment['date'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: 해당 게시글 상세 화면으로 이동
                  },
                );
              },
            ),
    );
  }
}
