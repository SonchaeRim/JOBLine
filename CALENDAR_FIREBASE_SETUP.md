# 캘린더 및 알림 기능 설정 가이드

## 필요한 이유 (3줄 요약)
1. **일정 관리 및 알림 기능**: 사용자의 일정을 Firestore에 저장하고, FCM 푸시 알림을 통해 일정 전날, 1시간 전, 5분 전에 알림을 발송합니다.
2. **백엔드 스케줄링**: Firebase Functions와 Cloud Scheduler를 사용하여 정확한 시간에 알림을 전송하며, 앱이 종료되어도 알림이 동작합니다.
3. **팀 협업 환경**: 모든 개발자가 동일한 Firebase 프로젝트와 설정으로 작업할 수 있도록 환경 구성을 표준화합니다.

---

## 목차
1. [필수 사전 요구사항](#필수-사전-요구사항)
2. [Firebase 프로젝트 설정](#firebase-프로젝트-설정)
3. [FlutterFire CLI 설정](#flutterfire-cli-설정)
4. [Firebase Functions 설정](#firebase-functions-설정)
5. [Firestore 보안 규칙 및 인덱스](#firestore-보안-규칙-및-인덱스)
6. [Firebase Auth 설정](#firebase-auth-설정)
7. [앱 실행 및 테스트](#앱-실행-및-테스트)

---

## 필수 사전 요구사항

### 1. Node.js 설치
- **버전**: Node.js 20 이상
- **설치 확인**:
  ```powershell
  node --version
  ```
- **다운로드**: https://nodejs.org/

### 2. Firebase CLI 설치
```powershell
# Firebase CLI 설치
npm install -g firebase-tools

# PATH 설정 (PowerShell에서 실행)
$env:Path += ";$env:APPDATA\npm"

# 설치 확인
firebase --version
```

### 3. FlutterFire CLI 설치
```powershell
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# PATH 설정 (PowerShell에서 실행)
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"

# 설치 확인
flutterfire --version
```

---

## Firebase 프로젝트 설정

### 1. Firebase Console 접속
- https://console.firebase.google.com 접속
- 프로젝트: `jobline-d1064` 선택

### 2. Android 앱 확인
- Firebase Console → 프로젝트 설정 → 내 앱
- Android 앱이 등록되어 있는지 확인
- `google-services.json` 파일이 `android/app/` 폴더에 있는지 확인

### 3. FlutterFire CLI로 설정 동기화
```powershell
# 프로젝트 루트에서 실행
flutterfire configure
```
- 프로젝트 선택: `jobline-d1064`
- 플랫폼 선택: `android` (필요시 `ios`도 선택 가능)
- 기존 설정 덮어쓰기: `y`

---

## Firebase Functions 설정

### 1. Firebase CLI 로그인
```powershell
firebase login
```

### 2. 프로젝트 선택
```powershell
firebase use jobline-d1064
```

### 3. Functions 의존성 설치
```powershell
cd functions
npm install
cd ..
```

### 4. Functions 빌드
```powershell
cd functions
npm run build
cd ..
```

### 5. Functions 배포
```powershell
firebase deploy --only functions
```

**배포되는 함수들:**
- `onNotificationRequestCreated`: 알림 요청 생성 시 `notification_jobs` 생성
- `onNotificationRequestUpdated`: 알림 요청 취소 시 관련 작업 삭제
- `onScheduleDeleted`: 일정 삭제 시 관련 알림 요청/작업 삭제
- `processScheduledNotifications`: 1분마다 실행되어 알림 시간이 된 작업 처리

### 6. 필요한 API 활성화
Firebase Console에서 다음 API들이 활성화되어 있어야 합니다:
- Cloud Functions API
- Cloud Build API
- Artifact Registry API
- Cloud Scheduler API

**활성화 방법:**
1. Firebase Console → 프로젝트 설정 → API 탭
2. 위 API들이 활성화되어 있는지 확인
3. 비활성화되어 있으면 "사용 설정" 클릭

---

## Firestore 보안 규칙 및 인덱스

### 1. 보안 규칙 설정
Firebase Console → Firestore Database → Rules 탭에서 다음 규칙 적용:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // schedules 컬렉션
    match /schedules/{scheduleId} {
      allow read, write: if request.auth != null;
    }
    
    // notification_requests 컬렉션
    match /notification_requests/{requestId} {
      allow read, write: if request.auth != null;
    }
    
    // notification_jobs 컬렉션 (Functions에서만 접근)
    match /notification_jobs/{jobId} {
      allow read, write: if false; // 클라이언트에서는 접근 불가
    }
    
    // 기타 컬렉션들...
  }
}
```

### 2. 인덱스 생성
Firebase Console → Firestore Database → Indexes 탭에서 다음 인덱스 생성:

**필수 인덱스:**
1. **schedules 컬렉션**:
   - Collection: `schedules`
   - Fields: `ownerId` (Ascending), `startDate` (Ascending)
   - Query scope: Collection

2. **notification_jobs 컬렉션**:
   - Collection: `notification_jobs`
   - Fields: `status` (Ascending), `notificationTime` (Ascending)
   - Query scope: Collection

**또는 코드로 배포:**
```powershell
firebase deploy --only firestore:indexes
```

---

## Firebase Auth 설정

### 1. Anonymous 인증 활성화
Firebase Console → Authentication → Sign-in method 탭:
1. "Anonymous" 찾기
2. "사용 설정" 클릭
3. 저장

**주의**: 현재 개발용으로 익명 인증을 사용하고 있습니다. 실제 로그인 기능 구현 시 이 부분을 제거해야 합니다.

---

## 앱 실행 및 테스트

### 1. Flutter 의존성 설치
```powershell
flutter pub get
```

### 2. 앱 실행
```powershell
# Android 에뮬레이터 또는 실제 기기에서 실행
flutter run
```

### 3. 테스트 체크리스트

#### 일정 기능 테스트
- [ ] 일정 추가: 캘린더 화면에서 "+" 버튼 클릭하여 일정 추가
- [ ] 일정 수정: 일정 클릭 → 수정 버튼 → 내용 변경 → 저장
- [ ] 일정 삭제: 일정 상세 화면에서 삭제 버튼 클릭
- [ ] 필터 기능: 헤더의 필터 버튼으로 카테고리별 필터링

#### 알림 기능 테스트
- [ ] 알림 설정: 일정 추가/수정 시 "알림 받기" 체크박스 활성화
- [ ] 알림 토글: 캘린더 화면에서 일정의 알림 아이콘 클릭하여 켜기/끄기
- [ ] 알림 수신: 일정 시간 5분 전, 1시간 전, 하루 전에 알림 수신 확인
- [ ] 백그라운드 알림: 앱을 백그라운드로 보낸 후 알림 수신 확인
- [ ] 앱 종료 알림: 앱을 완전히 종료한 후 알림 수신 확인

#### Firestore 데이터 확인
- [ ] Firebase Console → Firestore Database에서 `schedules` 컬렉션 확인
- [ ] `notification_requests` 컬렉션에 알림 요청이 생성되는지 확인
- [ ] `notification_jobs` 컬렉션에 알림 작업이 생성되는지 확인
- [ ] 일정 삭제 시 관련 알림 요청/작업도 함께 삭제되는지 확인

---

## 문제 해결

### Firebase CLI를 찾을 수 없음
```powershell
# PATH 확인 및 추가
$env:Path += ";$env:APPDATA\npm"
firebase --version
```

### FlutterFire CLI를 찾을 수 없음
```powershell
# PATH 확인 및 추가
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
flutterfire --version
```

### Firebase Auth 익명 인증 실패
- Firebase Console → Authentication → Sign-in method에서 Anonymous 활성화 확인
- 에러 메시지: `[firebase_auth/admin-restricted-operation]`

### Firestore 권한 오류
- Firebase Console → Firestore Database → Rules에서 보안 규칙 확인
- `request.auth != null` 조건을 만족하는지 확인 (익명 인증 포함)

### Functions 배포 실패
- Node.js 버전 확인 (20 이상 필요)
- `cd functions` 후 `npm install` 다시 실행
- Firebase Console에서 필요한 API 활성화 확인

### 알림이 오지 않음
1. Firebase Console → Functions → Logs에서 에러 확인
2. Firebase Console → Firestore Database에서 `notification_jobs` 상태 확인
3. 앱의 알림 권한 확인 (Android 설정 → 앱 → 알림)
4. FCM 토큰 확인: 앱 실행 시 콘솔 로그에서 FCM 토큰 출력 확인

---

## 주요 파일 구조

```
jobline/
├── lib/
│   ├── main.dart                          # Firebase 초기화 및 FCM 설정
│   └── features/
│       └── calendar/
│           ├── models/
│           │   └── schedule.dart          # 일정 데이터 모델
│           ├── screens/
│           │   ├── calendar_screen.dart    # 캘린더 메인 화면
│           │   └── schedule_detail_screen.dart  # 일정 상세/편집 화면
│           └── services/
│               ├── calendar_service.dart   # Firestore CRUD 서비스
│               └── fcm_notification_service.dart  # FCM 알림 서비스
├── functions/
│   ├── src/
│   │   └── index.ts                       # Firebase Functions 로직
│   ├── package.json                       # Node.js 의존성
│   └── tsconfig.json                      # TypeScript 설정
├── firebase.json                          # Firebase 프로젝트 설정
├── firestore.indexes.json                 # Firestore 인덱스 정의
└── android/
    └── app/
        └── google-services.json           # Firebase Android 설정 (자동 생성)
```

---

## 개발 시 주의사항

1. **익명 인증**: 현재 개발용으로 익명 인증을 사용 중입니다. 실제 로그인 기능 구현 시 `main.dart`의 익명 인증 코드를 제거해야 합니다.

2. **Firestore 인덱스**: 복합 쿼리를 사용하는 경우 인덱스가 필요합니다. 에러 메시지에 표시된 링크를 통해 인덱스를 생성하세요.

3. **Functions 배포**: 코드 변경 후 `firebase deploy --only functions`로 재배포해야 합니다.

4. **FCM 토큰**: 각 디바이스마다 고유한 FCM 토큰이 발급됩니다. 토큰은 `users/{userId}` 문서에 저장하도록 구현되어 있습니다 (현재는 TODO 상태).

5. **알림 중복 방지**: 같은 `scheduleId`의 알림 요청이 중복 생성되지 않도록 트랜잭션을 사용하여 처리합니다.

---

## 추가 리소스

- Firebase 공식 문서: https://firebase.google.com/docs
- FlutterFire 문서: https://firebase.flutter.dev/
- Firebase Functions 문서: https://firebase.google.com/docs/functions
- Cloud Messaging 문서: https://firebase.google.com/docs/cloud-messaging


