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
    /// ✅ 시스템 메시지
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

    /// ===============================
    /// ✅ 메시지 콘텐츠 (텍스트 / 이미지)
    /// ===============================
    final Widget content;

    final imageUrl = message.imageUrl ?? '';
    if (message.type == 'image' && imageUrl.isNotEmpty) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 180,
            height: 180,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) =>
          const Text('이미지를 불러올 수 없어요'),
        ),
      );
    } else {
      // 기본 텍스트 메시지
      content = Text(
        message.text,
        style: TextStyle(color: textColor, height: 1.3),
      );
    }

    /// ===============================
    /// ✅ 말풍선
    /// ===============================
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: message.type == 'image'
          ? const EdgeInsets.all(6)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: message.type == 'image' ? Colors.transparent : bubbleColor,
        borderRadius: radius,
      ),
      child: content,
    );

    final time = Text(
      timeText,
      style: const TextStyle(fontSize: 11, color: Colors.black45),
    );

    /// ===============================
    /// ✅ 상대 메시지
    /// ===============================
    if (!fromMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 영역
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bubble,
                    const SizedBox(width: 6),
                    time,
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    /// ===============================
    /// ✅ 내 메시지
    /// ===============================
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              time,
              const SizedBox(width: 6),
              bubble,
            ],
          ),
        ],
      ),
    );
  }
}
