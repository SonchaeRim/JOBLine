import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String type; // dm | group
  final String title; // group이면 사용, dm이면 비워도 됨
  final List<String> memberIds;
  final Map<String, dynamic> memberNicknames; // uid -> nickname
  final Map<String, dynamic> memberTags;      // uid -> tag(0000)
  final String lastMessage;
  final DateTime? lastMessageAt;

  ChatRoom({
    required this.id,
    required this.type,
    required this.title,
    required this.memberIds,
    required this.memberNicknames,
    required this.memberTags,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  bool get isGroup => type == 'group';

  factory ChatRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final ts = data['lastMessageAt'] as Timestamp?;

    return ChatRoom(
      id: doc.id,
      type: data['type'] as String? ?? 'dm',
      title: data['title'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      memberNicknames: Map<String, dynamic>.from(data['memberNicknames'] as Map? ?? {}),
      memberTags: Map<String, dynamic>.from(data['memberTags'] as Map? ?? {}),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: ts?.toDate(),
    );
  }
}
