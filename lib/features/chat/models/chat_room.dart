import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String type; // dm | group
  final String title;
  final List<String> memberIds;

  /// uid -> nickname
  final Map<String, dynamic> memberNicknames;

  /// uid -> tag(0000)
  final Map<String, dynamic> memberTags;

  /// uid -> profile image url
  final Map<String, dynamic> memberPhotoUrls;

  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  ChatRoom({
    required this.id,
    required this.type,
    required this.title,
    required this.memberIds,
    required this.memberNicknames,
    required this.memberTags,
    required this.memberPhotoUrls,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
  });

  bool get isGroup => type == 'group';

  factory ChatRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ChatRoom(
      id: doc.id,
      type: (data['type'] as String?) ?? 'dm',
      title: (data['title'] as String?) ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      memberNicknames: Map<String, dynamic>.from(data['memberNicknames'] as Map? ?? const {}),
      memberTags: Map<String, dynamic>.from(data['memberTags'] as Map? ?? const {}),
      memberPhotoUrls: Map<String, dynamic>.from(data['memberPhotoUrls'] as Map? ?? const {}),
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: _toDate(data['lastMessageAt']),
      createdAt: _toDate(data['createdAt']),
    );
  }
}
