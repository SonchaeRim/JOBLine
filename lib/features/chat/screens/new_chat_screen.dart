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

  /// uid -> userMap
  final Map<String, Map<String, dynamic>> _selected = {};
  final _groupTitleController = TextEditingController();

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await _chatService.searchUsersByNickname(q);
      if (!mounted) return;
      setState(() => _results = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelect(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    setState(() {
      if (_selected.containsKey(uid)) {
        _selected.remove(uid);
      } else {
        _selected[uid] = user;
      }
    });
  }

  Future<void> _createRoom() async {
    if (_selected.isEmpty) return;

    setState(() => _loading = true);
    try {
      // 1명 선택이면 DM
      if (_selected.length == 1) {
        final otherUid = _selected.keys.first;
        final roomId = await _chatService.createOrGetDmRoom(otherUid: otherUid);

        if (!mounted) return;
        final otherNickname = (_selected.values.first['nickname'] as String?) ?? 'User';

        Navigator.pushReplacementNamed(
          context,
          RouteNames.chatRoom,
          arguments: ChatRoomScreenArgs(
            roomId: roomId,
            roomTitle: otherNickname,
            isGroup: false,
          ),
        );
        return;
      }

      // 2명 이상 선택이면 그룹
      final memberUids = _selected.keys.toList(); // 나 포함은 service에서 보장
      final roomId = await _chatService.createGroupRoom(
        memberUids: memberUids,
        title: _groupTitleController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        RouteNames.chatRoom,
        arguments: ChatRoomScreenArgs(
          roomId: roomId,
          roomTitle: _groupTitleController.text.trim().isEmpty ? '그룹 채팅' : _groupTitleController.text.trim(),
          isGroup: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _selected.isNotEmpty && !_loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방 생성'),
        actions: [
          TextButton(
            onPressed: canCreate ? _createRoom : null,
            child: Text(
              _selected.length <= 1 ? 'DM 시작' : '그룹 생성',
              style: TextStyle(color: canCreate ? Colors.blue : Colors.grey),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 선택된 사용자 칩
          if (_selected.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selected.values.map((u) {
                  final nickname = (u['nickname'] as String?) ?? 'User';
                  final tag = (u['tag'] as String?) ?? '0000';
                  return InputChip(
                    label: Text('$nickname #$tag'),
                    onDeleted: () => _toggleSelect(u),
                  );
                }).toList(),
              ),
            ),

          // 그룹명 입력(그룹 선택 시만)
          if (_selected.length >= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                controller: _groupTitleController,
                decoration: InputDecoration(
                  hintText: '그룹 채팅방 이름(선택)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
            ),

          // 검색바 (엔터 + 버튼 둘 다)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '닉네임',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
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
                final userUid = (u['uid'] as String);
                final selected = _selected.containsKey(userUid);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: selected ? Colors.blue[100] : Colors.grey[200],
                    child: const Icon(Icons.person),
                  ),
                  title: Text(nickname),
                  subtitle: Text('#$tag'),
                  trailing: Icon(
                    selected ? Icons.check_circle : Icons.add_circle_outline,
                    color: selected ? Colors.blue : Colors.grey,
                  ),
                  onTap: _loading ? null : () => _toggleSelect(u),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
