# 테스트 가이드 (D 담당 기능)

## 📋 테스트 전 준비사항

### 1. Firestore 인덱스 생성
Firebase Console에서 다음 복합 인덱스를 생성해야 합니다:

1. **schedules**:
   - Collection: `schedules`
   - Fields: `ownerId` (Ascending), `startDate` (Ascending)

2. **schedules (deadline)**:
   - Collection: `schedules`
   - Fields: `ownerId` (Ascending), `isDeadline` (Ascending), `startDate` (Ascending)

3. **certifications**:
   - Collection: `certifications`
   - Fields: `userId` (Ascending), `challengeId` (Ascending), `proofDate` (Descending)

4. **xp_logs**:
   - Collection: `xp_logs`
   - Fields: `userId` (Ascending), `createdAt` (Descending)

**인덱스 생성 방법**:
1. Firebase Console → Firestore Database → Indexes
2. "Create Index" 클릭
3. 위의 필드들을 순서대로 추가
4. 인덱스 생성 완료 대기 (몇 분 소요)

### 2. Firestore 보안 규칙 설정
Firebase Console → Firestore Database → Rules에서 다음 규칙 적용:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // schedules 컬렉션
    match /schedules/{scheduleId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.ownerId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.ownerId;
    }
    
    // challenges 컬렉션 (읽기만 허용)
    match /challenges/{challengeId} {
      allow read: if request.auth != null;
      allow write: if false; // 관리자만 작성 가능
    }
    
    // certifications 컬렉션
    match /certifications/{certificationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
    
    // xp_logs 컬렉션
    match /xp_logs/{logId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow write: if false; // 서버/서비스에서만 작성
    }
    
    // users 컬렉션 (XP 필드만 업데이트)
    match /users/{userId} {
      allow read: if request.auth != null;
      allow update: if request.auth != null && 
        request.auth.uid == userId &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['totalXp', 'level', 'updatedAt']);
    }
  }
}
```

**테스트용 간단한 규칙 (개발 중)**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // 개발 중에만 사용
    }
  }
}
```

---

## 🚀 테스트 방법

### 방법 1: 라우팅 연결 후 테스트 (권장)

#### 1단계: 라우팅 연결 (A 담당과 협업)
`lib/routes/app_routes.dart`에 다음을 추가:

```dart
import '../features/calendar/screens/calendar_screen.dart';
import '../features/challenge/screens/challenge_list_screen.dart';

// routes 맵에 추가:
'/calendar': (context) => const CalendarScreen(),
'/challenge': (context) => const ChallengeListScreen(),
```

#### 2단계: 홈 화면에서 접근
`lib/features/common/screens/home_screen.dart`의 버튼에 라우팅 추가:

```dart
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/calendar');
  },
  child: const Text('캘린더 가기'),
),
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/challenge');
  },
  child: const Text('챌린지 가기'),
),
```

#### 3단계: 앱 실행
```bash
flutter run
```

---

### 방법 2: 직접 화면 테스트 (빠른 테스트)

#### 임시 테스트 화면 생성
`lib/features/common/screens/home_screen.dart`를 임시로 수정:

```dart
import '../calendar/screens/calendar_screen.dart';
import '../challenge/screens/challenge_list_screen.dart';

// 버튼에 직접 화면 이동:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
  },
  child: const Text('캘린더 가기'),
),
```

---

## 📝 테스트 시나리오

### 1. 캘린더 기능 테스트

#### 테스트 1: 일정 추가
1. 캘린더 화면 진입
2. 우측 상단 "+" 버튼 클릭
3. 일정 정보 입력:
   - 제목: "면접 준비"
   - 날짜: 내일
   - 시간: 오후 2시
   - 설명: "삼성전자 면접"
   - 카테고리: "면접"
   - 마감일로 설정: 체크
4. "저장" 버튼 클릭
5. ✅ 확인: 일정이 리스트에 표시됨

#### 테스트 2: 일정 수정
1. 일정 카드 클릭
2. 제목 수정
3. "저장" 버튼 클릭
4. ✅ 확인: 수정된 내용이 반영됨

#### 테스트 3: 일정 삭제
1. 일정 카드 클릭
2. 우측 상단 삭제 버튼 클릭
3. 확인 다이얼로그에서 "삭제" 클릭
4. ✅ 확인: 일정이 리스트에서 사라짐

#### 테스트 4: 월별 일정 조회
1. 캘린더 화면에서 좌우 화살표로 월 변경
2. ✅ 확인: 해당 월의 일정만 표시됨

---

### 2. 챌린지 기능 테스트

#### 사전 준비: 테스트 챌린지 데이터 생성
Firebase Console → Firestore → `challenges` 컬렉션에 다음 문서 추가:

