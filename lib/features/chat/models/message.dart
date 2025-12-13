import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;

  /// text | image | system
  final String type;

  final String text;
  final String? imageUrl;
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

  Map<String, dynamic> toTextMap() => {
    'roomId': roomId,
    'senderId': senderId,
    'type': 'text',
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toImageMap() => {
    'roomId': roomId,
    'senderId': senderId,
    'type': 'image',
    'text': '',
    'imageUrl': imageUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };

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
