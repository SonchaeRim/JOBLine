# Firestore 컬렉션 구조 문서

## 개요
이 문서는 Job Line 앱에서 사용하는 Firestore 컬렉션 구조를 설명합니다.
**D 담당 (일정·알림·채팅 담당)**에서 관리하는 컬렉션입니다.

---

## 컬렉션 목록

### 1. `schedules` - 일정 컬렉션

**경로**: `schedules/{scheduleId}`

**필드**:
- `title` (string, required): 일정 제목
- `description` (string, optional): 일정 설명
- `startDate` (timestamp, required): 시작 날짜/시간
- `endDate` (timestamp, optional): 종료 날짜/시간
- `ownerId` (string, required): 일정 소유자 사용자 ID
- `createdAt` (timestamp, required): 생성 시간
- `updatedAt` (timestamp, required): 수정 시간
- `isDeadline` (boolean, default: false): 마감일 여부
- `category` (string, optional): 일정 카테고리 (예: "면접", "서류제출", "시험")

**인덱스 필요**:
- `ownerId` + `startDate` (오름차순)
- `ownerId` + `isDeadline` + `startDate` (오름차순)

**사용 예시**:
```dart
// 사용자의 모든 일정 가져오기
calendarService.getSchedulesByUser(userId);

// 특정 날짜 범위의 일정 가져오기
calendarService.getSchedulesByDateRange(userId, startDate, endDate);

// 마감일이 D-1인 일정 가져오기
calendarService.getDeadlineSchedules(userId);
```

---

### 2. `challenges` - 챌린지 컬렉션

**경로**: `challenges/{challengeId}`

**필드**:
- `title` (string, required): 챌린지 제목
- `description` (string, required): 챌린지 설명
- `imageUrl` (string, optional): 챌린지 대표 이미지 URL
- `durationDays` (number, required): 챌린지 기간 (일)
- `targetCount` (number, required): 목표 인증 횟수
- `xpReward` (number, required): 완료 시 보상 XP
- `startDate` (timestamp, required): 시작 날짜
- `endDate` (timestamp, required): 종료 날짜
- `createdAt` (timestamp, required): 생성 시간
- `isActive` (boolean, default: true): 활성화 여부
- `category` (string, optional): 챌린지 카테고리

**인덱스 필요**:
- `isActive` + `startDate` (오름차순)

**사용 예시**:
```dart
// 활성화된 챌린지 목록 가져오기
challengeService.getActiveChallenges();

// 특정 챌린지 가져오기
challengeService.getChallengeById(challengeId);
```

---

### 3. `certifications` - 인증 결과 컬렉션

**경로**: `certifications/{certificationId}`

**필드**:
- `challengeId` (string, required): 참여한 챌린지 ID
- `userId` (string, required): 인증한 사용자 ID
- `imageUrl` (string, optional): 인증 이미지 URL
- `description` (string, optional): 인증 설명/텍스트
- `proofDate` (timestamp, required): 인증 날짜
- `createdAt` (timestamp, required): 생성 시간
- `isApproved` (boolean, default: true): 승인 여부
- `xpEarned` (number, default: 0): 이 인증으로 획득한 XP

**인덱스 필요**:
- `userId` + `challengeId` + `proofDate` (내림차순)
- `userId` + `proofDate` (내림차순)
- `userId` + `challengeId` + `isApproved`

**사용 예시**:
```dart
// 사용자의 특정 챌린지 인증 목록
proofService.getCertificationsByChallenge(userId, challengeId);

// 사용자의 모든 인증 목록
proofService.getUserCertifications(userId);

// 특정 챌린지의 인증 횟수
proofService.getCertificationCount(userId, challengeId);
```

---

### 4. `xp_logs` - XP 로그 컬렉션

**경로**: `xp_logs/{logId}`

**필드**:
- `userId` (string, required): 사용자 ID
- `action` (string, required): 액션 이름 (예: "challenge_proof", "schedule_create")
- `amount` (number, required): 획득한 XP 양
- `totalXp` (number, required): 획득 후 총 XP
- `level` (number, required): 획득 후 레벨
- `referenceId` (string, optional): 관련 ID (예: 챌린지 ID, 일정 ID)
- `createdAt` (timestamp, required): 생성 시간

**인덱스 필요**:
- `userId` + `createdAt` (내림차순)
- `userId` + `action` + `referenceId`

**사용 예시**:
```dart
// 사용자의 XP 로그 가져오기
xpService.getXpLogs(userId, limit: 50);
```

---

### 5. `users` - 사용자 컬렉션

**경로**: `users/{userId}`

**주의**: 이 컬렉션은 **B 담당 (계정·프로필/미디어 담당)**에서 주로 관리하지만, D 담당에서 XP 관련 필드를 업데이트합니다.

**D 담당이 업데이트하는 필드**:
- `totalXp` (number, default: 0): 누적 총 XP
- `level` (number, default: 0): 현재 레벨
- `updatedAt` (timestamp, required): 마지막 업데이트 시간

**인덱스 필요**: 없음 (단일 문서 조회)

**사용 예시**:
```dart
// 사용자의 현재 XP와 레벨 가져오기
xpService.getUserXp(userId);

// 사용자의 XP 스트림
xpService.getUserXpStream(userId);
```

---

## XP 규칙

### 액션별 XP 보상

| 액션 | XP |
|------|-----|
| `challenge_proof` | 10 |
| `challenge_complete` | 50 |
| `schedule_create` | 5 |
| `schedule_complete` | 15 |
| `post_create` | 5 |
| `post_like` | 2 |
| `comment_create` | 3 |
| `daily_login` | 5 |

### 레벨 계산

- 레벨 N에 도달하려면: `N * 100` XP 필요
- 예: 레벨 1 = 100 XP, 레벨 2 = 200 XP, 레벨 3 = 300 XP

---

## Firestore 보안 규칙 예시

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
        // XP 관련 필드만 업데이트 가능
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['totalXp', 'level', 'updatedAt']);
    }
  }
}
```

---

## 인덱스 생성 가이드

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

---

## 참고사항

- 모든 타임스탬프는 Firestore의 `Timestamp` 타입을 사용합니다.
- 사용자 ID는 Firebase Auth의 `uid`를 사용합니다.
- XP는 실시간으로 계산되며, `users` 컬렉션에 저장됩니다.
- 인증 결과가 등록되면 자동으로 XP가 부여됩니다.
- `users` 컬렉션의 XP 필드는 **B 담당과 협업**하여 업데이트합니다.

