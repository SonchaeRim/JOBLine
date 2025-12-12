import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  /// 내 채팅방 목록(실시간)
  Stream<List<ChatRoom>> watchMyRooms() {
    return _db
        .collection('chat_rooms')
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatRoom.fromDoc(d)).toList());
  }

  /// 방 메시지(실시간)
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  /// ✅ 닉네임으로만 검색 (정확히 일치)
  Future<List<Map<String, dynamic>>> searchUsersByNickname(String nickname) async {
    final q = nickname.trim().toLowerCase();
    if (q.isEmpty) return [];

    final snap = await _db
        .collection('users')
        .where('nicknameLower', isEqualTo: q)
        .limit(30)
        .get();

    final results = <Map<String, dynamic>>[];
    for (final d in snap.docs) {
      if (d.id == uid) continue;
      final data = d.data();
      data['uid'] = d.id;
      results.add(data);
    }
    return results;
  }

  Future<Map<String, String>> _getMyNickTag() async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final nick = (data['nickname'] as String?) ?? 'User';
    final tag = (data['tag'] as String?) ?? '0000';
    return {'nickname': nick, 'tag': tag};
  }

  /// ✅ DM 방 생성(중복 방지)
  Future<String> createOrGetDmRoom({
    required String otherUid,
    required String otherNickname,
    required String otherTag,
  }) async {
    final pair = [uid, otherUid]..sort();
    final pairKey = '${pair[0]}_${pair[1]}';

    final existing = await _db
        .collection('chat_rooms')
        .where('type', isEqualTo: 'dm')
        .where('pairKey', isEqualTo: pairKey)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final my = await _getMyNickTag();

    final docRef = _db.collection('chat_rooms').doc();
    await docRef.set({
      'type': 'dm',
      'pairKey': pairKey,
      'title': '', // dm은 상대 닉네임으로 화면에서 표시
      'memberIds': [uid, otherUid],

      // ✅ 표시용(닉네임 / 태그를 분리해서 저장)
      'memberNicknames': {
        uid: my['nickname'],
        otherUid: otherNickname,
      },
      'memberTags': {
        uid: my['tag'],
        otherUid: otherTag,
      },

      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });

    return docRef.id;
  }

  Future<void> sendText({
    required String roomId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'roomId': roomId,
        'senderId': uid,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(roomRef, {
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final roomRef = _db.collection('chat_rooms').doc(roomId);
    await roomRef.update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'memberNicknames.$uid': FieldValue.delete(),
      'memberTags.$uid': FieldValue.delete(),
    });
  }
}
