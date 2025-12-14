import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PostEditorScreen extends StatefulWidget {
  final String boardId;    // 어떤 게시판에 글을 쓰는지
  final String? postId;    // 수정용으로 쓸 수 있게 남겨둔 값(현재는 새 글만)

  const PostEditorScreen({
    super.key,
    required this.boardId,
    this.postId,
  });

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final TextEditingController _titleController = TextEditingController();   // 제목 입력
  final TextEditingController _contentController = TextEditingController(); // 내용 입력

  final _picker = ImagePicker(); // 갤러리 이미지 선택기
  final List<XFile> _images = []; // 선택된 이미지 목록
  bool _saving = false; // 저장/업로드 중 상태

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 갤러리에서 여러 장 이미지 선택
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85); // 이미지 압축(선택)
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked); // 선택된 이미지 추가
    });
  }

  // 선택된 이미지 1장 제거
  void _removeImage(int idx) {
    setState(() {
      _images.removeAt(idx);
    });
  }

  // 선택된 이미지들을 Firebase Storage에 올리고, 다운로드 URL 리스트 반환
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

      // 파일명 충돌 방지용 이름 생성
      final ext = x.name.contains('.') ? x.name.split('.').last : 'jpg';
      final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

      // Storage 경로: posts/{postId}/{uid}/{filename}
      final ref = storage.ref().child('posts/$postId/$uid/$filename');

      // 업로드
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );

      // 다운로드 URL 저장
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // 게시글 저장(이미지 업로드 포함)
  Future<void> _save() async {
    if (_saving) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 제목/내용 검증
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해 주세요.')),
      );
      return;
    }

    // 로그인 체크
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // users/{uid}에서 커뮤니티/닉네임 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw '유저 정보가 없습니다.';
      }

      final u = userDoc.data() as Map<String, dynamic>;

      // 메인 커뮤니티 확인
      final communityId = (u['mainCommunityId'] ?? '').toString().trim();
      if (communityId.isEmpty) {
        throw '메인 커뮤니티가 설정되지 않았습니다.';
      }

      // 작성자 이름(닉네임 우선, 없으면 name, 없으면 익명)
      String authorName = '익명';
      final nick = u['nickname'];
      final name = u['name'];
      final v = (nick ?? name);
      if (v != null && v.toString().trim().isNotEmpty) {
        authorName = v.toString().trim();
      }

      // 새 게시글 문서 생성(문서 ID를 이미지 경로에 쓰기 위해 먼저 생성)
      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      final postId = postRef.id;

      // 이미지 업로드 후 URL 리스트 얻기
      final imageUrls = await _uploadImages(postId: postId, uid: user.uid);

      // 게시글 문서 저장
      await postRef.set({
        'communityId': communityId,
        'boardId': widget.boardId,
        'title': title,
        'content': content,

        'createdAt': FieldValue.serverTimestamp(),
        'authorId': user.uid,
        'authorName': authorName,

        // 카운트 초기값
        'likeCount': 0,
        'commentCount': 0,

        // 이미지 URL 리스트
        'imageUrls': imageUrls,
      });

      // 성공 시 이전 화면으로 true 반환
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
          onPressed: () => Navigator.pop(context), // 작성 취소/닫기
        ),
        title: const Text('게시글 작성'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save, // 저장
            child: Text(
              _saving ? '저장중...' : '완료',
              style: const TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),

      // 본문 입력 영역
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

            // 선택한 이미지 미리보기(가로 스크롤)
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
                            onTap: () => _removeImage(i), // 이미지 삭제
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

      // 하단 업로드 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save, // 업로드 실행
              child: Text(_saving ? '업로드 중...' : '게시글 업로드'),
            ),
          ),
        ),
      ),
    );
  }
}
