import 'rank.dart';

/// XP 규칙 정의 클래스
class XpRule {
  // 전시회·공연 및 기타 활동 기본 XP
  static const int exhibitionParticipationXp = 10;
  static const int otherActivityXp = 10;

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

  /// 한국어 시험(TOPIK) 경험치 계산
  /// [grade] '6급', '5급', '4급'
  static int getTopikXp(String grade) {
    switch (grade) {
      case '6급':
        return 20;
      case '5급':
        return 10;
      case '4급':
        return 5;
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

  /// 현재 등급에서의 진행률 (0.0 ~ 1.0)
  /// 현재 등급에서 다음 등급까지의 XP 진행률을 계산합니다.
  static double getRankProgress(int totalXp) {
    final currentRank = RankUtil.getRank(totalXp);
    final ranks = Rank.values;
    final currentIndex = ranks.indexOf(currentRank);

    // 이미 최고 등급인 경우
    if (currentIndex >= ranks.length - 1) {
      return 1.0;
    }

    final currentRankXp = currentRank.requiredXp;
    final nextRank = ranks[currentIndex + 1];
    final nextRankXp = nextRank.requiredXp;

    final xpInCurrentRank = totalXp - currentRankXp;
    final xpNeededForNextRank = nextRankXp - currentRankXp;

    if (xpNeededForNextRank == 0) return 1.0;
    return (xpInCurrentRank / xpNeededForNextRank).clamp(0.0, 1.0);
  }

  // ========== 표 데이터 생성 ==========

  /// 자격증 경험치 지급 기준 표 데이터
  /// 반환값: [유형, 분류, 등급, 포인트] 형태의 행 리스트
  static List<List<String>> getLicenseTableRows() {
    final rows = <List<String>>[];

    // 국가자격증 - 기술·기능 분야
    rows.add(['국가자격증', '기술·기능 분야', '기술사', '${getNationalLicenseXp('technical', '기술사')}']);
    rows.add(['', '', '기능장', '${getNationalLicenseXp('technical', '기능장')}']);
    rows.add(['', '', '기사', '${getNationalLicenseXp('technical', '기사')}']);
    rows.add(['', '', '산업기사', '${getNationalLicenseXp('technical', '산업기사')}']);
    rows.add(['', '', '기능사', '${getNationalLicenseXp('technical', '기능사')}']);

    // 국가자격증 - 서비스 분야
    rows.add(['', '서비스 분야', '1급', '${getNationalLicenseXp('service', '1급')}']);
    rows.add(['', '', '2급', '${getNationalLicenseXp('service', '2급')}']);
    rows.add(['', '', '3급', '${getNationalLicenseXp('service', '3급')}']);

    // 국가전문자격
    rows.add(['국가전문자격', '-', '1급/단일등급', '${getNationalProfessionalLicenseXp('1급')}']);
    rows.add(['', '', '2급', '${getNationalProfessionalLicenseXp('2급')}']);
    rows.add(['', '', '3급', '${getNationalProfessionalLicenseXp('3급')}']);

    // 민간자격증 - 국가공인
    rows.add(['민간자격증', '국가공인', '1급/단일등급', '${getPrivateLicenseXp('national_approved', '1급')}']);
    rows.add(['', '', '2급', '${getPrivateLicenseXp('national_approved', '2급')}']);
    rows.add(['', '', '3급', '${getPrivateLicenseXp('national_approved', '3급')}']);

    // 민간자격증 - 등록민간자격
    rows.add(['', '등록민간자격', '1급/단일등급', '${getPrivateLicenseXp('registered', '1급')}']);
    rows.add(['', '', '2급', '${getPrivateLicenseXp('registered', '2급')}']);
    rows.add(['', '', '3급', '${getPrivateLicenseXp('registered', '3급')}']);

    return rows;
  }

  /// 공무원 및 외국어 시험 경험치 지급 기준 표 데이터
  /// 반환값: [유형, 시험, 등급/점수, 포인트] 형태의 행 리스트
  static List<List<String>> getExamTableRows() {
    final rows = <List<String>>[];

    // 공무원
    rows.add(['공무원', '7급, 9급, 소방, 경찰', '-', '${getPublicServiceExamXp('7급')}']);

    // 한국사
    rows.add([
      '한국사',
      '한국사능력검정시험',
      '1 / 2 / 3급',
      '${getKoreanHistoryExamXp('1급')} / ${getKoreanHistoryExamXp('2급')} / ${getKoreanHistoryExamXp('3급')}',
    ]);

    // 한국어 (TOPIK)
    rows.add([
      '한국어',
      'TOPIK',
      '6 / 5 / 4급',
      '${getTopikXp('6급')} / ${getTopikXp('5급')} / ${getTopikXp('4급')}',
    ]);

    // 영어 시험들
    rows.add([
      '영어',
      'TOEIC',
      '850 / 750 / 650',
      '${getEnglishExamXp('TOEIC', 850)} / ${getEnglishExamXp('TOEIC', 750)} / ${getEnglishExamXp('TOEIC', 650)}',
    ]);
    rows.add([
      '',
      'TOEIC Speaking',
      'AH, AM / AL, IH / IM1, IM2, IM3',
      '${getEnglishExamXp('TOEIC_Speaking', 'AH')} / ${getEnglishExamXp('TOEIC_Speaking', 'AL')} / ${getEnglishExamXp('TOEIC_Speaking', 'IM1')}',
    ]);
    rows.add([
      '',
      'TOEFL',
      '98 / 85 / 74',
      '${getEnglishExamXp('TOEFL', 98)} / ${getEnglishExamXp('TOEFL', 85)} / ${getEnglishExamXp('TOEFL', 74)}',
    ]);
    rows.add([
      '',
      'OPIC',
      'AL / IH, IM3 / IM2, IM1',
      '${getEnglishExamXp('OPIC', 'AL')} / ${getEnglishExamXp('OPIC', 'IH')} / ${getEnglishExamXp('OPIC', 'IM2')}',
    ]);
    rows.add([
      '',
      'TEPS',
      '386 / 324 / 281',
      '${getEnglishExamXp('TEPS', 386)} / ${getEnglishExamXp('TEPS', 324)} / ${getEnglishExamXp('TEPS', 281)}',
    ]);
    rows.add([
      '',
      'IELTS',
      '6 / 5 / 4',
      '${getEnglishExamXp('IELTS', 6.0)} / ${getEnglishExamXp('IELTS', 5.0)} / ${getEnglishExamXp('IELTS', 4.0)}',
    ]);

    // 기타 외국어
    rows.add([
      '기타',
      'G-TELP, HSK, JPT, JPTT, DALF/DELF, DELE, ZD',
      '각 등급',
      '${getOtherLanguageExamXp('G-TELP', '1')} / ${getOtherLanguageExamXp('G-TELP', '2')} / ${getOtherLanguageExamXp('G-TELP', '3')}',
    ]);

    return rows;
  }

  /// 전시회·공연·공모전·기타활동 경험치 지급 기준 표 데이터
  /// 반환값: [유형, 단위, 등급/결과, 포인트] 형태의 행 리스트
  static List<List<String>> getActivityTableRows() {
    final rows = <List<String>>[];

    // 전시회·공연
    rows.add(['전시회·공연', '참여', '-', '$exhibitionParticipationXp']);

    // 공모전·대회 - 국제 단위
    rows.add(['공모전·대회', '국제 단위', '대상', '${getContestXp('international', '대상')}']);
    rows.add(['', '', '입상', '${getContestXp('international', '입상')}']);
    rows.add(['', '', '입선', '${getContestXp('international', '입선')}']);
    rows.add(['', '', '참가', '${getContestXp('international', '참가')}']);

    // 공모전·대회 - 전국 단위
    rows.add(['', '전국 단위', '대상', '${getContestXp('national', '대상')}']);
    rows.add(['', '', '입상', '${getContestXp('national', '입상')}']);
    rows.add(['', '', '입선', '${getContestXp('national', '입선')}']);
    rows.add(['', '', '참가', '${getContestXp('national', '참가')}']);

    // 공모전·대회 - 시·도 단위
    rows.add(['', '시·도 단위', '대상', '${getContestXp('local', '대상')}']);
    rows.add(['', '', '입상', '${getContestXp('local', '입상')}']);
    rows.add(['', '', '입선', '${getContestXp('local', '입선')}']);
    rows.add(['', '', '참가', '${getContestXp('local', '참가')}']);

    // 기타 활동
    rows.add(['기타 활동', '서포터즈, 홍보단, 기자단, 해외탐방단, 교육수료 등', '수료증/이수증 기준', '$otherActivityXp']);

    return rows;
  }
}
