import 'package:flutter/material.dart';
import 'route_names.dart';

import '../features/common/screens/splash_screen.dart'; // 앱 첫 실행 시 보여주는 스플래시 화면
// 일정 시간 뒤에 항상 /login 으로 이동 (자동 로그인 기능 없음)

import '../features/common/screens/home_screen.dart'; // 메인 홈 화면
// 메인 홈 화면은 하단 BottomNavigationBar (게시판, 캘린더, 채팅, 챌린지, 프로필 등) 탭 전환만 담당함.
// 실제 내용은 각 feature의 screen이 담당함.

import '../features/common/screens/error_screen.dart'; // 에러 화면
// 정의되지 않은 라우트나 치명적인 에러 발생 시 보여줄 공통 에러 화면

// 앱 전체 공통 레이아웃 위젯들 (route는 아니지만 구조 파악용)
// import '../features/common/widgets/app_scaffold.dart'; -> AppBar / BottomNavBar 를 포함한 공통 Scaffold
// import '../features/common/widgets/bottom_nav_bar.dart'; -> 하단 탭바 위젯


//  ========== Auth 영역 (사용자가 누구인지 확인하는 기능) ==========
import '../features/auth/screens/login_screen.dart'; // 로그인 화면
// 로그인 화면에서 이메일/아이디 + 비밀번호 입력
// auth_service.dart 안에 로그인을 처리하는 클래스(AuthService 클래스)를 통해 Firebase Auth 로그인
// 성공 시 /home 으로 이동

import '../features/auth/screens/signup_screen.dart'; // 회원가입 화면
// 이름, 생년월일, 이메일, 아이디, 닉네임, 비밀번호 등 입력
// 가입 성공 후 관심 분야/커뮤니티 배정을 위해 community 쪽으로 연결

// Auth 관련 서비스/모델 (route는 아니지만 어떤 기능인지)
// import '../features/auth/models/user_profile.dart'; -> 유저 프로필 데이터 모델 (닉네임, 학교, 전공, 관심분야, 경험치 등)
// import '../features/auth/services/auth_service.dart'; -> 로그인/로그아웃/회원가입 등 인증 로직
// import '../features/auth/services/profile_service.dart'; -> 프로필 조회/수정, 프로필 이미지 업로드 등
// import '../features/auth/widgets/error_banner.dart'; -> 로그인/회원가입 에러 메시지 표시용 배너 위젯


// ========== 커뮤니티 영역 ==========
import '../features/community/screens/category_select_screen.dart'; // 회원가입 이후 관심 분야 기반으로 커뮤니티 카테고리 선택하는 화면
// 개발/IT, 디자인/예술, 공기업 등 관심있는 커뮤니티의 카테고리 선택하면 "이 커뮤니티에 가입하시겠습니까?" 다이얼로그 표시
// 최종 확인이 되면 프로필의 mainCommunity로 저장되면서 메인 홈으로 이동
// 또는 설정 탭에서 "커뮤니티 변경"을 누르면 나오는 화면

import '../features/community/screens/main_community_screen.dart'; // 사용자의 커뮤니티 내 홈 화면

// import '../features/community/models/community.dart'; -> 커뮤니티 ID, 이름, 카테고리, 설명 등을 담는 데이터 모델
// import '../features/community/services/community_service.dart'; -> 관심분야 기반 자동 배정, 커뮤니티 목록 조회/변경 로직


// ========= 게시판 영역 =========
import '../features/board/screens/board_tabs_screen.dart'; // 커뮤니티 내 게시판 메인 화면
// - 자유/스펙공유/스터디모집/취준/기업후기 탭으로 나뉜 게시판 리스트

import '../features/board/screens/post_detail_screen.dart'; // 게시글 상세 화면
// 게시글 제목/본문/첨부파일/좋아요/댓글/대댓글 표시
// 신고/차단 기능으로 연결

import '../features/board/screens/post_editor_screen.dart'; // 게시글 작성/수정 화면
// 게시판 종류에 따라 필수 입력 필드(작성 틀)가 다르게 표시됨
// 작성 완료 시 BoardService 로 저장, 수정 시 기존 데이터 업데이트

