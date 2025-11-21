import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(String id, Map<String, dynamic> m) => Comment(
    id: id,
    postId: m['postId'] ?? '',
    authorId: m['authorId'] ?? '',
    content: m['content'] ?? '',
    createdAt: (m['createdAt'] is Timestamp)
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'authorId': authorId,
    'content': content,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
