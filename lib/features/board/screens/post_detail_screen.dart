import 'package:flutter/material.dart';

/// 게시글 상세 화면 (임시)
class PostDetailScreen extends StatelessWidget {
  final String? postId; // 게시글 ID (임시로 nullable)

  const PostDetailScreen({
    super.key,
    this.postId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: postId로 실제 게시글 데이터 가져오기
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 수정/삭제 메뉴
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 정보
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '작성자 이름',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '2024-01-15 10:30',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    // TODO: 좋아요 기능
                  },
                ),
              ],
            ),
            const Divider(),
            
            // 제목
            const Text(
              '게시글 제목',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 본문
            const Text(
              '게시글 내용이 여기에 표시됩니다.\n\n본문 내용...',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            // 첨부파일 (있는 경우)
            // TODO: 첨부파일 표시
            
            const Divider(),
            
            // 댓글 섹션
            const Text(
              '댓글 (0)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 댓글 입력창
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // TODO: 댓글 작성
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 댓글 목록
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  '댓글이 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

