import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool fromMe;

  const MessageBubble({
    super.key,
    required this.text,
    required this.fromMe,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: fromMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: fromMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: fromMe ? Colors.blue[400] : Colors.grey[200],
          borderRadius: radius,
        ),
        child: Text(
          text,
          style: TextStyle(color: fromMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
