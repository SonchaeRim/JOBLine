import 'package:flutter/material.dart';

/// 등급 시스템 정의
enum Rank {
  newbie(0, 'NEWBIE', Color(0xFFFFB6C1)), // 연한 핑크
  bronze(40, 'BRONZE', Color(0xFFCD7F32)), // 구리색
  silver(100, 'SILVER', Color(0xFFC0C0C0)), // 은색
  gold(200, 'GOLD', Color(0xFFFFD700)), // 금색
  vip(400, 'VIP', Color(0xFF00CED1)); // 청록색

  final int requiredXp;
  final String name;
  final Color color;

  const Rank(this.requiredXp, this.name, this.color);
}

/// 등급 관련 유틸리티
class RankUtil {
  /// 현재 XP로 등급 계산
  static Rank getRank(int totalXp) {
    if (totalXp >= Rank.vip.requiredXp) return Rank.vip;
    if (totalXp >= Rank.gold.requiredXp) return Rank.gold;
    if (totalXp >= Rank.silver.requiredXp) return Rank.silver;
    if (totalXp >= Rank.bronze.requiredXp) return Rank.bronze;
    return Rank.newbie;
  }

  /// 다음 등급까지 필요한 XP
  static int getXpToNextRank(int totalXp) {
    final currentRank = getRank(totalXp);
    final ranks = Rank.values;
    final currentIndex = ranks.indexOf(currentRank);
    
    if (currentIndex >= ranks.length - 1) {
      return 0; // 이미 최고 등급
    }
    
    final nextRank = ranks[currentIndex + 1];
    return nextRank.requiredXp - totalXp;
  }

  /// 모든 등급 목록 가져오기
  static List<Rank> getAllRanks() {
    return Rank.values;
  }
}

