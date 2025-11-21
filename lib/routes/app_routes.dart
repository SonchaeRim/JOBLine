import 'package:flutter/material.dart';

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
  // 첫 화면: 로그인 화면으로 지정
  static const String initial = '/home';

  // 모든 라우트 등록
  static final Map<String, WidgetBuilder> routes = {
    //'/login': (context) => const LoginScreen(),
    //'/signup': (context) => const SignupScreen(),
    '/home': (context) => const HomeScreen(),
    //'/board': (context) => const BoardTabsScreen(),
    //'/calendar': (context) => const CalendarScreen(),
    //'/chat': (context) => const ChatListScreen(),
  };
}