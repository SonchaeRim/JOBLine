import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final List<Map<String, dynamic>> _selectedUsers = [];

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  bool _isSelected(String uid) {
    return _selectedUsers.any((u) => (u['uid'] as String) == uid);
  }

  void _toggleSelect(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    setState(() {
      if (_isSelected(uid)) {
        _selectedUsers.removeWhere((u) => (u['uid'] as String) == uid);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    setState(() => _loading = true);
    try {
      _results = await _chatService.searchUsers(q);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_selectedUsers.isEmpty) return;

    setState(() => _loading = true);
    try {
      // ✅ 1명 선택이면 DM
      if (_selectedUsers.length == 1) {
        final u = _selectedUsers.first;
        final otherUid = u['uid'] as String;
        final otherNickname = (u['nickname'] as String?) ?? 'User';

        final roomId = await _chatService.createOrGetDmRoom(otherUid: otherUid);

        if (!mounted) return;
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

      // ✅ 2명 이상이면 그룹 채팅
      final memberUids = _selectedUsers.map((e) => e['uid'] as String).toList();

      final roomId = await _chatService.createGroupRoom(
        memberUids: memberUids,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        RouteNames.chatRoom,
        arguments: ChatRoomScreenArgs(
          roomId: roomId,
          roomTitle: '',
          isGroup: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildAvatar(Map<String, dynamic> u) {
    final nick = (u['nickname'] as String?)?.trim();
    final photoUrl = (u['profileImageUrl'] as String?)?.trim() ?? '';

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }

    // photoUrl 없을 때 기본(글자 or 아이콘)
    final first = (nick != null && nick.isNotEmpty) ? nick.characters.first : '';
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[300],
      child: first.isNotEmpty
          ? Text(first, style: const TextStyle(fontWeight: FontWeight.bold))
          : const Icon(Icons.person, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방 생성'),
        actions: [
          TextButton(
            onPressed: (_selectedUsers.isEmpty || _loading) ? null : _confirm,
            child: Text(
              '확인',
              style: TextStyle(
                color: (_selectedUsers.isEmpty || _loading) ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ 상단: 선택된 사용자 아바타 리스트(프로필 이미지 적용)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('초대할 사용자', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final u = _selectedUsers[i];

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildAvatar(u),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: InkWell(
                              onTap: () => _toggleSelect(u),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ✅ 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '닉네임, 아이디',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (query.isEmpty || _loading) ? null : _search,
                    child: const Text('검색'),
                  ),
                ),
              ],
            ),
          ),

          if (_loading) const LinearProgressIndicator(minHeight: 2),

          // ✅ 결과 리스트
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('닉네임, 아이디로 검색해보세요.'))
                : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = _results[index];
                final uid = u['uid'] as String;
                if (uid == _myUid) return const SizedBox.shrink();

                final nickname = (u['nickname'] as String?) ?? 'User';
                final tag = (u['tag'] as String?) ?? '0000';
                final selected = _isSelected(uid);

                // ✅ 결과 리스트도 프로필 이미지 있으면 보여주기(선택사항이지만 자연스러워서 넣었음)
                final photoUrl = (u['profileImageUrl'] as String?)?.trim() ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: photoUrl.isEmpty ? null : CachedNetworkImageProvider(photoUrl),
                    child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(nickname),
                  subtitle: Text('#$tag'),
                  trailing: IconButton(
                    icon: Icon(selected ? Icons.remove_circle_outline : Icons.add),
                    onPressed: _loading ? null : () => _toggleSelect(u),
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