```json
{
  "title": "매일 운동하기",
  "description": "하루에 30분 이상 운동하기",
  "durationDays": 30,
  "targetCount": 20,
  "xpReward": 100,
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-31T23:59:59Z",
  "createdAt": "2024-01-01T00:00:00Z",
  "isActive": true,
  "category": "건강"
}
```

#### 테스트 1: 챌린지 목록 조회
1. 챌린지 화면 진입
2. ✅ 확인: 활성화된 챌린지 목록이 표시됨

#### 테스트 2: 챌린지 상세 보기
1. 챌린지 카드 클릭
2. ✅ 확인: 챌린지 상세 정보 표시
3. ✅ 확인: 진행도 표시 (0%)

#### 테스트 3: 인증 등록
1. 챌린지 상세 화면에서 "인증하기" 버튼 클릭
2. 인증 설명 입력: "오늘 30분 러닝 완료"
3. "인증 제출" 버튼 클릭
4. ✅ 확인: "인증이 완료되었습니다! +10 XP" 메시지 표시
5. ✅ 확인: 챌린지 상세 화면으로 돌아가서 진행도 증가 확인

#### 테스트 4: 인증 내역 확인
1. 챌린지 상세 화면에서 "인증 내역" 섹션 확인
2. ✅ 확인: 등록한 인증이 표시됨
3. ✅ 확인: "+10 XP" 표시 확인

---

### 3. XP 시스템 테스트

#### 테스트 1: XP 획득 확인
1. 인증 등록 후
2. Firestore Console → `users/test_user_12345` 문서 확인
3. ✅ 확인: `totalXp` 필드가 10으로 증가
4. ✅ 확인: `level` 필드가 0 (100 XP 미만)

#### 테스트 2: 레벨 업 확인
1. 여러 번 인증 등록 (총 10회 이상)
2. Firestore Console → `users/test_user_12345` 확인
3. ✅ 확인: `totalXp`가 100 이상이면 `level`이 1로 증가

#### 테스트 3: XP 로그 확인
1. Firestore Console → `xp_logs` 컬렉션 확인
2. ✅ 확인: 각 인증마다 로그가 기록됨
3. ✅ 확인: `action`, `amount`, `totalXp`, `level` 필드 확인

#### 테스트 4: XP 배지 위젯 테스트
1. 홈 화면에 XP 배지 위젯 추가 (임시):
```dart
import '../xp/widgets/xp_badge.dart';

// body에 추가:
XpBadge(userId: 'test_user_12345'),
```
2. ✅ 확인: 레벨과 XP가 표시됨
3. ✅ 확인: 진행도 바가 표시됨

---

## 🔍 Firestore 데이터 확인

### 확인할 컬렉션

1. **schedules**: 일정 데이터
   - `ownerId`: "test_user_12345"
   - `title`, `startDate`, `isDeadline` 등 확인

2. **challenges**: 챌린지 데이터
   - `isActive`: true인 챌린지만 표시

3. **certifications**: 인증 데이터
   - `userId`: "test_user_12345"
   - `challengeId`, `xpEarned` 확인

4. **xp_logs**: XP 로그
   - `userId`: "test_user_12345"
   - `action`, `amount`, `totalXp` 확인

5. **users**: 사용자 XP
   - 문서 ID: "test_user_12345"
   - `totalXp`, `level` 확인

---

## ⚠️ 주의사항

1. **인덱스 생성**: 인덱스가 생성되지 않으면 쿼리 오류 발생
2. **보안 규칙**: 개발 중에는 모든 읽기/쓰기 허용 규칙 사용 가능
3. **사용자 ID**: 현재는 하드코딩된 `test_user_12345` 사용 (B 담당과 협업 후 교체)
4. **라우팅**: A 담당이 라우팅 연결 필요

---

## 🐛 문제 해결

### 오류: "The query requires an index"
- **원인**: Firestore 인덱스가 생성되지 않음
- **해결**: Firebase Console에서 인덱스 생성 (오류 메시지에 링크 제공)

### 오류: "Permission denied"
- **원인**: Firestore 보안 규칙 문제
- **해결**: 개발 중에는 모든 읽기/쓰기 허용 규칙 사용

### 화면이 표시되지 않음
- **원인**: 라우팅이 연결되지 않음
- **해결**: A 담당과 협업하여 라우팅 연결

### 데이터가 표시되지 않음
- **원인**: Firestore에 데이터가 없음
- **해결**: 테스트 데이터 생성 또는 실제 데이터 추가

---

## 📊 테스트 체크리스트

- [ ] Firestore 인덱스 생성 완료
- [ ] Firestore 보안 규칙 설정 완료
- [ ] 라우팅 연결 완료 (A 담당)
- [ ] 일정 추가/수정/삭제 테스트 완료
- [ ] 챌린지 목록 조회 테스트 완료
- [ ] 인증 등록 테스트 완료
- [ ] XP 획득 확인 완료
- [ ] 레벨 업 확인 완료
- [ ] XP 배지 위젯 표시 확인 완료

