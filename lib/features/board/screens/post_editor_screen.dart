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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ✅ 현재 로그인 유저의 mainCommunityId 가져오기
  Future<String?> _getMyMainCommunityId(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data() as Map<String, dynamic>;
    final v = data['mainCommunityId'];

    if (v == null) return null;
    final id = v.toString();
    if (id.isEmpty) return null;

    return id;
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // ✅ users/{uid} 한 번만 읽어서 communityId + authorName 같이 얻기
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists || userDoc.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유저 정보가 없습니다.')),
      );
      return;
    }

    final u = userDoc.data() as Map<String, dynamic>;

    final communityId = (u['mainCommunityId'] ?? '').toString().trim();
    if (communityId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메인 커뮤니티가 설정되지 않았습니다.')),
      );
      return;
    }

    // ✅ 닉네임 우선 → 없으면 name → 없으면 익명
    String authorName = '익명';
    final nick = u['nickname'];
    final name = u['name'];
    final v = (nick ?? name);
    if (v != null && v.toString().trim().isNotEmpty) {
      authorName = v.toString().trim();
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'communityId': communityId,
      'boardId': widget.boardId,
      'title': title,
      'content': content,

      // ㅅ필드 3종 세트
      'createdAt': FieldValue.serverTimestamp(),
      'authorId': user.uid,
      'authorName': authorName,
    });

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
