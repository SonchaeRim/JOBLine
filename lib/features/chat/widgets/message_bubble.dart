import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool fromMe;
  final String senderName;
  final String senderPhotoUrl;
  final bool showSenderInfo;

  const MessageBubble({
    super.key,
    required this.message,
    required this.fromMe,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.showSenderInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      );
    }

    final timeText = DateFormat('a hh:mm', 'ko_KR').format(message.createdAt);

    final bubbleColor = fromMe ? const Color(0xFF4A83F3) : Colors.white;
    final textColor = fromMe ? Colors.white : Colors.black87;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: fromMe ? const Radius.circular(16) : const Radius.circular(6),
      bottomRight: fromMe ? const Radius.circular(6) : const Radius.circular(16),
    );

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: radius,
      ),
      child: Text(
        message.text,
        style: TextStyle(color: textColor, height: 1.3),
      ),
    );

    final time = Text(
      timeText,
      style: const TextStyle(fontSize: 11, color: Colors.black45),
    );

    // ✅ 상대 메시지
    if (!fromMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 자리 (연속 메시지 정렬 유지용)
            SizedBox(
              width: 40,
              child: showSenderInfo
                  ? CircleAvatar(
                radius: 16,
                backgroundImage: senderPhotoUrl.isEmpty
                    ? null
                    : CachedNetworkImageProvider(senderPhotoUrl),
                child: senderPhotoUrl.isEmpty
                    ? Text(senderName.characters.first)
                    : null,
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSenderInfo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bubble,
                    const SizedBox(width: 6),
                    time, // ⭕ 말풍선 옆
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ✅ 내 메시지
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              time, // ⭕ 말풍선 옆
              const SizedBox(width: 6),
              bubble,
            ],
          ),
        ],
      ),
    );
  }
}
