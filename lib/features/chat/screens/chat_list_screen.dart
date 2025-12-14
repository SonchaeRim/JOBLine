import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../routes/route_names.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

/// 내 채팅방 목록 화면
class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final ChatService _chatService = ChatService();

  /// 내 기준으로 방 제목 만들기
  /// - DM: 상대 닉네임
  /// - 그룹: 멤버 3명까지 보여주고 "외 n명"
  String _roomTitleForMe(ChatRoom room, String myUid) {
    final others = <String>[];

    for (final uid in room.memberIds) {
      if (uid == myUid) continue;
      final nick = room.memberNicknames[uid];
      if (nick != null && nick.trim().isNotEmpty) {
        others.add(nick.trim());
      }
    }

    if (others.isNotEmpty) {
      if (others.length <= 3) return others.join(', ');
      final shown = others.take(3).join(', ');
      return '$shown 외 ${others.length - 3}명';
    }

    return room.title.trim().isNotEmpty ? room.title.trim() : '채팅';
  }

  /// DM이면 상대 프로필 이미지를 썸네일로 사용
  String _roomPhotoForMe(ChatRoom room, String myUid) {
    if (!room.isGroup) {
      for (final uid in room.memberIds) {
        if (uid == myUid) continue;
        final url = room.memberPhotoUrls[uid];
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return '';
  }

  /// 목록에서 사용할 시간 표기(간단 버전)
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays >= 1) return '어제';
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? '오전' : '오후';
    final hh = (h % 12 == 0) ? 12 : (h % 12);
    return '$ampm ${hh.toString().padLeft(2, '0')}:$m';
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 목록'),
        actions: [
          IconButton(
            tooltip: '채팅방 만들기',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, RouteNames.newChat),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        // 내 uid가 포함된 방만 실시간 구독
        stream: _chatService.watchMyRooms(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return const Center(
              child: Text('채팅방이 없습니다.\n오른쪽 위 + 로 채팅을 시작해보세요.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final title = _roomTitleForMe(room, myUid);
              final last = room.lastMessage.isEmpty ? '대화를 시작해보세요' : room.lastMessage;
              final photoUrl = _roomPhotoForMe(room, myUid);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                  photoUrl.isEmpty ? null : CachedNetworkImageProvider(photoUrl),
                  child: photoUrl.isEmpty
                      ? Text(
                    title.characters.first,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  room.lastMessageAt == null ? '' : _formatTime(room.lastMessageAt!),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                onTap: () {
                  // 방 입장 화면으로 이동
                  Navigator.pushNamed(
                    context,
                    RouteNames.chatRoom,
                    arguments: ChatRoomScreenArgs(
                      roomId: room.id,
                      roomTitle: title,
                      isGroup: room.isGroup,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
