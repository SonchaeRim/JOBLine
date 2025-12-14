# 📱 취준생 커뮤니티 앱 (Flutter)

> Android / iOS 지원  
> 고급 모바일 프로그래밍 팀 프로젝트로
> 대학생&취준생을 위한 취업 커뮤니티 앱을 구현함.

---

## 👥 팀 구성 및 역할 

| 역할 | 이름(예시) | 담당 기능 | 설명 |
|------|-------------|-----------|------|
| **A. 앱 뼈대·라우팅 담당 (스캐폴드 리드)** | - | 프로젝트 생성, 폴더 구조, 하단 탭/화면 전환, 공통 위젯(버튼/입력창) 제작 | 다른 팀원이 만든 화면을 “앱에 연결”하는 허브 역할 |
| **B. 계정·프로필/미디어 담당 (사용자 기능 리드)** | - | 이메일 로그인/회원가입, 프로필 보기·수정, 사진 업로드(Storage) | 사용자 정보 관리 전반 담당 |
| **C. 게시판·댓글 담당 (콘텐츠 리드)** | - | 게시글 목록/작성/상세, 댓글·좋아요 | 리스트 스크롤 성능과 DB 연동 기본 구현 |
| **D. 일정·알림·채팅 담당 (소통 리드)** | - | 캘린더 목록/상세, 마감 D-1 알림(간단 FCM), 1:1 채팅(텍스트) | 알림/실시간 기능 중심 |

---

## 🏗️ 폴더 구조


| Path            | 설명                            |
| --------------- | ----------------------------- |
| `lib/main.dart` | 앱 진입점                         |
| `lib/config/`   | 환경 설정 (Firebase, 상수 등)        |
| `lib/core/`     | 전역 공통 리소스 (테마, 색상, 유틸, 공용 위젯) |
| `lib/routes/`   | 라우팅(화면 이동) 정의                 |
| `lib/features/` | 주요 기능(도메인)별 모듈                |

| Module                | Subfolders                                     | 설명                |
| --------------------- | ---------------------------------------------- | ----------------- |
| `features/auth/`      | `models/`, `screens/`, `services/`, `widgets/` | 로그인, 회원가입, 프로필    |
| `features/board/`     | `models/`, `screens/`, `services/`, `widgets/` | 게시판, 댓글, 좋아요      |
| `features/calendar/`  | `models/`, `screens/`, `services/`, `widgets/` | 일정 및 마감 알림        |
| `features/chat/`      | `models/`, `screens/`, `services/`, `widgets/` | 채팅 기능 (1:1, 차단 등) |
| `features/challenge/` | `models/`, `screens/`, `services/`, `widgets/` | 챌린지 및 인증 기능       |
| `features/community/` | `models/`, `screens/`, `services/`, `widgets/` | 커뮤니티 배정 및 변경      |
| `features/xp/`        | `models/`, `services/`, `widgets/`             | 경험치 및 레벨 시스템      |

| Folder      | 의미                           |
| ----------- | ---------------------------- |
| `models/`   | 데이터 구조(모델) 정의                |
| `screens/`  | 화면(UI) 단위                    |
| `services/` | 비즈니스 로직 / Firebase 연동 / CRUD |
| `widgets/`  | 재사용 UI 컴포넌트                  |



---

### 🧩 파일별 역할 요약

#### `main.dart`
- 앱의 진입점 (`runApp()` 함수)
- 라우팅 및 테마 설정

---

### 📂 config/ 환경 설정 (Firebase, 상수 등)

| 파일명 | 설명 |
|--------|------|
| **firebase_options.dart** | Firebase 초기 설정 자동 생성 파일 (`flutterfire configure`로 생성됨) |
| **app_config.dart** | 환경 설정 상수 (앱 이름, 버전, Firestore 컬렉션 이름 등) |

---

### 📂 core/ 전역 공통 리소스 (테마, 색상, 유틸, 공용 위젯)

| 파일명 | 설명 |
|--------|------|
| **app_colors.dart / app_text_styles.dart** | 전역 색상·폰트 정의 |
| **helpers.dart** | 날짜 포맷 등 공통 함수 |
| **validators.dart** | 입력값 유효성 검사 (이메일, 비밀번호 등) |
| **common_button.dart / input_field.dart** | 모든 화면에서 재사용되는 버튼/입력창 위젯 |

