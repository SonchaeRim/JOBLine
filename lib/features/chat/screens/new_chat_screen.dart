// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import 'chat_room_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  // TODO: 나중에 실제 유저 리스트/검색 결과로 바꾸기
  final List<_FriendItem> _allFriends = [
    const _FriendItem(nickname: 'JobLine#0000', userId: '0000'),
    const _FriendItem(nickname: 'JobLine#1111', userId: '1111'),
    const _FriendItem(nickname: 'JobLine#2222', userId: '2222'),
    const _FriendItem(nickname: 'JobLine#3333', userId: '3333'),
  ];

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final friends = _allFriends.where((f) {
      if (query.isEmpty) return true;
      return f.nickname.toLowerCase().contains(query) ||
          f.userId.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방 만들기'),
      ),
      body: Column(
        children: [
          // 상단 선택된 사람 영역 (지금은 UI만)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: const Text(
              '초대할 친구 선택',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // 검색 필드
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '닉네임, 아이디',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: ListView.separated(
              itemCount: friends.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(friend.nickname),
                  subtitle: Text('ID: ${friend.userId}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // 지금은 1:1 채팅 바로 생성한다고 가정
                      Navigator.pushNamed(
                        context,
                        RouteNames.chatRoom,
                        arguments: ChatRoomScreenArgs(
                          roomId: 'new_${friend.userId}',
                          roomTitle: friend.nickname,
                          isGroup: false,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendItem {
  final String nickname;
  final String userId;

  const _FriendItem({required this.nickname, required this.userId});
}
