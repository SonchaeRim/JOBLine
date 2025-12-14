import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../community/services/community_service.dart';
import '../../community/models/community.dart';

class CommunitySwitchScreen extends StatefulWidget {
  const CommunitySwitchScreen({super.key});

  @override
  State<CommunitySwitchScreen> createState() => _CommunitySwitchScreenState();
}

class _CommunitySwitchScreenState extends State<CommunitySwitchScreen> {
  final _svc = CommunityService();
  List<Community> _items = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _selectedId = null;
        _loading = false;
      });
      return;
    }

    final items = await _svc.fetchCommunities();
    final current = await _svc.getMainCommunityId(user.uid);

    if (!mounted) return;
    setState(() {
      _items = items;
      _selectedId = current;
      _loading = false;
    });
  }

  Future<void> _apply() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다.')),
      );
      return;
    }

    if (_selectedId == null) return;

    try {
      await _svc.setMainCommunityId(user.uid, _selectedId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커뮤니티가 변경되었습니다!')),
      );
      Navigator.pop(context); // 설정화면으로 돌아가기
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('변경 중 오류가 발생했습니다.')),
      );
      // ignore: avoid_print
      print('setMainCommunityId error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('커뮤니티 변경')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '새 메인 커뮤니티를 선택하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _items.map((c) {
                    final selected = _selectedId == c.id;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedId = c.id),
                      backgroundColor: surface,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('변경 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