---

### 📂 routes/ 라우팅(화면 이동) 정의

| 파일명 | 설명 |
|--------|------|
| **app_routes.dart** | 화면 이동(go_router / Navigator 설정) |
| **route_names.dart** | 각 화면의 라우트 이름 상수화 (ex: `/login`, `/board/detail`) |

---

### 📂 features/auth/  *(로그인·프로필·미디어)*

| 파일명 | 설명 |
|--------|------|
| **models/user_profile.dart** | 사용자 정보 데이터 구조 정의 (이름, 이메일, XP 등) |
| **screens/login_screen.dart** | 이메일 로그인 화면 |
| **screens/signup_screen.dart** | 회원가입 화면 |
| **screens/profile_screen.dart** | 프로필 조회 화면 |
| **screens/profile_edit_screen.dart** | 프로필 수정 화면 (사진 업로드 포함) |
| **services/auth_service.dart** | Firebase Auth 로그인/회원가입 처리 |
| **services/profile_service.dart** | Firestore/Storage와 프로필 데이터 연동 |
| **widgets/profile_avatar.dart** | 프로필 이미지 표시 위젯 |

---

### 📂 features/board/  *(게시판·댓글)*

| 파일명 | 설명 |
|--------|------|
| **models/post.dart** | 게시글 데이터 모델 |
| **models/board_category.dart** | 게시판 카테고리 정의 (자유, 취준, 스터디 등) |
| **screens/board_tabs_screen.dart** | 게시판 탭별 목록 화면 |
| **screens/post_editor_screen.dart** | 게시글 작성/수정 화면 |
| **screens/post_detail_screen.dart** | 게시글 상세 화면 (댓글, 좋아요 포함) |
| **services/board_service.dart** | 게시글 CRUD 및 Firestore 연동 |
| **services/report_block_service.dart** | 게시글 신고 및 차단 처리 |
| **widgets/post_card.dart** | 게시글 목록 카드 UI |
| **widgets/comment_item.dart** | 댓글 표시용 리스트 아이템 |

---

### 📂 features/calendar/  *(일정·알림)*

| 파일명 | 설명 |
|--------|------|
| **models/schedule.dart** | 일정 데이터 모델 |
| **screens/calendar_screen.dart** | 월별 달력 및 일정 리스트 화면 |
| **screens/schedule_detail_screen.dart** | 일정 상세 보기/편집 화면 |
| **services/calendar_service.dart** | Firestore 일정 CRUD 로직 |
| **services/deadline_alarm_service.dart** | 마감 D-1 알림 처리 (FCM 사용) |
| **widgets/calendar_month_view.dart** | 월별 달력 위젯 |
| **widgets/schedule_card.dart** | 일정 카드 UI |

---

### 📂 features/challenge/  *(챌린지·인증)*

| 파일명 | 설명 |
|--------|------|
| **models/challenge.dart** | 챌린지 데이터 구조 |
| **models/proof_result.dart** | 인증 결과 데이터 |
| **screens/challenge_list_screen.dart** | 챌린지 목록 화면 |
| **screens/challenge_detail_screen.dart** | 챌린지 상세 보기 |
| **screens/proof_camera_screen.dart** | 인증 사진 촬영 화면 |
| **services/challenge_service.dart** | 챌린지 목록/진행 관리 |
| **services/proof_service.dart** | 인증 결과 저장, XP 부여 연동 |
| **widgets/challenge_card.dart** | 챌린지 카드 UI |
| **widgets/progress_bar.dart** | 진행도 표시 위젯 |

---

### 📂 features/chat/  *(1:1 채팅)*

| 파일명 | 설명 |
|--------|------|
| **models/chat_room.dart** | 채팅방 정보 구조 (참여자, 최근 메시지 등) |
| **models/message.dart** | 채팅 메시지 데이터 구조 |
| **screens/chat_list_screen.dart** | 채팅방 목록 화면 |
| **screens/chat_room_screen.dart** | 1:1 채팅방 화면 |
| **services/chat_service.dart** | 실시간 채팅 송수신 처리 (Firestore 기반) |
| **services/block_service.dart** | 사용자 차단/차단 해제 기능 |
| **widgets/message_bubble.dart** | 말풍선 형태의 메시지 UI |
| **widgets/chat_input_field.dart** | 메시지 입력창 위젯 |

