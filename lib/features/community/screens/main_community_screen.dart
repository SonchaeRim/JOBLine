import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../community/services/community_service.dart';
import '../../community/models/community.dart';

class MainCommunityScreen extends StatefulWidget {
  const MainCommunityScreen({super.key});

  @override
  State<MainCommunityScreen> createState() => _MainCommunityScreenState();
}

class _MainCommunityScreenState extends State<MainCommunityScreen> {
  final _svc = CommunityService();
  String? _name;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;

    // 로그인 정보 없으면 미설정 처리
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _name = '미설정';
        _loading = false;
      });
      return;
    }

    // users/{uid}에서 mainCommunityId 읽기
    final id = await _svc.getMainCommunityId(user.uid);

    if (!mounted) return;

    // 없거나 빈 값이면 미설정
    if (id == null || id.isEmpty) {
      setState(() {
        _name = '미설정';
        _loading = false;
      });
      return;
    }

    // communities에서 id에 해당하는 name 찾아오기
    final List<Community> list = await _svc.fetchCommunities();

    Community? found;
    for (final c in list) {
      if (c.id == id) {
        found = c;
        break;
      }
    }

    setState(() {
      _name = found?.name ?? id; // name 있으면 name, 없으면 id 그대로 표시
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Chip(label: Text(_name ?? '미설정'));
  }
}
