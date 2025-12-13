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
  Stream<List<ChatRoom>> watchMyRooms() {
    return _db
        .collection('chat_rooms')
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatRoom.fromDoc(d)).toList());
  }

  /// 방 메시지(실시간) - 위->아래 쌓이기(asc)
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(300)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  /// ✅ 방 정보
  Stream<ChatRoom> watchRoom(String roomId) {
    return _db.collection('chat_rooms').doc(roomId).snapshots().map((d) => ChatRoom.fromDoc(d));
  }

  /// ✅ 닉네임/아이디 검색(정확히 일치)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    final byNick = await _db.collection('users').where('nicknameLower', isEqualTo: q).limit(30).get();
    for (final d in byNick.docs) {
      if (d.id == uid) continue;
      if (seen.add(d.id)) {
        final data = d.data();
        data['uid'] = d.id;
        results.add(data);
      }
    }

    final byIdLower = await _db.collection('users').where('loginId', isEqualTo: q).limit(30).get();
    for (final d in byIdLower.docs) {
      if (d.id == uid) continue;
      if (seen.add(d.id)) {
        final data = d.data();
        data['uid'] = d.id;
        results.add(data);
      }
    }

    final byIdRaw =
    await _db.collection('users').where('loginId', isEqualTo: query.trim()).limit(30).get();
    for (final d in byIdRaw.docs) {
      if (d.id == uid) continue;
      if (seen.add(d.id)) {
        final data = d.data();
        data['uid'] = d.id;
        results.add(data);
      }
    }

    return results;
  }

  Future<Map<String, String>> _getUserNickTagPhoto(String userUid) async {
    final doc = await _db.collection('users').doc(userUid).get();
    final data = doc.data() ?? {};

    final nick = (data['nickname'] as String?) ?? 'User';
    final tag = (data['tag'] as String?) ?? '0000';
    final photoUrl = (data['profileImageUrl'] as String?) ?? '';

    return {'nickname': nick, 'tag': tag, 'photoUrl': photoUrl};
  }

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
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });

    await _db.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage.systemMap(roomId: roomId, text: '${me['nickname']}님이 채팅을 시작했어요.'),
    );

    return roomId;
  }

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
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });

    final meNick = nickMap[uid] ?? 'User';
    await _db.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage.systemMap(roomId: roomId, text: '$meNick님이 채팅을 만들었어요.'),
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ✅ 이미지 전송 (PostEditor 방식 참고해서 안정화)
  Future<void> sendImage({required String roomId, required File file}) async {
    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    // 확장자 안전 처리
    String ext = 'jpg';
    final name = file.path.split('/').last;
    if (name.contains('.')) {
      final e = name.split('.').last.toLowerCase();
      if (e.isNotEmpty) ext = e;
    }

    // contentType 대충 맞춰주기
    String contentType = 'image/$ext';
    if (ext == 'jpg') contentType = 'image/jpeg';
    if (ext == 'jpeg') contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';
    if (ext == 'heic' || ext == 'heif') contentType = 'image/heic';

    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    // ✅ PostEditor랑 동일하게 uid까지 포함하면 관리/권한/디버깅이 쉬움
    final storageRef = _storage.ref().child('chat_images/$roomId/$uid/$filename');

    try {
      // 업로드
      await storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      // URL
      final url = await storageRef.getDownloadURL();

      // Firestore 저장 (메시지 + 채팅방 lastMessage 동시 업데이트)
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
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      // 여기서 caught 되면 거의 대부분 "권한" 또는 "경로" 문제
      throw Exception('이미지 업로드 실패: ${e.code}');
    } catch (e) {
      throw Exception('이미지 전송 실패: $e');
    }
  }

  Future<void> leaveRoom(String roomId) async {
    final roomRef = _db.collection('chat_rooms').doc(roomId);
    await roomRef.update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'memberNicknames.$uid': FieldValue.delete(),
      'memberTags.$uid': FieldValue.delete(),
      'memberPhotoUrls.$uid': FieldValue.delete(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
