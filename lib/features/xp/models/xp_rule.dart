/// XP 규칙 정의 클래스
class XpRule {
  /// 액션별 XP 보상 규칙 (기본 액션)
  static const Map<String, int> actionXp = {
    // 일정 관련
    'schedule_create': 5, // 일정 생성
    'schedule_complete': 15, // 일정 완료 (마감일 지남)
    
    // 커뮤니티 관련
    'post_create': 5, // 게시글 작성
    'post_like': 2, // 게시글 좋아요
    'comment_create': 3, // 댓글 작성
    
    // 로그인 관련
    'daily_login': 5, // 일일 로그인
    
    // 기타 활동
    'exhibition_participation': 10, // 전시회·공연 참여
    'other_activity': 10, // 서포터즈, 교육수료 등 기타 활동
  };

  // ========== 자격증 경험치 지급 기준 ==========

  /// 국가자격증 경험치 계산
  /// [category] 'technical' (기술·기능 분야) 또는 'service' (서비스 분야)
  /// [grade] '기술사', '기능장', '기사', '산업기사', '기능사' 또는 '1급', '2급', '3급'
  static int getNationalLicenseXp(String category, String grade) {
    if (category == 'technical') {
      switch (grade) {
        case '기술사':
          return 100;
        case '기능장':
          return 80;
        case '기사':
          return 50;
        case '산업기사':
          return 40;
        case '기능사':
          return 30;
        default:
          return 0;
      }
    } else if (category == 'service') {
      switch (grade) {
        case '1급':
          return 50;
        case '2급':
          return 40;
        case '3급':
          return 30;
        default:
          return 0;
      }
    }
    return 0;
  }

  /// 국가전문자격 경험치 계산
  /// [grade] '1급' 또는 '단일등급', '2급', '3급'
  static int getNationalProfessionalLicenseXp(String grade) {
    switch (grade) {
      case '1급':
      case '단일등급':
        return 100;
      case '2급':
        return 80;
      case '3급':
        return 50;
      default:
        return 0;
    }
  }

  /// 민간자격증 경험치 계산
  /// [type] 'national_approved' (국가공인) 또는 'registered' (등록민간자격)
  /// [grade] '1급' 또는 '단일등급', '2급', '3급'
  static int getPrivateLicenseXp(String type, String grade) {
    if (type == 'national_approved') {
      switch (grade) {
        case '1급':
        case '단일등급':
          return 50;
        case '2급':
          return 30;
        case '3급':
          return 15;
        default:
          return 0;
      }
    } else if (type == 'registered') {
      switch (grade) {
        case '1급':
        case '단일등급':
          return 30;
        case '2급':
          return 20;
        case '3급':
          return 10;
        default:
          return 0;
      }
    }
    return 0;
  }

  // ========== 공무원 및 외국어 시험 경험치 지급 기준 ==========

  /// 공무원 시험 경험치 계산
  /// [examType] '7급', '9급', '소방', '경찰'
  static int getPublicServiceExamXp(String examType) {
    return 100; // 모든 공무원 시험은 100 포인트
  }

  /// 한국사능력검정시험 경험치 계산
  /// [grade] '1급', '2급', '3급'
  static int getKoreanHistoryExamXp(String grade) {
    switch (grade) {
      case '1급':
        return 50;
      case '2급':
        return 40;
      case '3급':
        return 30;
      default:
        return 0;
    }
  }

