import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleLike(DocumentReference<Map<String, dynamic>> postRef) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final likeRef = postRef.collection('likes').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final likeSnap = await tx.get(likeRef);

      final data = postSnap.data() ?? {};
      final raw = data['likeCount'];
      final likeCount = raw is int ? raw : 0;

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': likeCount > 0 ? likeCount - 1 : 0});
      } else {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'likeCount': likeCount + 1});
      }
    });
  }

  Future<void> _submitComment(DocumentReference<Map<String, dynamic>> postRef) async {
    if (_sending) return;

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      String authorName = '익명';
      String? authorId;

      if (user != null) {
        authorId = user.uid;

        final profileSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (profileSnap.exists && profileSnap.data() != null) {
          final profile = profileSnap.data()!;
          final v = profile['nickname'] ?? profile['name'];
          if (v != null && v.toString().trim().isNotEmpty) {
            authorName = v.toString().trim();
          }
        }
      }

      final newCommentRef = postRef.collection('comments').doc();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.set(newCommentRef, {
          'content': text,
          'createdAt': FieldValue.serverTimestamp(),
          'authorId': authorId,
          'authorName': authorName,
        });

        tx.update(postRef, {
          'commentCount': FieldValue.increment(1),
        });
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 저장 중 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openMoreMenu(DocumentReference<Map<String, dynamic>> postRef) async {
    final me = FirebaseAuth.instance.currentUser;

    final snap = await postRef.get();
    if (!snap.exists || snap.data() == null) return;

    final data = snap.data()!;
    final authorId = (data['authorId'] ?? '').toString();
    final isMine = (me != null && me.uid == authorId);

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('게시글 삭제'),
                  onTap: () => Navigator.pop(context, 'delete'),
                )
              else
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('내 글만 삭제할 수 있어요'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('정말 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (ok == true) {
        await _deletePost(postRef);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _deletePost(DocumentReference<Map<String, dynamic>> postRef) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      final snap = await postRef.get();
      if (!snap.exists || snap.data() == null) return;

      final data = snap.data()!;
      final authorId = (data['authorId'] ?? '').toString();

      if (authorId != me.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내 글만 삭제할 수 있어요.')),
        );
        return;
      }

      final rawImgs = data['imageUrls'];
      if (rawImgs is List) {
        for (final u in rawImgs) {
          final url = u.toString();
          if (url.isEmpty) continue;
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (_) {}
        }
      }

      final likesSnap = await postRef.collection('likes').get();
      final commentsSnap = await postRef.collection('comments').get();

      final batch = FirebaseFirestore.instance.batch();
      for (final d in likesSnap.docs) {
        batch.delete(d.reference);
      }
      for (final d in commentsSnap.docs) {
        batch.delete(d.reference);
      }
      batch.delete(postRef);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.postId;
    if (postId == null) {
      return const Scaffold(
        body: Center(child: Text('잘못된 게시글입니다.')),
      );
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final me = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _openMoreMenu(postRef),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x11000000))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요.',
                    filled: true,
                    fillColor: const Color(0xFFF2F3F5),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_sending ? Icons.hourglass_top : Icons.send),
                onPressed: _sending ? null : () => _submitComment(postRef),
              ),
            ],
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: postRef.snapshots(),
        builder: (context, postSnap) {
          if (postSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!postSnap.hasData || !postSnap.data!.exists) {
            return const Center(child: Text('삭제되었거나 없는 게시글입니다.'));
          }

          final data = postSnap.data!.data()!;
          final title = (data['title'] ?? '').toString();
          final content = (data['content'] ?? '').toString();
          final authorName = (data['authorName'] ?? '익명').toString();
          final createdText = _fmtTs(data['createdAt'] as Timestamp?);

          final rawLike = data['likeCount'];
          final likeCount = rawLike is int ? rawLike : 0;

          // ----- 이미지 URL들 꺼내기---------
          final rawImgs = data['imageUrls'];
          final imageUrls = (rawImgs is List)
              ? rawImgs
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
              : <String>[];

          final likeDocStream = (me == null)
              ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
              : postRef.collection('likes').doc(me.uid).snapshots();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: postRef
                .collection('comments')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, commentSnap) {
              final docs = commentSnap.data?.docs ?? [];
              final commentCount = docs.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 작성자 헤더
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.person, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                createdText.isEmpty ? '작성 시간 불러오는 중...' : createdText,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 제목/본문
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      content,
                      style: const TextStyle(fontSize: 16, height: 1.55),
                    ),

                    // ---------사진 섹션 --------
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final url = imageUrls[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, err, st) {
                                    return Container(
                                      width: 260,
                                      color: const Color(0xFFF2F3F5),
                                      alignment: Alignment.center,
                                      child: const Text('이미지 로드 실패'),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),

                    // ------ 공감/댓글수 바 -----------
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: likeDocStream,
                            builder: (context, likeSnap) {
                              final isLiked =
                                  (me != null) && (likeSnap.data?.exists ?? false);

                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _toggleLike(postRef),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        size: 20,
                                        color: isLiked ? Colors.red : Colors.black87,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '공감 $likeCount',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '댓글 $commentCount',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),
                    const SizedBox(height: 10),

                    // ---------- 댓글 리스트 ----------
                    if (commentSnap.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final c = docs[i].data();
                          final cText = (c['content'] ?? '').toString();
                          final cAuthor = (c['authorName'] ?? '익명').toString();
                          final cTime = _fmtTs(c['createdAt'] as Timestamp?);

                          return Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      cAuthor,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cTime,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cText,
                                  style: const TextStyle(fontSize: 15, height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
