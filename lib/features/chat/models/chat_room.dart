import 'package:cloud_firestore/cloud_firestore.dart';

/// 채팅방(rooms) 문서 모델
/// chat_rooms/{roomId}
class ChatRoom {
  final String id;

  /// dm | group
  final String type;

  /// 그룹 채팅 제목(없을 수도 있음)
  final String title;

  /// 참여자 uid 목록
  final List<String> memberIds;

  /// uid -> nickname
  final Map<String, String> memberNicknames;

  /// uid -> tag(0000)
  final Map<String, String> memberTags;

  /// uid -> profile image url
  final Map<String, String> memberPhotoUrls;

  /// 마지막 메시지 프리뷰(텍스트 or "📷 사진" 등)
  final String lastMessage;

  /// 마지막 메시지 시간
  final DateTime? lastMessageAt;

  /// 방 생성 시간
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

  /// Firestore 문서 -> ChatRoom 변환
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

      // map 필드는 null/타입 꼬임 방지 위해 기본값 처리
      memberNicknames: Map<String, String>.from(
        (data['memberNicknames'] as Map?) ?? const {},
      ),
      memberTags: Map<String, String>.from(
        (data['memberTags'] as Map?) ?? const {},
      ),
      memberPhotoUrls: Map<String, String>.from(
        (data['memberPhotoUrls'] as Map?) ?? const {},
      ),

      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: _toDate(data['lastMessageAt']),
      createdAt: _toDate(data['createdAt']),
    );
  }
}
