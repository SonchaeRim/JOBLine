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

/// 채팅방 화면으로 이동할 때 사용하는 arguments
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

/// 실제 채팅방 화면
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
  /// 메시지 입력 컨트롤러
  final _messageController = TextEditingController();

  /// Firestore / Storage 통신 담당 서비스
  final _chatService = ChatService();

  /// 이미지 선택용 picker
  final _picker = ImagePicker();

  /// 메시지 리스트 스크롤 제어
  final _scrollController = ScrollController();

  /// 입력창 포커스 제어
  final _inputFocus = FocusNode();

  /// 메시지 개수 변경 감지용
  int _lastMsgCount = 0;

  /// 내 uid
  String get _myUid => FirebaseAuth.instance.currentUser!.uid;


  /// 채팅방 나가기
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

   /// 텍스트 메시지 전송
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await _chatService.sendText(roomId: widget.roomId, text: text);

    // 메시지 전송 후 다시 입력창에 포커스
    if (mounted) _inputFocus.requestFocus();
  }


  /// 이미지 메시지 전송

  Future<void> _sendImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    try {
      // 업로드 중 안내 스낵바
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진 업로드 중...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _chatService.sendImage(
        roomId: widget.roomId,
        file: File(x.path),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      // 업로드 실패 시 에러 안내
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 전송 실패: $e')),
      );
    }

    if (mounted) _inputFocus.requestFocus();
  }


  /// 스크롤을 맨 아래로 이동
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


  /// 메시지 보낸 사람 이름 결정
  String _senderName(ChatRoom? room, ChatMessage m) {
    if (m.senderId == 'system') return 'system';
    if (room == null) return m.senderId == _myUid ? '나' : '사용자';

    final v = room.memberNicknames[m.senderId];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return m.senderId == _myUid ? '나' : '사용자';
  }


  /// 메시지 보낸 사람 프로필 이미지
  String _senderPhotoUrl(ChatRoom? room, ChatMessage m) {
    if (m.senderId == 'system' || room == null) return '';
    final v = room.memberPhotoUrls[m.senderId];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom>(
      // 채팅방 정보 실시간 구독
      stream: _chatService.watchRoom(widget.roomId),
      builder: (context, roomSnap) {
        final room = roomSnap.data;

        // 상단 헤더 정보
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
                  backgroundImage: headerPhotoUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(headerPhotoUrl),
                  child: headerPhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 18)
                      : null,
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // 채팅방 나가기 버튼
              IconButton(
                tooltip: '채팅방 나가기',
                icon: const Icon(Icons.exit_to_app),
                onPressed: _confirmLeaveRoom,
              ),
            ],
          ),
          body: Column(
            children: [
              /// 상단 안내 문구
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: Colors.grey[100],
                child: const Text(
                  '모두가 기분 좋게 소통할 수 있는 취준 커뮤니티를 위해\n'
                      '서로를 존중하고 배려하는 마음을 지켜주세요. 🍀💌',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                ),
              ),

              /// 메시지 리스트 영역
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.watchMessages(widget.roomId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final msgs = snap.data ?? [];
                    if (msgs.isEmpty) {
                      return const Center(child: Text('첫 메시지를 보내보세요.'));
                    }

                    // 메시지 개수 변경 시 자동 스크롤
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

                        final prev = index > 0 ? msgs[index - 1] : null;
                        final isFirstOfSequence =
                            prev == null || prev.senderId != m.senderId;

                        final showSenderInfo =
                            !fromMe && isFirstOfSequence && m.type != 'system';

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

              /// 입력창 영역
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                              final isEnter =
                                  event.logicalKey == LogicalKeyboardKey.enter ||
                                      event.logicalKey ==
                                          LogicalKeyboardKey.numpadEnter;
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
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


  /// 방 제목 생성 (내 기준)
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


  /// 상단 헤더 프로필 이미지
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


  /// 상단 헤더 부제목 (태그 / 멤버 요약)
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
}
