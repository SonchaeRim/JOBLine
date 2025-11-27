import 'package:flutter/material.dart';
import '../../community/services/community_service.dart';
import '../../community/models/community.dart';
import '../../../routes/route_names.dart';
import '../../common/screens/main_screen.dart'; // 🔹 MainScreen 직접 이동용

const demoUid = 'demo-uid';

class CategorySelectScreen extends StatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
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
    final items = await _svc.fetchCommunities();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// 🔹 가입 완료 눌렀을 때
  Future<void> _submit() async {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('하나를 선택해주세요')),
      );
      return;
    }

    try {
      await _svc.setMainCommunityId(demoUid, _selectedId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커뮤니티가 설정되었습니다!')),
      );

      // ✅ 방법 1: MainScreen 직접 푸시 (스택 싹 비우고)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );

      // ✅ 방법 2: named route 쓰고 싶으면 이걸로 (위에 거 대신)
      // Navigator.pushNamedAndRemoveUntil(
      //   context,
      //   RouteNames.home,
      //   (route) => false,
      // );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
      );
      // 디버깅용
      // ignore: avoid_print
      print('setMainCommunityId error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('관심 분야 선택'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '어떤 분야에 관심이 있나요?',
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
                      onSelected: (_) {
                        setState(() => _selectedId = c.id);
                      },
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
                onPressed: _submit,
                child: const Text('가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
