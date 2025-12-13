import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/chat_service.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreenArgs {
  final String roomId;
  final String roomTitle;
  final bool isGroup;

  ChatRoomScreenArgs({
    required this.roomId,
    required this.roomTitle,
    this.isGroup = false,
  });
}

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final bool isGroup;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    this.isGroup = false,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _picker = ImagePicker();

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _confirmLeaveRoom() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방을 나가시겠습니까?'),
        content: const Text('나가기를 하면 채팅방 목록에서 삭제됩니다.'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('확인', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _chatService.leaveRoom(widget.roomId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await _chatService.sendText(roomId: widget.roomId, text: text);
  }

  Future<void> _sendImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    await _chatService.sendImage(roomId: widget.roomId, file: File(x.path));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom>(
      stream: _chatService.watchRoom(widget.roomId),
      builder: (context, roomSnap) {
        final room = roomSnap.data;
        final title = room == null ? widget.roomTitle : _titleForRoom(room);

        final headerPhotoUrl = room == null ? '' : _headerPhotoUrl(room);
        final headerSubtitle = room == null ? '' : _headerSubtitle(room);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: headerPhotoUrl.isEmpty ? null : CachedNetworkImageProvider(headerPhotoUrl),
                  child: headerPhotoUrl.isEmpty ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (headerSubtitle.isNotEmpty)
                        Text(
                          headerSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: '알림',
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              IconButton(
                tooltip: '채팅방 나가기',
                icon: const Icon(Icons.exit_to_app),
                onPressed: _confirmLeaveRoom,
              ),
            ],
          ),
          body: Column(
            children: [
              // ✅ (8) 상단 공지 문구 (항상 고정)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: Colors.grey[100],
                child: const Text(
                  '모두가 기분 좋게 소통할 수 있는 취준 커뮤니티를 위해\n서로를 존중하고 배려하는 마음을 지켜주세요. 🍀💌',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.watchMessages(widget.roomId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final msgs = snap.data ?? [];
                    if (msgs.isEmpty) return const Center(child: Text('첫 메시지를 보내보세요.'));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      reverse: true,
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final m = msgs[index];
                        final fromMe = m.senderId == _myUid;

                        return MessageBubble(
                          message: m,
                          fromMe: fromMe,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '사진 보내기',
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        onPressed: _sendImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: '메시지를 입력하세요',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _titleForRoom(ChatRoom room) {
    if (!room.isGroup) {
      for (final u in room.memberIds) {
        if (u != _myUid) {
          final n = room.memberNicknames[u];
          if (n is String && n.isNotEmpty) return n;
        }
      }
      return '채팅';
    }
    return room.title.isEmpty ? '그룹 채팅' : room.title;
  }

  String _headerPhotoUrl(ChatRoom room) {
    if (!room.isGroup) {
      for (final u in room.memberIds) {
        if (u != _myUid) {
          final url = room.memberPhotoUrls[u];
          if (url is String && url.isNotEmpty) return url;
        }
      }
      return '';
    }
    // 그룹은 대표 이미지 없음(원하면 첫 멤버로 넣어도 됨)
    return '';
  }

  String _headerSubtitle(ChatRoom room) {
    if (!room.isGroup) {
      for (final u in room.memberIds) {
        if (u != _myUid) {
          final tag = room.memberTags[u];
          if (tag is String && tag.isNotEmpty) return '#$tag';
        }
      }
      return '';
    }
    // 그룹: 멤버 요약
    final names = <String>[];
    for (final u in room.memberIds) {
      if (u == _myUid) continue;
      final n = room.memberNicknames[u];
      if (n is String && n.isNotEmpty) names.add(n);
      if (names.length >= 2) break;
    }
    final head = names.isEmpty ? '멤버' : names.join(', ');
    return '$head 외 ${room.memberIds.length - 1}명';
  }

  String _formatTime(DateTime dt) {
    return DateFormat('a hh:mm', 'ko_KR').format(dt);
  }
}
