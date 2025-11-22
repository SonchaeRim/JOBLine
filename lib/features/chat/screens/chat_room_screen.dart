import 'package:flutter/material.dart';

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
  final TextEditingController _messageController = TextEditingController();

  // TODO: 나중에 Firestore에서 messages 가져오도록
  final List<_LocalMessage> _messages = [
    _LocalMessage(fromMe: false, text: '오늘 인증 올려주세요'),
    _LocalMessage(fromMe: true, text: '네~'),
    _LocalMessage(fromMe: false, text: '9시 전에 부탁드려요!'),
  ];

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
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // TODO: 여기서 실제로 방 나가기 처리 (Firestore 업데이트 등)
      Navigator.of(context).pop(); // 채팅방 화면 닫기
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_LocalMessage(fromMe: true, text: text));
    });
    _messageController.clear();

    // TODO: ChatService 통해 서버/Firestore로 전송
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: '알림',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: 알림 설정 화면 혹은 토글
            },
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              reverse: false,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(
                  text: msg.text,
                  fromMe: msg.fromMe,
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
  }
}

class _LocalMessage {
  final bool fromMe;
  final String text;

  _LocalMessage({required this.fromMe, required this.text});
}

/// 임시 말풍선 위젯 (나중에 features/chat/widgets/message_bubble.dart 로 교체해도 됨)
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool fromMe;

  const _MessageBubble({
    required this.text,
    required this.fromMe,
  });

  @override
  Widget build(BuildContext context) {
    final align =
    fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: fromMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: fromMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: fromMe ? Colors.blue[400] : Colors.grey[200],
            borderRadius: radius,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: fromMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
