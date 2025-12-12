import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();

  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      _results = await _chatService.searchUsersByNickname(_searchController.text);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startDm(Map<String, dynamic> user) async {
    final otherUid = user['uid'] as String;
    final otherNickname = (user['nickname'] as String?) ?? 'User';
    final otherTag = (user['tag'] as String?) ?? '0000';

    setState(() => _loading = true);
    try {
      final roomId = await _chatService.createOrGetDmRoom(
        otherUid: otherUid,
        otherNickname: otherNickname,
        otherTag: otherTag,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        RouteNames.chatRoom,
        arguments: ChatRoomScreenArgs(
          roomId: roomId,
          roomTitle: otherNickname, // ✅ 채팅방 타이틀은 닉네임
          isGroup: false,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('채팅방 만들기')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: const Text('초대할 친구 선택', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '닉네임', // ✅ 닉네임만
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: query.isEmpty || _loading ? null : _search,
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('닉네임으로 검색해보세요.'))
                : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = _results[index];
                final nickname = (u['nickname'] as String?) ?? 'User';
                final tag = (u['tag'] as String?) ?? '0000';

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(nickname),       // ✅ 닉네임만
                  subtitle: Text('#$tag'),     // ✅ 중복 구분
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _loading ? null : () => _startDm(u),
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
