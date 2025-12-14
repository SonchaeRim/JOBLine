import 'package:flutter/material.dart';

import 'route_names.dart';

// ========= 공통 =========
import '../features/common/screens/splash_screen.dart';
import '../features/common/screens/main_screen.dart';
import '../features/common/screens/error_screen.dart';

// ========= Auth =========
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';

// ========= Community =========
import '../features/community/screens/category_select_screen.dart';
import '../features/community/screens/main_community_screen.dart';
import '../features/community/screens/community_switch_screen.dart';

// ========= Board =========
import '../features/board/screens/post_list_screen.dart';
import '../features/board/screens/board_tabs_screen.dart';
import '../features/board/screens/post_detail_screen.dart';
import '../features/board/screens/post_editor_screen.dart';

// ========= Calendar =========
import '../features/calendar/screens/calendar_screen.dart';
import '../features/calendar/screens/schedule_detail_screen.dart';
import '../features/calendar/models/schedule.dart';
import '../features/calendar/services/calendar_service.dart';

// ========= Challenge =========
import '../features/challenge/screens/challenge_screen.dart';
import '../features/challenge/screens/photo_proof_camera_screen.dart';
import '../features/challenge/screens/review_criteria_screen.dart';
import '../features/challenge/screens/certification_list_screen.dart';
import '../features/challenge/screens/certification_detail_screen.dart';
import '../features/challenge/screens/admin_user_list_screen.dart';
import '../features/challenge/screens/admin_certification_list_screen.dart';

// ========= Chat =========
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_room_screen.dart';
import '../features/chat/screens/new_chat_screen.dart';

// ========= Settings =========
import '../features/settings/screens/setting_screen.dart';
import '../features/settings/screens/password_change_screen.dart';
import '../features/settings/screens/nickname_change_screen.dart';
import '../features/settings/screens/my_posts_screen.dart';
import '../features/settings/screens/my_comments_screen.dart';

class AppRoutes {
  /// 인자가 필요 없는 화면은 여기 routes에서 처리
  static final Map<String, WidgetBuilder> routes = {
    // --- 공통 ---
    RouteNames.splash: (context) => const SplashScreen(),
    RouteNames.error: (context) => const ErrorScreen(),

    // --- Auth ---
    RouteNames.login: (context) => const LoginScreen(),
    RouteNames.signup: (context) => const SignUpScreen(),

    // --- 홈(탭 루트) ---
    RouteNames.home: (context) => const MainScreen(),

    // --- 커뮤니티 ---
    RouteNames.categorySelect: (context) => const CategorySelectScreen(),
    RouteNames.mainCommunity: (context) => const MainCommunityScreen(),

    // --- 게시판(탭 루트) ---
    RouteNames.board: (context) => const BoardTabsScreen(),

    // --- 캘린더(탭 루트) ---
    RouteNames.calendar: (context) => const CalendarScreen(),

    // --- 채팅(탭 루트) ---
    // ChatListScreen은 const 불가일 수 있으므로 const 제거
    RouteNames.chat: (context) => ChatListScreen(),

    // --- 챌린지(탭 루트) ---
    RouteNames.challenge: (context) => const ChallengeScreen(),

    // --- 설정(탭 루트) ---
    RouteNames.settings: (context) => const SettingScreen(),

    // --- 설정 하위 ---
    RouteNames.passwordChange: (context) => const PasswordChangeScreen(),
    RouteNames.nicknameChange: (context) => const NicknameChangeScreen(),
    RouteNames.communityChange: (context) => const CommunitySwitchScreen(),
    RouteNames.myPosts: (context) => const MyPostsScreen(),
    RouteNames.myComments: (context) => const MyCommentsScreen(),
  };

  /// arguments 필요한 화면들만 여기서 처리
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
    // ------------- 게시판 상세/작성 -------------
      case RouteNames.postDetail: {
        final postId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: postId),
          settings: settings,
        );
      }



      case RouteNames.postEditor: {
        final args = settings.arguments as Map<String, dynamic>?;
        final boardId = args?['boardId'] as String?;
        final postId = args?['postId'] as String?;

        if (boardId == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'postEditor: boardId missing',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => PostEditorScreen(boardId: boardId, postId: postId),
          settings: settings,
        );
      }

      case RouteNames.postList: {
        final args = settings.arguments as Map<String, dynamic>?;

        final boardId = args?['boardId'] as String?;
        final title = args?['title'] as String?;
        final communityId = args?['communityId'] as String?;

        if (boardId == null || title == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'postList args missing',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => PostListScreen(
            boardId: boardId,
            title: title,
            communityId: communityId,
          ),
          settings: settings,
        );
      }

    // ------------- 챌린지 인증 내역 확인 -------------
      case RouteNames.proofList: {
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;

        if (userId == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'proofList: userId missing',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => CertificationListScreen(userId: userId),
          settings: settings,
        );
      }

      case RouteNames.photoProof: {
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;

        if (userId == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'photoProof: userId missing',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => PhotoProofCameraScreen(userId: userId),
          settings: settings,
        );
      }

      case RouteNames.proofDetail: {
        final args = settings.arguments as Map<String, dynamic>?;
        final certificationId = args?['certificationId'] as String?;

        if (certificationId == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'proofDetail: certificationId missing',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => CertificationDetailScreen(
            certificationId: certificationId,
          ),
          settings: settings,
        );
      }

      case RouteNames.reviewCriteria:
        return MaterialPageRoute(
          builder: (_) => const ReviewCriteriaScreen(),
          settings: settings,
        );

      case RouteNames.adminUserList:
        return MaterialPageRoute(
          builder: (_) => const AdminUserListScreen(),
          settings: settings,
        );

      case RouteNames.adminCertificationList: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['userId'] != null && args['userName'] != null) {
          return MaterialPageRoute(
            builder: (_) => AdminCertificationListScreen(
              userId: args['userId'] as String,
              userName: args['userName'] as String,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ErrorScreen(
            unknownRouteName: 'adminCertificationList: userId or userName missing',
          ),
          settings: settings,
        );
      }

    // ------------- 채팅방 / 새 채팅 -------------
      case RouteNames.chatRoom: {
        final args = settings.arguments as ChatRoomScreenArgs?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'chatRoom args missing',
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: args.roomId,
            roomTitle: args.roomTitle,
            isGroup: args.isGroup,
          ),
          settings: settings,
        );
      }

      case RouteNames.newChat:
        return MaterialPageRoute(
          builder: (_) => const NewChatScreen(),
          settings: settings,
        );

    // ------------- 캘린더 일정 상세/추가/수정 -------------
      case RouteNames.scheduleDetail: {
        final args = settings.arguments as Map<String, dynamic>?;

        final userId = args?['userId'] as String?;
        final calendarService = args?['calendarService'] as CalendarService?;
        final schedule = args?['schedule'] as Schedule?;
        final selectedDate = args?['selectedDate'] as DateTime?;

        if (userId == null || calendarService == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              unknownRouteName: 'scheduleDetail: userId or calendarService missing',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => ScheduleDetailScreen(
            userId: userId,
            calendarService: calendarService,
            schedule: schedule,
            selectedDate: selectedDate,
          ),
          settings: settings,
        );
      }

      default:
        return MaterialPageRoute(
          builder: (_) => ErrorScreen(unknownRouteName: settings.name),
          settings: settings,
        );
    }
  }
}
