import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PostEditorScreen extends StatefulWidget {
  final String boardId;
  final String? postId; // 지금은 새 글만

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

  final _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // 여러 장 선택 (갤러리)
    final picked = await _picker.pickMultiImage(imageQuality: 85); // 압축(선택)
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked);
    });
  }

  void _removeImage(int idx) {
    setState(() {
      _images.removeAt(idx);
    });
  }

  Future<List<String>> _uploadImages({
    required String postId,
    required String uid,
  }) async {
    if (_images.isEmpty) return [];

    final storage = FirebaseStorage.instance;
    final urls = <String>[];

    for (int i = 0; i < _images.length; i++) {
      final x = _images[i];
      final file = File(x.path);

      // 파일명 충돌 방지용
      final ext = x.name.contains('.') ? x.name.split('.').last : 'jpg';
      final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

      final ref = storage.ref().child('posts/$postId/$uid/$filename');

      // 업로드
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );

      // 다운로드 URL
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> _save() async {
    if (_saving) return;

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

    setState(() => _saving = true);

    try {
      // users/{uid}에서 communityId + authorName
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw '유저 정보가 없습니다.';
      }

      final u = userDoc.data() as Map<String, dynamic>;

      final communityId = (u['mainCommunityId'] ?? '').toString().trim();
      if (communityId.isEmpty) {
        throw '메인 커뮤니티가 설정되지 않았습니다.';
      }

      String authorName = '익명';
      final nick = u['nickname'];
      final name = u['name'];
      final v = (nick ?? name);
      if (v != null && v.toString().trim().isNotEmpty) {
        authorName = v.toString().trim();
      }

      // postId를 먼저 확정(이미지 업로드 경로에 필요)
      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      final postId = postRef.id;

      // 이미지 업로드 후 URL 리스트 얻기
      final imageUrls = await _uploadImages(postId: postId, uid: user.uid);

      // posts 문서 저장
      await postRef.set({
        'communityId': communityId,
        'boardId': widget.boardId,
        'title': title,
        'content': content,

        'createdAt': FieldValue.serverTimestamp(),
        'authorId': user.uid,
        'authorName': authorName,

        //카운트
        'likeCount': 0,
        'commentCount': 0,

        //  이미지 URL 리스트
        'imageUrls': imageUrls,
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? '저장중...' : '완료',
              style: const TextStyle(color: Colors.blue, fontSize: 16),
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
              maxLines: 12,
            ),

            const SizedBox(height: 16),

            // 사진 선택 버튼
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image_outlined),
                  label: Text('사진 선택 (${_images.length})'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 미리보기
            if (_images.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final x = _images[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(x.path),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '업로드 중...' : '게시글 업로드'),
            ),
          ),
        ),
      ),
    );
  }
}
