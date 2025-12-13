import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String boardId;      // 'free' | 'study' | 'job' | 'review' | 'spec'
  final String title;
  final String content;

  final String authorId;     // 작성자 uid
  final String authorName;   // 작성자 닉네임/이름

  final String communityId;  // 유저의 mainCommunityId
  final DateTime createdAt;

  final int likeCount;       // 좋아요 수
  final int commentCount;    // 댓글 수

  final List<String> imageUrls; //  이미지 URL들(없으면 빈 리스트)

  Post({
    required this.id,
    required this.boardId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.communityId,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.imageUrls,
  });

  factory Post.fromMap(String id, Map<String, dynamic> m) {
    // imageUrls 안전 변환
    final rawImgs = m['imageUrls'];
    final imgs = (rawImgs is List)
        ? rawImgs.map((e) => e.toString()).toList()
        : <String>[];

    return Post(
      id: id,
      boardId: (m['boardId'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      content: (m['content'] ?? '').toString(),
      authorId: (m['authorId'] ?? '').toString(),
      authorName: (m['authorName'] ?? '익명').toString(),
      communityId: (m['communityId'] ?? '').toString(),
      createdAt: (m['createdAt'] is Timestamp)
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likeCount: (m['likeCount'] is int) ? m['likeCount'] as int : 0,
      commentCount: (m['commentCount'] is int) ? m['commentCount'] as int : 0,
      imageUrls: imgs,
    );
  }

  Map<String, dynamic> toMap() => {
    'boardId': boardId,
    'title': title,
    'content': content,
    'authorId': authorId,
    'authorName': authorName,
    'communityId': communityId,
    // createdAt은 서버에서
    'createdAt': FieldValue.serverTimestamp(),

    'likeCount': likeCount,
    'commentCount': commentCount,
    'imageUrls': imageUrls,
  };

  Post copyWith({String? title, String? content}) => Post(
    id: id,
    boardId: boardId,
    title: title ?? this.title,
    content: content ?? this.content,
    authorId: authorId,
    authorName: authorName,
    communityId: communityId,
    createdAt: createdAt,
    likeCount: likeCount,
    commentCount: commentCount,
    imageUrls: imageUrls,
  );
}
