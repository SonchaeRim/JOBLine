# Firebase Functions 배포 가이드

## 빠른 배포 방법

### 1. Firebase CLI 확인
```powershell
# Firebase CLI가 설치되어 있는지 확인
firebase --version

# 없으면 설치 (이미 설치했다면 스킵)
npm install -g firebase-tools

# PATH에 추가 (필요시)
$env:Path += ";$env:APPDATA\npm"
```

### 2. Firebase 로그인
```powershell
firebase login
```

### 3. 프로젝트 설정
```powershell
# 프로젝트 루트에서 실행
firebase use jobline-d1064
```

### 4. Functions 빌드 및 배포
```powershell
# functions 폴더로 이동
cd functions

# 빌드
npm run build

# 루트로 돌아가기
cd ..

# 배포
firebase deploy --only functions
```

## 배포 후 확인

1. Firebase Console → Functions에서 함수가 배포되었는지 확인
2. Firebase Console → Firestore Database → Data에서 `notification_jobs` 컬렉션 확인
3. 앱에서 일정에 알림 설정 후 테스트

## 문제 해결

### Firebase CLI를 찾을 수 없음
- `npm install -g firebase-tools` 실행
- PATH에 `%APPDATA%\npm` 추가

### 배포 권한 오류
- `firebase login` 다시 실행
- Firebase Console에서 프로젝트 권한 확인

### 빌드 오류
- `cd functions` 후 `npm install` 다시 실행
- Node.js 버전 확인 (18 이상 권장)

