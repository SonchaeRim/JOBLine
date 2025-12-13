import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../home/screens/home_screen.dart';
import '../../board/screens/board_tabs_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../settings/screens/setting_screen.dart';
import '../../community/services/community_service.dart';
import '../../community/models/community.dart';
import '../../../core/theme/app_colors.dart';

/// 메인 화면 - 하단 네비게이션 바와 탭 전환을 관리하는 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final CommunityService _communityService = CommunityService();
  String? _communityName;

  // 탭 index에 따라 보여줄 화면 5개
  // 0: 홈, 1: 캘린더, 2: 게시판, 3: 채팅, 4: 설정
  late final List<Widget> _screens = [
    HomeScreen(onTabChanged: _onTab),
    const CalendarScreen(),
    const BoardTabsScreen(),
    const ChatListScreen(),
    const SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCommunityName();
  }

  // 커뮤니티 이름 로드
  Future<void> _loadCommunityName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final communityId = await _communityService.getMainCommunityId(userId);
        if (communityId != null && communityId.isNotEmpty) {
          final communities = await _communityService.fetchCommunities();
          final community = communities.firstWhere(
            (c) => c.id == communityId,
            orElse: () => Community(
              id: '',
              name: '',
              description: '',
              createdAt: DateTime.now(),
            ),
          );
          if (mounted) {
            setState(() {
              // 커뮤니티 이름이 있으면 표시, 없으면 기본값 표시
              _communityName = community.name.isNotEmpty 
                  ? community.name 
                  : 'IT개발 • 데이터';
            });
          }
        } else {
          // 커뮤니티 ID가 없으면 기본값 표시
          if (mounted) {
            setState(() {
              _communityName = 'IT개발 • 데이터';
            });
          }
        }
      } catch (e) {
        // 에러 발생 시에도 기본값 표시
        print('커뮤니티 정보 로드 실패: $e');
        if (mounted) {
          setState(() {
            _communityName = 'IT개발 • 데이터';
          });
        }
      }
    } else {
      // 사용자 ID가 없어도 기본값 표시
      setState(() {
        _communityName = 'IT개발 • 데이터';
      });
    }
  }

  // BottomNavBar에서 탭 누르면 이 함수가 실행돼서 index가 변화되어 UI 갱신
  void _onTab(int i) {
    setState(() {
      _index = i;
    });
  }

  // AppBar 제목
  String? get _title {
    if (_index == 0) {
      return null; // 홈 화면일 때는 null 반환하여 커스텀 title 사용
    }
    switch (_index) {
      case 1:
        return "캘린더";
      case 2:
        return "게시판";
      case 3:
        return "채팅";
      case 4:
        return "설정";
      default:
        return "JOB LINE";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _index == 0
            ? const Text(
                'JL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              )
            : Text(_title ?? ''),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
        actions: _index == 0
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      _communityName ?? 'IT개발 • 데이터',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      // body: 중상단에 탭 화면들을 띄우는 영역
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      // bottomNavigationBar: 하단 네비게이션 바
      bottomNavigationBar: BottomNavBar(
        currentIndex: _index,
        onTap: _onTab,
      ),
    );
  }
}

