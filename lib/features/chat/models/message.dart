import 'package:cloud_firestore/cloud_firestore.dart';

/// 채팅 메시지 모델
/// chat_rooms/{roomId}/messages/{messageId}
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;

  /// text | image | system
  final String type;

  /// text 타입 메시지 내용(이미지일 땐 보통 '')
  final String text;

  /// image 타입일 때 이미지 URL
  final String? imageUrl;

  /// 메시지 생성 시간
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.createdAt,
    this.imageUrl,
  });

  /// Firestore 문서 -> ChatMessage 변환
  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = (data['createdAt'] as Timestamp?) ?? Timestamp.now();

    return ChatMessage(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: ts.toDate(),
    );
  }

  /// 텍스트 메시지 전송용 map
  Map<String, dynamic> toTextMap() => {
    'roomId': roomId,
    'senderId': senderId,
    'type': 'text',
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// 이미지 메시지 전송용 map
  Map<String, dynamic> toImageMap() => {
    'roomId': roomId,
    'senderId': senderId,
    'type': 'image',
    'text': '',
    'imageUrl': imageUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// 시스템 메시지(입장/생성/나가기 등)용 map
  static Map<String, dynamic> systemMap({
    required String roomId,
    required String text,
  }) =>
      {
        'roomId': roomId,
        'senderId': 'system',
        'type': 'system',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
