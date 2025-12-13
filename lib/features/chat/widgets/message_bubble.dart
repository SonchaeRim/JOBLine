import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool fromMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.fromMe,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 시스템 메시지
    if (message.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: fromMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: fromMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    final timeText = DateFormat('a hh:mm', 'ko_KR').format(message.createdAt);

    final bubbleColor = fromMe ? Colors.blue[400] : Colors.grey[200];
    final textColor = fromMe ? Colors.white : Colors.black87;

    Widget content;
    if (message.type == 'image' && (message.imageUrl ?? '').isNotEmpty) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: message.imageUrl!,
          width: 210,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 210,
            height: 140,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 210,
            height: 140,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    } else {
      content = Text(message.text, style: TextStyle(color: textColor));
    }

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromMe) ...[
              Text(timeText, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              const SizedBox(width: 6),
            ],
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: message.type == 'image' ? 6 : 12,
                vertical: message.type == 'image' ? 6 : 8,
              ),
              decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
              child: content,
            ),
            if (fromMe) ...[
              const SizedBox(width: 6),
              Text(timeText, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ],
        ),
      ),
    );
  }
}
