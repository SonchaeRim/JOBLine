import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/chat_room.dart';
import '../models/message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser!.uid;

  /// ✅ 내 채팅방 목록(실시간)
  /// - 너 콘솔에 이미 있는 인덱스: memberIds + lastMessageAt 로 맞춤
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
        .limit(300)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  /// ✅ 방 정보(프로필/멤버 표시용)
  Stream<ChatRoom> watchRoom(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .map((d) => ChatRoom.fromDoc(d));
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

  /// ✅ 너 users 문서 구조에 맞춤: profileImageUrl 사용
  Future<Map<String, String>> _getUserNickTagPhoto(String userUid) async {
    final doc = await _db.collection('users').doc(userUid).get();
    final data = doc.data() ?? {};

    final nick = (data['nickname'] as String?) ?? 'User';
    final tag = (data['tag'] as String?) ?? '0000';

    // 🔥 여기 중요: 너 DB는 profileImageUrl 임
    final photoUrl = (data['profileImageUrl'] as String?) ?? '';

    return {'nickname': nick, 'tag': tag, 'photoUrl': photoUrl};
  }

  /// ✅ DM 방 생성(중복 방지)
  Future<String> createOrGetDmRoom({required String otherUid}) async {
    final pair = [uid, otherUid]..sort();
    final pairKey = '${pair[0]}_${pair[1]}';

    final existing = await _db
        .collection('chat_rooms')
        .where('type', isEqualTo: 'dm')
        .where('pairKey', isEqualTo: pairKey)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final me = await _getUserNickTagPhoto(uid);
    final other = await _getUserNickTagPhoto(otherUid);

    final docRef = _db.collection('chat_rooms').doc();
    final roomId = docRef.id;

    await docRef.set({
      'type': 'dm',
      'pairKey': pairKey,
      'title': '',
      'memberIds': [uid, otherUid],
      'memberNicknames': {uid: me['nickname'], otherUid: other['nickname']},
      'memberTags': {uid: me['tag'], otherUid: other['tag']},
      'memberPhotoUrls': {uid: me['photoUrl'], otherUid: other['photoUrl']},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });

    // 시스템 메시지
    await _db.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage.systemMap(
        roomId: roomId,
        text: '${me['nickname']}님이 채팅을 시작했어요.',
      ),
    );

    return roomId;
  }

  /// ✅ 그룹 채팅방 생성(항상 새로 생성 → 채팅방 여러개 생성 가능)
  Future<String> createGroupRoom({
    required List<String> memberUids,
    String? title,
  }) async {
    final uniq = {...memberUids}.toList();
    if (!uniq.contains(uid)) uniq.add(uid);

    if (uniq.length < 3) {
      throw Exception('그룹 채팅은 최소 3명(나 포함)이어야 합니다.');
    }

    final nickMap = <String, String>{};
    final tagMap = <String, String>{};
    final photoMap = <String, String>{};

    for (final u in uniq) {
      final info = await _getUserNickTagPhoto(u);
      nickMap[u] = info['nickname'] ?? 'User';
      tagMap[u] = info['tag'] ?? '0000';
      photoMap[u] = info['photoUrl'] ?? '';
    }

    final docRef = _db.collection('chat_rooms').doc();
    final roomId = docRef.id;

    await docRef.set({
      'type': 'group',
      'title': title?.trim() ?? '',
      'memberIds': uniq,
      'memberNicknames': nickMap,
      'memberTags': tagMap,
      'memberPhotoUrls': photoMap,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });

    final meNick = nickMap[uid] ?? 'User';
    await _db.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage.systemMap(roomId: roomId, text: '$meNick님이 그룹 채팅을 만들었어요.'),
    );

    final invitedNames =
    uniq.where((u) => u != uid).map((u) => nickMap[u] ?? 'User').toList();

    await _db.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage.systemMap(
        roomId: roomId,
        text: '초대된 사용자: ${invitedNames.join(', ')}',
      ),
    );

    return roomId;
  }

  Future<void> sendText({required String roomId, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'roomId': roomId,
        'senderId': uid,
        'type': 'text',
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(roomRef, {
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> sendImage({required String roomId, required File file}) async {
    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    final ext = file.path.split('.').last.toLowerCase();
    final storageRef = _storage
        .ref()
        .child('chat_images')
        .child(roomId)
        .child('${DateTime.now().millisecondsSinceEpoch}.$ext');

    final task = await storageRef.putFile(file);
    final url = await task.ref.getDownloadURL();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'roomId': roomId,
        'senderId': uid,
        'type': 'image',
        'text': '',
        'imageUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(roomRef, {
        'lastMessage': '📷 사진',
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
      'memberPhotoUrls.$uid': FieldValue.delete(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
}
