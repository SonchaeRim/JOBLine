import 'package:flutter/material.dart';
import '../../community/services/community_service.dart';

const demoUid = 'demo-uid'; // TODO: Auth 붙이면 교체

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
    final id = await _svc.getMainCommunityId(demoUid);
    if (id == null) {
      setState(() {
        _name = '미설정';
        _loading = false;
      });
      return;
    }
    // id → name 조회
    final list = await _svc.fetchCommunities();
    final found = list.where((e) => e.id == id).firstOrNull;
    setState(() {
      _name = found?.name ?? id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    return Chip(label: Text(_name ?? '미설정'));
  }
}
