import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  int _lastMsgCount = 0;

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

    if (mounted) _inputFocus.requestFocus();
  }

  // ✅ 여기만 수정됨: 실패 원인 보이게 + 업로드 중 UX
  Future<void> _sendImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    try {
      // (선택) 업로드 중 표시
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진 업로드 중...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _chatService.sendImage(roomId: widget.roomId, file: File(x.path));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      // ✅ 지금까지는 "안 보내짐"으로만 보였는데,
      // 이제는 권한/규칙/경로 문제를 에러로 바로 확인 가능
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 전송 실패: $e')),
      );
    }

    if (mounted) _inputFocus.requestFocus();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  String _senderName(ChatRoom? room, ChatMessage m) {
    if (m.senderId == 'system') return 'system';
    if (room == null) return m.senderId == _myUid ? '나' : '사용자';

    final v = room.memberNicknames[m.senderId];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return m.senderId == _myUid ? '나' : '사용자';
  }

  String _senderPhotoUrl(ChatRoom? room, ChatMessage m) {
    if (m.senderId == 'system' || room == null) return '';
    final v = room.memberPhotoUrls[m.senderId];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return '';
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
              // IconButton(
              //   tooltip: '알림',
              //   icon: const Icon(Icons.notifications_none),
              //   onPressed: () {},
              // ),
              IconButton(
                tooltip: '채팅방 나가기',
                icon: const Icon(Icons.exit_to_app),
                onPressed: _confirmLeaveRoom,
              ),
            ],
          ),
          body: Column(
            children: [
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

                    if (msgs.length != _lastMsgCount) {
                      _lastMsgCount = msgs.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom(animate: true);
                      });
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final m = msgs[index];
                        final fromMe = m.senderId == _myUid;

                        final prev = (index - 1 >= 0) ? msgs[index - 1] : null;
                        final isFirstOfSequence = prev == null || prev.senderId != m.senderId;

                        final showSenderInfo = !fromMe && isFirstOfSequence && m.type != 'system';

                        return MessageBubble(
                          message: m,
                          fromMe: fromMe,
                          senderName: _senderName(room, m),
                          senderPhotoUrl: _senderPhotoUrl(room, m),
                          showSenderInfo: showSenderInfo,
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
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) {
                            if (event is RawKeyDownEvent) {
                              final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey == LogicalKeyboardKey.numpadEnter;
                              if (isEnter && !event.isShiftPressed) {
                                _sendMessage();
                              }
                            }
                          },
                          child: TextField(
                            focusNode: _inputFocus,
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: '메시지를 입력하세요',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
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
    final others = <String>[];

    for (final u in room.memberIds) {
      if (u == _myUid) continue;
      final n = room.memberNicknames[u];
      if (n is String && n.trim().isNotEmpty) others.add(n.trim());
    }

    if (others.isNotEmpty) {
      if (others.length <= 3) return others.join(', ');
      final shown = others.take(3).join(', ');
      return '$shown 외 ${others.length - 3}명';
    }

    final t = room.title.trim();
    return t.isNotEmpty ? t : '채팅';
  }

  String _headerPhotoUrl(ChatRoom room) {
    if (!room.isGroup) {
      for (final u in room.memberIds) {
        if (u != _myUid) {
          final url = room.memberPhotoUrls[u];
          if (url is String && url.isNotEmpty) return url;
        }
      }
    }
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
