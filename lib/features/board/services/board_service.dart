import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';

class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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

  // 현재 로그인된 사용자가 작성한 게시물 가져옴
  Stream<List<Post>> watchMyPosts({int limit = 50}) {
    // 1. 현재 사용자 ID 가져오기
    final uid = _auth.currentUser?.uid;

    // 로그인 정보가 없으면 빈 목록 Stream 반환
    if (uid == null) {
      return Stream.value([]);
    }

    // 2. Firestore 쿼리 구성
    // 'authorId' 필드가 현재 사용자의 uid와 일치하는 문서 필터링
    Query<Map<String, dynamic>> q = _posts
        .where('authorId', isEqualTo: uid) // 사용자 ID로 필터링
        .orderBy('createdAt', descending: true) // 최신 글 순서
        .limit(limit);

    // 3. 쿼리 결과 Stream 반환
    return q.snapshots().map(
          (s) => s.docs.map((d) => Post.fromMap(d.id, d.data())).toList(),
    );
  }

  // 현재 로그인된 사용자가 작성한 댓글 가져옴
  Stream<List<Comment>> watchMyComments({int limit = 50}) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream.value([]);
    }

    // Collection Group Query를 사용하여 모든 post의 comments 서브컬렉션에서 검색
    Query<Map<String, dynamic>> q = _db
        .collectionGroup('comments') // 'comments' 이름의 모든 컬렉션을 검색
        .where('authorId', isEqualTo: uid) // 현재 사용자 ID로 필터링
        .orderBy('createdAt', descending: true) // 최신 댓글 순서
        .limit(limit);

    return q.snapshots().map(
          (s) => s.docs.map((d) {
        // 문서 참조 경로에서 부모인 게시글 ID(postId)를 추출
        final postId = d.reference.parent.parent?.id ?? 'Unknown';

        // Comment.fromMap 호출 시 postId를 포함시켜 모델에서 사용할 수 있도록 전달
        // (Comment 모델이 postId를 필드로 받도록 수정 필요)
        return Comment.fromMap(d.id, {...d.data(), 'postId': postId});
      }).toList(),
    );
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
