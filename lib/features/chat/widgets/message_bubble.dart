import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

/// 채팅 말풍선 위젯 (텍스트/이미지/시스템 메시지)
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool fromMe;

  /// 그룹 채팅에서 상대 이름 표시용
  final String senderName;

  /// 그룹 채팅에서 상대 프로필 이미지 표시용
  final String senderPhotoUrl;

  /// 같은 사람이 연속으로 보낼 때 정보(이름/프로필) 생략할지 여부
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
    // 시스템 메시지(가운데 회색 텍스트)
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

    // 메시지 시간(오전/오후 hh:mm)
    final timeText = DateFormat('a hh:mm', 'ko_KR').format(message.createdAt);

    // 내/상대 말풍선 색상
    final bubbleColor = fromMe ? const Color(0xFF4A83F3) : Colors.white;
    final textColor = fromMe ? Colors.white : Colors.black87;

    // 말풍선 모서리 라운드(내 메시지/상대 메시지 구분)
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: fromMe ? const Radius.circular(16) : const Radius.circular(6),
      bottomRight: fromMe ? const Radius.circular(6) : const Radius.circular(16),
    );

    /// 메시지 콘텐츠: image면 이미지, 아니면 텍스트
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
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => const Text('이미지를 불러올 수 없어요'),
        ),
      );
    } else {
      content = Text(
        message.text,
        style: TextStyle(color: textColor, height: 1.3),
      );
    }

    /// 말풍선 박스(최대 너비 제한)
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: message.type == 'image'
          ? const EdgeInsets.all(6)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // 이미지는 투명 배경(이미지 자체가 컨텐츠)
        color: message.type == 'image' ? Colors.transparent : bubbleColor,
        borderRadius: radius,
      ),
      child: content,
    );

    final time = Text(
      timeText,
      style: const TextStyle(fontSize: 11, color: Colors.black45),
    );

    /// 상대 메시지(왼쪽 정렬, 필요 시 프로필/이름 표시)
    if (!fromMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 영역(연속 메시지면 숨김)
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
                    time,
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    /// 내 메시지(오른쪽 정렬)
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