// import '../features/board/models/post.dart'; -> 게시글 데이터 모델 (title, content, authorId, createdAt 등)
// import '../features/board/models/post_template.dart'; -> 게시판 종류별로 다른 "작성 틀" 정의
// import '../features/board/models/board_category.dart'; -> 자유/스펙공유/스터디/취준/기업후기 등 게시판 유형 정보
// import '../features/board/services/board_service.dart'; -> 글 목록 조회, 작성/수정/삭제, 좋아요 등 게시판 비즈니스 로직
// import '../features/board/services/report_block_service.dart'; -> 신고/차단 기능 처리 (무관/위반 게시글 숨기기/삭제)
// import '../features/board/widgets/post_card.dart'; -> 게시글 목록에서 한 개의 게시글을 카드 형태로 보여주는 위젯
// import '../features/board/widgets/template_fields.dart'; -> 게시판별 필수 입력 필드를 생성해주는 UI 위젯


// ========= 캘린더 영역 =========
import '../features/calendar/screens/calendar_screen.dart'; // 캘린더 메인 화면 (월간 달력 뷰)
// 상단 : 한 달 단위 월간 달력 뷰 (MonthView 위젯 사용)
// 하단 : 곧 마감되는 일정부터, 마감일이 먼 일정 순으로 쭉 나열되는 리스트 (공모전 / 자격증 / 채용 / 챌린지 등 모든 일정 포함)

// 이 기능은 없는 거죠 ??
// import '../features/calendar/screens/schedule_detail_sheet.dart';
// // 캘린더에서 특정 일정을 눌렀을 때 뜨는 상세 화면
// // - 제목, 일시, 링크, 좋아요 버튼, 설명 등을 표시

// import '../features/calendar/models/schedule.dart'; -> 일정 데이터 모델 (title, dateTime, category, link 등)
// import '../features/calendar/services/calendar_service.dart'; -> 일정 등록/수정/삭제, 목록 조회 로직
// import '../features/calendar/services/deadline_alarm_service.dart'; -> 마감 하루 전 알림 등록/관리
// import '../features/calendar/services/like_service.dart'; -> 일정 "관심" 토글 처리
// import '../features/calendar/widgets/month_view.dart'; -> 달력을 실제로 그려주는 위젯


// ========== 챌린지 / XP 영역 ==========
import '../features/challenge/screens/challenge_list_screen.dart'; // 챌린지 메인 화면
// 홈 화면에서 "챌린지 등록" 버튼을 누르면 나오는 화면
// 상단 : "심사기준 확인하기" 버튼, 현재 검토 중인 사진 상황
// 가운데 : "사진 인증하기", "인증 내역 확인하기" 버튼
// 하단 : 레벨별 배지 카드(NEWBIE~VIP)가 나열되어 현재 등급과 다음 등급 기준을 시각적으로 보여줌
// - "사진 인증하기" → ProofCameraScreen 으로 이동
// - "인증 내역 확인하기" → ChallengeDetailScreen 으로 이동

import '../features/challenge/screens/challenge_detail_screen.dart'; // 인증 내역 화면
// ChallengeListScreen에서 "인증 내역 확인하기" 버튼을 누르면 진입

import '../features/challenge/screens/proof_camera_screen.dart'; // 챌린지 증빙 사진 촬영/업로드 화면
// 카메라/갤러리에서 이미지 선택
// ChallengeListScreen에서 "사진 인증하기" 버튼을 누르면 진입
// 사진 촬영이 성공하면 서버/관리자 검토 이후 상태(검토 중/반려/성공)는 ChallengeListScreen에서 메시지로 노출

// import '../features/challenge/models/challenge.dart'; -> 챌린지 전체에 대한 정보 모델 (제목, 설명, 보상 XP 등)
// import '../features/challenge/models/proof_result.dart'; -> 사용자가 올린 인증 사진 하나가 가지고 있는 정보 모델 (어떤 챌린지 인증인지, 어떤 유저가 올렸는지, 상태 등)
// import '../features/challenge/services/challenge_service.dart'; -> 내 현재 레벨/경험치 조회, 챌린지 목록/상세 조회, 레벨업 조건 계산 로직
// import '../features/challenge/services/proof_service.dart'; -> 사용자가 올린 사진을 처리하는 핵심 로직 (올린 사진을 검토하고 경험치 지급을 책임짐)


// ========= 채팅 영역 =========
import '../features/chat/screens/chat_list_screen.dart'; // 채팅 목록 화면
// 하단 탭에서 "채팅" 누르면 보이는 화면
// 그동안 참여했던 채팅방 리스트를 최신 순으로 보여줌.
// 상단 AppBar 오른쪽에 + 버튼으로 새 채팅방 만들기 (친구 검색 후 초대)

