import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/chat_room.dart';
import '../models/message.dart';

/// 채팅 관련 Firestore/Storage 처리 서비스
class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser!.uid;

  /// 내 mainCommunityId 조회(같은 커뮤니티끼리만 채팅 가능하도록 제한)
  Future<String?> _myCommunityId() async {
    final doc = await _db.collection('users').doc(uid).get();
    final v = doc.data()?['mainCommunityId'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  /// 내 채팅방 목록 구독 (memberIds에 내 uid 포함된 방)
  Stream<List<ChatRoom>> watchMyRooms() {
    return _db
        .collection('chat_rooms')
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatRoom.fromDoc(d)).toList());
  }

  /// 특정 방 메시지 구독
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

  /// 방 정보 구독 (제목/멤버/최신메시지 등)
  Stream<ChatRoom> watchRoom(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .map((d) => ChatRoom.fromDoc(d));
  }

  /// 유저 검색: 같은 커뮤니티 유저만 대상으로
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final myCommunityId = await _myCommunityId();
    if (myCommunityId == null) return [];

    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    // 1) nicknameLower 정확히 일치 검색
    final byNick = await _db
        .collection('users')
        .where('mainCommunityId', isEqualTo: myCommunityId)
        .where('nicknameLower', isEqualTo: q)
        .limit(30)
        .get();

    for (final d in byNick.docs) {
      if (d.id == uid) continue;
      if (seen.add(d.id)) {
        final data = d.data();
        data['uid'] = d.id;
        results.add(data);
      }
    }

    // 2) loginId 소문자 기준 검색(필요 시 인덱스 주의)
    final byIdLower = await _db
        .collection('users')
        .where('mainCommunityId', isEqualTo: myCommunityId)
        .where('loginId', isEqualTo: q)
        .limit(30)
        .get();

    for (final d in byIdLower.docs) {
      if (d.id == uid) continue;
      if (seen.add(d.id)) {
        final data = d.data();
        data['uid'] = d.id;
        results.add(data);
      }
    }

    // 3) 원본 입력 그대로도 한 번 더 검색
    final byIdRaw = await _db
        .collection('users')
        .where('mainCommunityId', isEqualTo: myCommunityId)
        .where('loginId', isEqualTo: query.trim())
        .limit(30)
        .get();

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

  /// 특정 uid의 (닉/태그/프로필이미지) 기본 정보 가져오기
  Future<Map<String, String>> _getUserNickTagPhoto(String userUid) async {
    final doc = await _db.collection('users').doc(userUid).get();
    final data = doc.data() ?? {};

    final nick = (data['nickname'] as String?) ?? 'User';
    final loginId = (data['loginId'] as String?) ?? '';
    final photoUrl = (data['profileImageUrl'] as String?) ?? '';

    // tag는 loginId 끝 4자리로 생성
    String tag = '0000';
    if (loginId.isNotEmpty && loginId.length > 4) {
      tag = loginId.substring(loginId.length - 4);
    }

    return {'nickname': nick, 'tag': tag, 'photoUrl': photoUrl};
  }

  /// DM 방 생성(이미 있으면 기존 방 반환)
  /// - 같은 커뮤니티끼리만 허용
  /// - pairKey로 중복 방지
  Future<String> createOrGetDmRoom({required String otherUid}) async {
    final myDoc = await _db.collection('users').doc(uid).get();
    final otherDoc = await _db.collection('users').doc(otherUid).get();

    final myCommunity = myDoc.data()?['mainCommunityId'];
    final otherCommunity = otherDoc.data()?['mainCommunityId'];

    if (myCommunity == null ||
        otherCommunity == null ||
        myCommunity != otherCommunity) {
      throw Exception('같은 커뮤니티 사용자만 채팅할 수 있습니다.');
    }

    // pairKey: uid 2개를 정렬해서 고정 키 생성
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
      'communityId': myCommunity,
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

    // 시스템 메시지(방 생성 안내)
    await docRef.collection('messages').add(
      ChatMessage.systemMap(
        roomId: roomId,
        text: '${me['nickname']}님이 채팅을 시작했어요.',
      ),
    );

    return roomId;
  }

  /// 그룹 방 생성
  /// - 같은 커뮤니티끼리만 허용
  /// - 최소 3명(나 포함)
  Future<String> createGroupRoom({
    required List<String> memberUids,
    String? title,
  }) async {
    final myDoc = await _db.collection('users').doc(uid).get();
    final myCommunity = myDoc.data()?['mainCommunityId'];

    // 커뮤니티 일치 검사
    for (final u in memberUids) {
      final otherDoc = await _db.collection('users').doc(u).get();
      final otherCommunity = otherDoc.data()?['mainCommunityId'];

      if (myCommunity == null ||
          otherCommunity == null ||
          myCommunity != otherCommunity) {
        throw Exception('같은 커뮤니티 사용자만 그룹 채팅이 가능합니다.');
      }
    }

    // 중복 제거 + 나 포함 보장
    final uniq = {...memberUids}.toList();
    if (!uniq.contains(uid)) uniq.add(uid);

    if (uniq.length < 3) {
      throw Exception('그룹 채팅은 최소 3명(나 포함)이어야 합니다.');
    }

    // 멤버별 표시 정보 map 구성
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
      'communityId': myCommunity,
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
    await docRef.collection('messages').add(
      ChatMessage.systemMap(
        roomId: roomId,
        text: '$meNick님이 채팅을 만들었어요.',
      ),
    );

    return roomId;
  }

  /// 텍스트 메시지 전송 (트랜잭션으로 메시지+방 최신정보 동시 업데이트)
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

  /// 이미지 업로드(Storage) 후 메시지 전송
  Future<void> sendImage({required String roomId, required File file}) async {
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('chat_images/$roomId/$uid/$filename');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

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
  }

  /// 채팅방 나가기: memberIds에서 제거 + 멤버 map(닉/태그/사진)에서도 삭제
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
