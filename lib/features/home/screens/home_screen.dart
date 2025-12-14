import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/route_names.dart';
import '../widgets/xp_badge.dart';
import '../widgets/admin_button.dart';
import '../widgets/board_section.dart';
import '../widgets/calendar_section.dart';
import '../../challenge/utils/admin_utils.dart';

/// 홈 탭 화면
class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;

  const HomeScreen({super.key, this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  // 현재 사용자 ID 가져오기
  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminUtils.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 ID가 없으면 임시 ID 사용 (개발용)
    final userId = _currentUserId ?? 'temp_user_id';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 관리자 버튼 (관리자인 경우에만 표시)
          if (_isAdmin && !_isCheckingAdmin) ...[
            const AdminButton(),
            const SizedBox(height: 24),
          ],

          // XP Badge 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: XpBadge(
              userId: userId,
              onChallengeRegisterPressed: () {
                Navigator.pushNamed(context, RouteNames.challenge);
              },
            ),
          ),

          const SizedBox(height: 16),

          // 게시판 섹션,
          BoardSection(userId: userId),

          const SizedBox(height: 16),

          // 캘린더 섹션
          CalendarSection(
            userId: userId,
            onTabChanged: widget.onTabChanged,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}