import '../features/chat/screens/chat_room_screen.dart'; // 채팅방 내 화면
// 이미지/파일 전송, 차단/나가기 버튼 등의 UI
// 차단 또는 나가기 아이콘을 누르면 확인 다이얼로그를 띄운 뒤 차단 또는 나가기 처리함.

import '../features/chat/screens/new_chat_screen.dart'; // 새 채팅방 생성 화면
// ChatListScreen에서 + 를 누르면 나오는 화면
// 상단 : 현재 초대한 친구 목록 표시
// 중앙 : 닉네임 + 아이디로 사용자 검색
// 하단 : 검색에 맞는 사용자들 리스트 표시
// 참여자를 선택한 뒤 "채팅방 생성"을 하면 새로운 채팅방을 만들고 ChatRoomScreen 으로 이동

// import '../features/chat/models/chat_room.dart'; -> 채팅방 메타데이터 (참여자 목록, 방 제목 등)
// import '../features/chat/models/message.dart'; -> 개별 메시지 데이터 (senderId, text, createdAt 등)
// import '../features/chat/services/chat_service.dart'; -> 메시지 송수신, Firestore/Realtime DB 연동
// import '../features/chat/services/block_service.dart'; -> 사용자 차단/해제 처리
// import '../features/chat/widgets/message_bubble.dart'; -> 채팅방에서 각 메시지를 말풍선 UI로 그려주는 위젯


// ========= 설정 영역 =========
import '../features/settings/screens/setting_screen.dart'; // 설정 메인 화면
// 하단 탭에서 "설정"을 누르면 진입
// 상단 : 프로필 정보 (사진, 닉네임, #번호, 전공/커뮤니티, 레벨) 표시
// 하단 :
//      계정: 아이디 변경, 비밀번호 변경, 닉네임 변경
//      게시물: 내가 쓴 게시물 / 내가 쓴 댓글
//      커뮤니티: 커뮤니티 변경
// 프로필 사진 변경 기능 포합 (앨범에서 선택, 기본 이미지 선택)

import '../features/settings/screens/id_change_screen.dart'; // [설정 > 아이디 변경] 화면

import '../features/settings/screens/password_change_screen.dart'; // [설정 > 비밀번호 변경] 화면
// 현재 비밀번호, 새 비밀번호, 새 비밀번호 확인 입력
// 유효성 검사(길이, 일치 여부 등) 후 Profile/AuthService를 통해 비밀번호 변경
// 성공 시 토스트 안내 후 이전 화면으로 돌아감

import '../features/settings/screens/nickname_change_screen.dart'; // [설정 > 닉네임 변경] 화면
// 현재 닉네임을 보여주고, 새 닉네임 입력 필드 제공
// 닉네임 중복 체크/형식 검사 후 ProfileService를 통해 저장
// 성공 시 설정 메인 화면으로 돌아가고 프로필 카드에 즉시 반영

import '../features/settings/screens/community_change_screen.dart'; // [설정 > 커뮤니티 변경] 화면
// 다른 커뮤니티 목록 제공
// 원하는 커뮤니티를 선택하면 "이 커뮤니티로 변경하시겠습니까?" 확인 다이얼로그 표시
// 확인 시 사용자의 mainCommunity를 변경하고, 홈/게시판/캘린더 등에서 해당 커뮤니티 기준으로 콘텐츠가 보이도록 업데이트

import '../features/settings/screens/my_posts_screen.dart'; // [설정 > 내가 쓴 게시물] 화면
// 내가 작성한 모든 게시글을 목록으로 보여줌

import '../features/settings/screens/my_comments_screen.dart'; // [설정 > 내가 쓴 댓글] 화면
// 내가 작성한 댓글들을 모아 보여주는 화면
// 댓글 내용 일부, 작성 시각 등을 함께 표시


