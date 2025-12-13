import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/comment.dart';

class BoardService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');
  CollectionReference<Map<String, dynamic>> get _comments =>
      _db.collection('comments');

  /// [목록 조회] 게시판별 최신순 (communityId 필터는 옵션)
  Future<List<Post>> fetchPosts(
      String boardId, {
        String? communityId,
        int limit = 20,
      }) async {
    Query<Map<String, dynamic>> q = _posts.where('boardId', isEqualTo: boardId);

    if (communityId != null && communityId.isNotEmpty) {
      q = q.where('communityId', isEqualTo: communityId);
    }

    q = q.orderBy('createdAt', descending: true);

    final snap = await q.limit(limit).get();
    return snap.docs.map((d) => Post.fromMap(d.id, d.data())).toList();
  }


  /// [상세 조회]
  Future<Post?> getPostById(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromMap(doc.id, doc.data()!);
  }

  /// [작성]
  Future<String> createPost(Post post) async {
    final ref = await _posts.add(post.toMap());
    return ref.id;
  }

  /// [수정]
  Future<void> updatePost(Post post) async {
    await _posts.doc(post.id).update({
      'title': post.title,
      'content': post.content,
      // createdAt은 그대로 둠
    });
  }

  /// [삭제]
  Future<void> deletePost(String postId) => _posts.doc(postId).delete();

  // ===== 댓글 =====

  /// 댓글 실시간 구독
  Stream<List<Comment>> watchComments(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Comment.fromMap(d.id, d.data())).toList());
  }

  /// 댓글 작성
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) {
    return _comments.add({
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 댓글 삭제
  Future<void> deleteComment(String commentId) =>
      _comments.doc(commentId).delete();
}
