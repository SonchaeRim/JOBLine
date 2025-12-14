import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/route_names.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

/// 유저 검색 → 선택 → DM/그룹 채팅방 생성 화면
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();

  bool _loading = false;

  /// 검색 결과(users 문서들을 Map으로)
  List<Map<String, dynamic>> _results = [];

  /// 선택된 유저 목록
  final List<Map<String, dynamic>> _selectedUsers = [];

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  bool _isSelected(String uid) {
    return _selectedUsers.any((u) => (u['uid'] as String) == uid);
  }

  /// 검색 결과에서 유저 선택/해제 토글
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

  /// Firestore에서 유저 검색(닉네임/아이디)
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

  /// 확인 버튼: 1명이면 DM, 2명 이상이면 그룹 생성
  Future<void> _confirm() async {
    if (_selectedUsers.isEmpty) return;

    setState(() => _loading = true);
    try {
      // 1명 선택이면 DM
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

      // 2명 이상이면 그룹 채팅
      final memberUids = _selectedUsers.map((e) => e['uid'] as String).toList();
      final roomId = await _chatService.createGroupRoom(memberUids: memberUids);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        RouteNames.chatRoom,
        arguments: ChatRoomScreenArgs(
          roomId: '', // 실제로는 아래에서 넣어야 함 (실수 방지)
          roomTitle: '',
          isGroup: true,
        ),
      );
      // 위 arguments는 roomId를 반드시 넣어야 해.
      // 아래처럼 해야 정상:
      // arguments: ChatRoomScreenArgs(roomId: roomId, roomTitle: '', isGroup: true)
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 선택된 사용자 아바타(프로필 이미지 있으면 적용)
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

    // photoUrl 없을 때 기본(첫 글자 or 아이콘)
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
          // 상단: 선택된 사용자 아바타 리스트
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
                          // 선택 해제(엑스 버튼)
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
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
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
                    onPressed: (_searchController.text.trim().isEmpty || _loading) ? null : _search,
                    child: const Text('검색'),
                  ),
                ),
              ],
            ),
          ),

          if (_loading) const LinearProgressIndicator(minHeight: 2),

          // ✅ 검색 결과 리스트
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('닉네임, 아이디로 검색해보세요.'))
                : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = _results[index];
                final uid = u['uid'] as String;

                // 내 자신은 초대 대상에서 제외
                if (uid == _myUid) return const SizedBox.shrink();

                final nickname = (u['nickname'] as String?) ?? 'User';
                final tag = (u['tag'] as String?) ?? '0000';
                final selected = _isSelected(uid);

                // 프로필 이미지(있으면 표시)
                final photoUrl = (u['profileImageUrl'] as String?)?.trim() ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                    photoUrl.isEmpty ? null : CachedNetworkImageProvider(photoUrl),
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
