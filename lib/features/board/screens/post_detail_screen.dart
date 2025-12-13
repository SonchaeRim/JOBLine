import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String? postId;

  const PostDetailScreen({
    super.key,
    this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    print('▶ _submitComment pressed');

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력해 주세요.')),
      );
      return;
    }
    if (widget.postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잘못된 게시글입니다.')),
      );
      return;
    }

    try {
      final postId = widget.postId!;
      final user = FirebaseAuth.instance.currentUser;

      // -------- 기본값 -----------
      String authorName = '익명';
      String? authorId;

      if (user != null) {
        authorId = user.uid;

        // --------  users 컬렉션에서 내 프로필 가져오기  ------------
        final profileSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (profileSnap.exists) {
          final profile = profileSnap.data()!;
          // nickname 우선, 없으면 name, 둘 다 없으면 익명
          authorName = (profile['nickname'] ?? profile['name'] ?? '익명') as String;
        }
      }

      // ----------------  댓글 저장할 때 author 정보 같이 넣기 ---------------
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': text,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': authorId,      // uid
        'authorName': authorName,  // users 컬렉션에서 가져온 닉네임
      });

      print('✅ comment saved');
      _commentController.clear();
    } catch (e) {
      print('🔥 comment save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 저장 중 오류: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.postId == null) {
      return const Scaffold(
        body: Center(child: Text('잘못된 게시글입니다.')),
      );
    }

    final postDocRef =
    FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: postDocRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('삭제되었거나 없는 게시글입니다.'));
          }

          final data = snapshot.data!.data()!;
          final title = data['title'] ?? '';
          final content = data['content'] ?? '';
          final authorName = (data['authorName'] ?? '익명').toString();

          final ts = data['createdAt'] as Timestamp?;
          String timeText = '';
          if (ts != null) {
            final dt = ts.toDate();
            timeText =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          }



          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 섹션 (임시)
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeText.isEmpty ? '작성 시간 불러오는 중...' : timeText,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    ),
                  ],
                ),
                const Divider(),

                // 제목
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 본문
                Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),

                const Divider(),

                const Text(
                  '댓글',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 댓글 입력
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitComment, //
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 댓글 목록
                // 댓글 목록
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: postDocRef
                      .collection('comments')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, commentSnap) {
                    if (commentSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final docs = commentSnap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            '첫 댓글을 남겨보세요!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = docs[i].data();

                        final text = c['content'] ?? '';
                        final authorName = c['authorName'] ?? '익명';

                        final ts = c['createdAt'] as Timestamp?;
                        String timeText = '';
                        if (ts != null) {
                          final dt = ts.toDate();
                          timeText =
                          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                        }

                        return ListTile(
                          title: Text(text),                       // 댓글 내용
                          subtitle: Text('$authorName · $timeText'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