// ====================== AppRoutes 본체 ======================
//
// 앱 전체의 “화면 경로 → 실제 위젯” 매핑을 담당하는 클래스.
// route_names.dart 에 정의한 RouteNames.* 상수와 1:1로 대응됨.
// main.dart 예시
//    MaterialApp(
//      initialRoute: RouteNames.splash,
//      routes: AppRoutes.routes,
//      onGenerateRoute: AppRoutes.onGenerateRoute,
//    );
//
class AppRoutes {
  /// 인자가 필요 없는 단순 화면들에 대한 라우트 맵.
  /// 대부분의 메인 탭/목록/상세 없이 진입하는 화면은 여기에서 처리.
  static final Map<String, WidgetBuilder> routes = {
    // --- 공통 ---
    RouteNames.splash: (context) => const SplashScreen(),
    RouteNames.error:  (context) => const ErrorScreen(),

    // --- Auth ---
    RouteNames.login:  (context) => const LoginScreen(),
    RouteNames.signup: (context) => const SignupScreen(),

    // --- 홈(탭 루트) ---
    RouteNames.home:   (context) => const HomeScreen(),

    // --- 커뮤니티 (회원가입/변경 공용) ---
    RouteNames.categorySelect: (context) => const CategorySelectScreen(),
    // 회원가입 직후 관심 분야 기반 커뮤니티 선택 화면
    RouteNames.mainCommunity:  (context) => const MainCommunityScreen(),
    // 사용자의 커뮤니티 홈(필요 시 사용)

    // --- 게시판 루트(탭 화면) ---
    RouteNames.board:  (context) => const BoardTabsScreen(),

    // --- 캘린더 루트 ---
    RouteNames.calendar: (context) => const CalendarScreen(),

    // --- 채팅 루트 ---
    RouteNames.chat: (context) => const ChatListScreen(),

    // --- 챌린지 루트 ---
    RouteNames.challenge: (context) => const ChallengeListScreen(),

    // --- 설정 루트 & 설정 하위 화면들 ---
    RouteNames.settings:        (context) => const SettingScreen(),
    // [설정 > 계정 > 아이디 변경]
    RouteNames.idChange:        (context) => const IdChangeScreen(),
    // [설정 > 계정 > 비밀번호 변경]
    RouteNames.passwordChange:  (context) => const PasswordChangeScreen(),
    // [설정 > 계정 > 닉네임 변경]
    RouteNames.nicknameChange:  (context) => const NicknameChangeScreen(),
    // [설정 > 커뮤니티 변경]
    RouteNames.communityChange: (context) => const CommunityChangeScreen(),
    // [설정 > 내가 쓴 게시물]
    RouteNames.myPosts:         (context) => const MyPostsScreen(),
    // [설정 > 내가 쓴 댓글]
    RouteNames.myComments:      (context) => const MyCommentsScreen(),
  };

  /// arguments(게시글/챌린지/채팅방 ID 등)가 필요한 화면을 처리하는 곳.
  ///
  /// 예)
  /// ```dart
  /// Navigator.pushNamed(
  ///   context,
  ///   RouteNames.postDetail,
  ///   arguments: post,   // 또는 postId
  /// );
  /// ```
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

    // ------------- 게시판 상세/작성 -------------
      case RouteNames.postDetail:
      // arguments 로 Post 객체나 postId 를 받는다고 가정
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            // TODO: 실제 생성자에 맞게 수정
          ),
          settings: settings,
        );

      case RouteNames.postEditor:
      // 새 글 작성(인자 없음) 또는 수정(기존 Post 전달) 둘 다 지원 가능
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => PostEditorScreen(
            // TODO: 실제 생성자에 맞게 수정
          ),
          settings: settings,
        );

    // ------------- 챌린지 상세 & 증빙 업로드 -------------
      case RouteNames.challengeDetail:
      // 예: 특정 챌린지 정보나 id 를 넘길 수 있음
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => ChallengeDetailScreen(
            // TODO: 실제 생성자에 맞게 수정
          ),
          settings: settings,
        );

      case RouteNames.proofCamera:
      // 예: 어떤 챌린지에 대한 인증인지 challengeId 등을 넘길 수도 있음
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => ProofCameraScreen(
            // TODO: 필요 시 인자 사용
          ),
          settings: settings,
        );

    // ------------- 채팅방 / 새 채팅 -------------
      case RouteNames.chatRoom:
      // arguments 로 ChatRoom 이나 roomId 를 받는다고 가정
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            // TODO: 실제 생성자에 맞게 수정
          ),
          settings: settings,
        );

      case RouteNames.newChat:
      // 새 채팅방 생성 화면 (일반 화면 형태, 다이얼로그 아님)
        return MaterialPageRoute(
          builder: (_) => const NewChatScreen(),
          settings: settings,
        );

    }

    // 여기까지 왔다면 정의되지 않은 경로 → 공통 에러 화면으로 보냄
    return MaterialPageRoute(
      builder: (_) => ErrorScreen(
        unknownRouteName: settings.name,
      ),
      settings: settings,
    );
  }
}