---

### 📂 features/common/  *(앱 뼈대/탭바)*

| 파일명 | 설명 |
|--------|------|
| **home_screen.dart** | 앱 기본 홈 (탭바 포함) |
| **bottom_nav_bar.dart** | 하단 탭바 네비게이션 |
| **app_scaffold.dart** | 공통 Scaffold 위젯 (AppBar, Body, BottomNav 포함) |
| **splash_screen.dart** | 앱 로딩/인트로 화면 |
| **error_screen.dart** | 네트워크 오류/예외 처리 화면 |

---

### 📂 features/community/  *(커뮤니티 배정/변경)*

| 파일명 | 설명 |
|--------|------|
| **models/community.dart** | 커뮤니티 정보 구조 (카테고리, 인원수 등) |
| **screens/community_assign_screen.dart** | 초기 커뮤니티 배정 화면 |
| **screens/community_main_screen.dart** | 커뮤니티 메인 페이지 |
| **screens/community_switch_screen.dart** | 커뮤니티 변경/탐색 화면 |
| **services/community_service.dart** | 관심 분야 기반 자동 배정 로직 |
| **widgets/community_card.dart** | 커뮤니티 정보 표시 카드 |

---

### 📂 features/xp/  *(경험치/레벨 시스템)*

| 파일명 | 설명 |
|--------|------|
| **models/xp_rule.dart** | 경험치 규칙 정의 (행동별 포인트) |
| **services/xp_service.dart** | XP 계산, 누적, Firestore 저장 로직 |
| **widgets/xp_badge.dart** | XP·레벨 표시용 UI 배지 |
| **widgets/level_progress_bar.dart** | 경험치 진행도 표시 바 |

---

## ⚙️ 개발 환경
- **Flutter 3.35.7**
- **Dart 3.9.2**
- **Firebase (Auth, Firestore, Storage, FCM)**
- **Android Studio**

---

## 🚀 설치 패키지 주소
| Package (name:version)                 | Link                                                                                                         |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `path_provider: ^2.1.2`                | [https://pub.dev/packages/path_provider](https://pub.dev/packages/path_provider)                             |
| `image_picker: ^1.0.7`                 | [https://pub.dev/packages/image_picker](https://pub.dev/packages/image_picker)                               |
| `cached_network_image: ^3.4.1`         | [https://pub.dev/packages/cached_network_image](https://pub.dev/packages/cached_network_image)               |
| `flutter_doc_scanner: ^0.0.16`         | [https://pub.dev/packages/flutter_doc_scanner](https://pub.dev/packages/flutter_doc_scanner)                 |
| `permission_handler: ^11.3.1`          | [https://pub.dev/packages/permission_handler](https://pub.dev/packages/permission_handler)                   |
| `firebase_storage: ^12.4.10`           | [https://pub.dev/packages/firebase_storage](https://pub.dev/packages/firebase_storage)                       |
| `shared_preferences: ^2.2.2`           | [https://pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences)                   |
| `cupertino_icons: ^1.0.8`              | [https://pub.dev/packages/cupertino_icons](https://pub.dev/packages/cupertino_icons)                         |
| `firebase_core: ^3.10.0`               | [https://pub.dev/packages/firebase_core](https://pub.dev/packages/firebase_core)                             |
| `firebase_auth: ^5.3.1`                | [https://pub.dev/packages/firebase_auth](https://pub.dev/packages/firebase_auth)                             |
| `cloud_firestore: ^5.6.12`             | [https://pub.dev/packages/cloud_firestore](https://pub.dev/packages/cloud_firestore)                         |
| `firebase_messaging: ^15.1.3`          | [https://pub.dev/packages/firebase_messaging](https://pub.dev/packages/firebase_messaging)                   |
| `flutter_local_notifications: ^18.0.1` | [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |
| `intl: ^0.19.0`                        | [https://pub.dev/packages/intl](https://pub.dev/packages/intl)                                               |
| `flutter_layout_grid: ^2.0.4`          | [https://pub.dev/packages/flutter_layout_grid](https://pub.dev/packages/flutter_layout_grid)                 |
| `flutter_markdown: ^0.6.18`            | [https://pub.dev/packages/flutter_markdown](https://pub.dev/packages/flutter_markdown)                       |