  /// 영어 시험 경험치 계산
  /// [examType] 'TOEIC', 'TOEIC_Speaking', 'TOEFL', 'OPIC', 'TEPS', 'IELTS'
  /// [score] 시험 점수 또는 등급
  static int getEnglishExamXp(String examType, dynamic score) {
    // TOEIC
    if (examType == 'TOEIC') {
      final intScore = score is int ? score : int.tryParse(score.toString()) ?? 0;
      if (intScore >= 850) return 50;
      if (intScore >= 750) return 30;
      if (intScore >= 650) return 10;
      return 0;
    }
    
    // TOEIC Speaking
    if (examType == 'TOEIC_Speaking') {
      final String grade = score.toString().toUpperCase();
      if (grade == 'AH' || grade == 'AM') return 50;
      if (grade == 'AL' || grade == 'IH') return 30;
      if (grade == 'IM1' || grade == 'IM2' || grade == 'IM3') return 10;
      return 0;
    }
    
    // TOEFL
    if (examType == 'TOEFL') {
      final intScore = score is int ? score : int.tryParse(score.toString()) ?? 0;
      if (intScore >= 98) return 50;
      if (intScore >= 85) return 30;
      if (intScore >= 74) return 10;
      return 0;
    }
    
    // OPIC
    if (examType == 'OPIC') {
      final String grade = score.toString().toUpperCase();
      if (grade == 'AL') return 50;
      if (grade == 'IH' || grade == 'IM3') return 30;
      if (grade == 'IM2' || grade == 'IM1') return 10;
      return 0;
    }
    
    // TEPS
    if (examType == 'TEPS') {
      final intScore = score is int ? score : int.tryParse(score.toString()) ?? 0;
      if (intScore >= 386) return 50;
      if (intScore >= 324) return 30;
      if (intScore >= 281) return 10;
      return 0;
    }
    
    // IELTS
    if (examType == 'IELTS') {
      final doubleScore = score is double ? score : double.tryParse(score.toString()) ?? 0.0;
      if (doubleScore >= 6.0) return 50;
      if (doubleScore >= 5.0) return 30;
      if (doubleScore >= 4.0) return 10;
      return 0;
    }
    
    return 0;
  }

  /// 기타 외국어 시험 경험치 계산
  /// [examType] 'G-TELP', 'HSK', 'JPT', 'JPTT', 'DALF/DELF', 'DELE', 'ZD'
  /// [grade] 등급 또는 점수
  static int getOtherLanguageExamXp(String examType, String grade) {
    // 등급별로 50/30/10 포인트 지급
    final upperGrade = grade.toUpperCase();
    if (upperGrade.contains('1') || upperGrade.contains('A') || upperGrade.contains('HIGH')) {
      return 50;
    } else if (upperGrade.contains('2') || upperGrade.contains('B') || upperGrade.contains('MID')) {
      return 30;
    } else if (upperGrade.contains('3') || upperGrade.contains('C') || upperGrade.contains('LOW')) {
      return 10;
    }
    return 0;
  }

  // ========== 전시회·공연·공모전·기타활동 경험치 지급 기준 ==========

  /// 공모전·대회 경험치 계산
  /// [scale] 'international' (국제), 'national' (전국), 'local' (시·도)
  /// [result] '대상', '입상', '입선', '참가'
  static int getContestXp(String scale, String result) {
    if (scale == 'international' || scale == 'national') {
      switch (result) {
        case '대상':
          return 100;
        case '입상':
          return 50;
        case '입선':
          return 30;
        case '참가':
          return 10;
        default:
          return 0;
      }
    } else if (scale == 'local') {
      switch (result) {
        case '대상':
          return 50;
        case '입상':
          return 30;
        case '입선':
          return 20;
        case '참가':
          return 10;
        default:
          return 0;
      }
    }
    return 0;
  }

  /// 레벨별 필요 XP 계산
  /// 레벨 N에 도달하려면: level * 100 XP 필요
  /// 예: 레벨 1 = 100 XP, 레벨 2 = 200 XP, 레벨 3 = 300 XP
  static int getRequiredXpForLevel(int level) {
    if (level <= 0) return 0;
    return level * 100;
  }

  /// 현재 XP로 레벨 계산
  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 0;
    
    int level = 1;
    while (totalXp >= getRequiredXpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// 현재 레벨에서 다음 레벨까지 필요한 XP
  static int getXpToNextLevel(int totalXp) {
    final currentLevel = calculateLevel(totalXp);
    final nextLevelXp = getRequiredXpForLevel(currentLevel + 1);
    return nextLevelXp - totalXp;
  }

  /// 현재 레벨에서의 진행률 (0.0 ~ 1.0)
  static double getLevelProgress(int totalXp) {
    final currentLevel = calculateLevel(totalXp);
    final currentLevelXp = getRequiredXpForLevel(currentLevel);
    final nextLevelXp = getRequiredXpForLevel(currentLevel + 1);
    final xpInCurrentLevel = totalXp - currentLevelXp;
    final xpNeededForNext = nextLevelXp - currentLevelXp;
    
    if (xpNeededForNext == 0) return 1.0;
    return (xpInCurrentLevel / xpNeededForNext).clamp(0.0, 1.0);
  }

  /// 액션 이름으로 XP 가져오기
  static int getXpForAction(String action) {
    return actionXp[action] ?? 0;
  }
}