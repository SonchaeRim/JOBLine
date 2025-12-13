import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/comment.dart';

class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  // posts/{postId}/comments
  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) =>
      _posts.doc(postId).collection('comments');


  /// [목록 조회 - 1회성]
  Future<List<Post>> fetchPosts(
      String boardId, {
        String? communityId,
        int limit = 20,
      }) async {
    Query<Map<String, dynamic>> q = _posts.where('boardId', isEqualTo: boardId);

    if (communityId != null && communityId.trim().isNotEmpty) {
      q = q.where('communityId', isEqualTo: communityId.trim());
    }

    q = q.orderBy('createdAt', descending: true).limit(limit);

    final snap = await q.get();
    return snap.docs.map((d) => Post.fromMap(d.id, d.data())).toList();
  }

  /// [목록 조회 - 실시간]
  Stream<List<Post>> watchPosts(
      String boardId, {
        String? communityId,
        int limit = 50,
      }) {
    Query<Map<String, dynamic>> q = _posts.where('boardId', isEqualTo: boardId);

    if (communityId != null && communityId.trim().isNotEmpty) {
      q = q.where('communityId', isEqualTo: communityId.trim());
    }

    q = q.orderBy('createdAt', descending: true).limit(limit);

    return q.snapshots().map(
          (s) => s.docs.map((d) => Post.fromMap(d.id, d.data())).toList(),
    );
  }

  /// [상세 조회 - 1회성]
  Future<Post?> getPostById(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists || doc.data() == null) return null;
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
    });
  }

  /// [삭제]
  Future<void> deletePost(String postId) => _posts.doc(postId).delete();


  ///댓글 실시간 구독 (posts/{postId}/comments)
  Stream<List<Comment>> watchComments(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Comment.fromMap(d.id, d.data())).toList());
  }

  /// 댓글 작성 + posts/{postId}.commentCount 자동 +1
  Future<void> addComment({
    required String postId,
    required String? authorId,
    required String authorName,
    required String content,
  }) async {
    final postRef = _posts.doc(postId);
    final newCommentRef = _commentsRef(postId).doc();

    await _db.runTransaction((tx) async {
      tx.set(newCommentRef, {
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': authorId,
        'authorName': authorName,
      });

      tx.update(postRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }

  /// 댓글 삭제 + posts/{postId}.commentCount 자동 -1
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final postRef = _posts.doc(postId);
    final commentRef = _commentsRef(postId).doc(commentId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(commentRef);
      if (!snap.exists) return;

      tx.delete(commentRef);
      tx.update(postRef, {
        'commentCount': FieldValue.increment(-1),
      });
    });
  }
}
