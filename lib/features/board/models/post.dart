import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String boardId;      // 'free' | 'study' | 'job' | 'review' | 'spec'
  final String title;
  final String content;
  final String authorId;     // 작성자 uid
  final String communityId;  // 유저의 mainCommunityId
  final DateTime createdAt;

  Post({
    required this.id,
    required this.boardId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.communityId,
    required this.createdAt,
  });

  factory Post.fromMap(String id, Map<String, dynamic> m) => Post(
    id: id,
    boardId: m['boardId'] ?? '',
    title: m['title'] ?? '',
    content: m['content'] ?? '',
    authorId: m['authorId'] ?? '',
    communityId: m['communityId'] ?? '',
    createdAt: (m['createdAt'] is Timestamp)
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'boardId': boardId,
    'title': title,
    'content': content,
    'authorId': authorId,
    'communityId': communityId,
    'createdAt': FieldValue.serverTimestamp(), // 서버 시간이 들어감(정렬용)
  };

  Post copyWith({String? title, String? content}) => Post(
    id: id,
    boardId: boardId,
    title: title ?? this.title,
    content: content ?? this.content,
    authorId: authorId,
    communityId: communityId,
    createdAt: createdAt,
  );
}
