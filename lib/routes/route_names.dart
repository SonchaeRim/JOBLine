class RouteNames {
  // ========== 공통 ==========
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String error = '/error';

  // ========== 홈 영역 ==========
  static const String board = '/home/board';
  static const String calendar = '/home/calendar';
  static const String chat = '/home/chat';
  static const String challenge = '/home/challenge';
  static const String settings = '/home/settings';

  // ========== 캘린더 ==========
  static const String scheduleDetail = '/schedule-detail';

  // ========== 커뮤니티 ==========
  static const String categorySelect = '/community/category-select'; // 회원가입 이후 커뮤니티 선택
  static const String mainCommunity   = '/community/main';           // 커뮤니티 홈

  // ========== 게시판 ==========
  static const String postList   = '/home/board/list';
  static const String postDetail = '/home/board/detail';
  static const String postEditor = '/home/board/editor';

  // ========== 챌린지 ==========
  static const String photoProof = '/home/challenge/photo-proof';
  static const String proofList = '/home/challenge/proof-list';
  static const String proofDetail = '/home/challenge/proof-detail';
  static const String reviewCriteria = '/home/challenge/review-criteria';
  static const String adminUserList = '/home/challenge/admin/user-list';
  static const String adminCertificationList = '/home/challenge/admin/certification-list';

  // ========== 채팅 ==========
  static const String chatRoom = '/home/chat/room';
  static const String newChat  = '/home/chat/new';

  // ========== 설정 ==========
  static const String idChange         = '/home/settings/id-change';
  static const String passwordChange   = '/home/settings/password-change';
  static const String nicknameChange   = '/home/settings/nickname-change';
  static const String communityChange  = '/home/settings/community-change';
  static const String myPosts          = '/home/settings/my-posts';
  static const String myComments       = '/home/settings/my-comments';
}