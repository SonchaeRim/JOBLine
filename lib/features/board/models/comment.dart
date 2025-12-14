import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;        // Firestore 문서 ID
  final String postId;    // 어떤 게시글(post)에 달린 댓글인지 (게시글 ID)
  final String authorId;  // 댓글 작성자 UID
  final String content;   // 댓글 내용
  final DateTime createdAt; // 작성 시간

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  // Firestore에서 가져온 Map 데이터를 Comment 객체로 변환
  factory Comment.fromMap(String id, Map<String, dynamic> m) => Comment(
    id: id,
    postId: m['postId'] ?? '',
    authorId: m['authorId'] ?? '',
    content: m['content'] ?? '',
    // createdAt이 Timestamp이면 DateTime으로 변환, 아니면 임시로 현재시간
    createdAt: (m['createdAt'] is Timestamp)
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );

  // Comment 객체를 Firestore에 저장할 Map 형태로 변환
  Map<String, dynamic> toMap() => {
    'postId': postId,
    'authorId': authorId,
    'content': content,
    // 서버 시간을 기준으로 createdAt 저장 (클라 시간 오차 방지)
    'createdAt': FieldValue.serverTimestamp(),
  };
}
