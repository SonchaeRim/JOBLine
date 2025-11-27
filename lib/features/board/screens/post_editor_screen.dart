import 'package:flutter/material.dart';

/// 게시글 작성/수정 화면 (임시)
class PostEditorScreen extends StatelessWidget {
  final String? postId; // 수정 시 게시글 ID (null이면 새 글 작성)

  const PostEditorScreen({
    super.key,
    this.postId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEditing = postId != null;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? '게시글 수정' : '게시글 작성'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 저장 로직
              Navigator.pop(context);
            },
            child: const Text(
              '완료',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력
            const Text(
              '제목',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            
            // 본문 입력
            const Text(
              '내용',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 15,
            ),
            const SizedBox(height: 24),
            
            // 첨부파일 버튼
            OutlinedButton.icon(
              onPressed: () {
                // TODO: 파일 첨부 기능
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('첨부파일 추가'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

