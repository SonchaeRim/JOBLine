import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/route_names.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _roomTitleForMe(ChatRoom room, String myUid) {
    if (!room.isGroup) {
      for (final uid in room.memberIds) {
        if (uid != myUid) {
          final nick = room.memberNicknames[uid];
          if (nick is String && nick.isNotEmpty) return nick;
        }
      }
      return '채팅';
    }
    return room.title.isEmpty ? '그룹 채팅' : room.title;
  }

  String _roomPhotoForMe(ChatRoom room, String myUid) {
    if (!room.isGroup) {
      for (final uid in room.memberIds) {
        if (uid != myUid) {
          final url = room.memberPhotoUrls[uid];
          if (url is String && url.isNotEmpty) return url;
        }
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          IconButton(
            tooltip: '채팅방 만들기',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, RouteNames.newChat),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: chatService.watchMyRooms(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return const Center(child: Text('채팅방이 없습니다.\n오른쪽 위 + 로 채팅을 시작해보세요.'));
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
                  backgroundImage: photoUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(photoUrl),
                  child: photoUrl.isEmpty
                      ? Text(title.characters.first, style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  room.lastMessageAt == null ? '' : _formatTime(room.lastMessageAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                onTap: () {
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays >= 1) return '어제';
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? '오전' : '오후';
    final hh = (h % 12 == 0) ? 12 : (h % 12);
    return '$ampm ${hh.toString().padLeft(2, '0')}:$m';
  }
}
