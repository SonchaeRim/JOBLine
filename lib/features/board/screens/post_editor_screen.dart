import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostEditorScreen extends StatefulWidget {
  final String boardId;   // 어떤 게시판인지 (free, spec, ...)
  final String? postId;   // 수정 시 사용 (지금은 새 글만)

  const PostEditorScreen({
    super.key,
    required this.boardId,
    this.postId,
  });

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  // 제목/내용 입력창 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 글 저장
  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해 주세요.')),
      );
      return;
    }

    // 현재 로그인한 유저 (없으면 null)
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('posts').add({
      'boardId': widget.boardId,
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'authorId': user?.uid,                    // 권한 체크용
      'authorName': user?.displayName ?? '익명', // 나중에 닉네임/프로필 연동
    });

    // true를 리턴 값처럼 넘기고 이전 화면으로 돌아감
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('게시글 작성'),
        actions: [
          TextButton(
            onPressed: _save,
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
            const Text('제목', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            const Text('내용', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 15,
            ),
          ],
        ),
      ),
    );
  }
}
