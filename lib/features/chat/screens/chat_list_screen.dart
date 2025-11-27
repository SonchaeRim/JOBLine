import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import 'chat_room_screen.dart';
import 'new_chat_screen.dart'; // (혹시 필요하면)

/// 채팅방 리스트 화면
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 나중에 Firestore/ChatService 에서 채팅방 목록 받아오도록 교체
    final dummyRooms = [
      _ChatRoomItem(
        roomId: 'room1',
        title: '신태규',
        lastMessage: '과제 해야지',
        time: '오전 09:32',
        isGroup: false,
        color: Colors.blue[100],
      ),
      _ChatRoomItem(
        roomId: 'room2',
        title: '공부 인증방 4',
        lastMessage: '오늘 인증 올려주세요',
        time: '오전 10:12',
        isGroup: true,
        color: Colors.yellow[100],
      ),
      _ChatRoomItem(
        roomId: 'room3',
        title: '정보 공유방 100',
        lastMessage: '링크 공유해드릴게요',
        time: '어제',
        isGroup: true,
        color: Colors.green[100],
      ),
    ];

    // MainScreen에서 이미 Scaffold와 AppBar를 제공하므로 body만 반환
    return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: dummyRooms.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final room = dummyRooms[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: room.color ?? Colors.grey[300],
              child: Text(
                room.title.characters.first,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              room.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              room.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              room.time,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                RouteNames.chatRoom,
                arguments: ChatRoomScreenArgs(
                  roomId: room.roomId,
                  roomTitle: room.title,
                  isGroup: room.isGroup,
                ),
              );
            },
          );
        },
    );
  }
}

class _ChatRoomItem {
  final String roomId;
  final String title;
  final String lastMessage;
  final String time;
  final bool isGroup;
  final Color? color;

  _ChatRoomItem({
    required this.roomId,
    required this.title,
    required this.lastMessage,
    required this.time,
    required this.isGroup,
    this.color,
  });
}
