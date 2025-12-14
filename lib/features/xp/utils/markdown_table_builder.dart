import '../models/xp_rule.dart';

/// Markdown 테이블 생성 유틸리티
class MarkdownTableBuilder {
  /// 자격증 경험치 지급 기준 Markdown 테이블 생성
  static String buildLicenseTable() {
    final rows = XpRule.getLicenseTableRows();
    return _buildMarkdownTable(
      title: '### 자격증 경험치 지급 기준',
      headers: ['유형', '분류', '등급', '포인트'],
      rows: rows,
    );
  }

  /// 공무원 및 외국어 시험 경험치 지급 기준 Markdown 테이블 생성
  static String buildExamTable() {
    final rows = XpRule.getExamTableRows();
    return _buildMarkdownTable(
      title: '### 공무원 및 외국어 시험 경험치 지급 기준',
      headers: ['유형', '시험', '등급/점수', '포인트'],
      rows: rows,
    );
  }

  /// 전시회·공연·공모전·기타활동 경험치 지급 기준 Markdown 테이블 생성
  static String buildActivityTable() {
    final rows = XpRule.getActivityTableRows();
    return _buildMarkdownTable(
      title: '### 전시회·공연·공모전·기타활동 경험치 지급 기준',
      headers: ['유형', '단위', '등급/결과', '포인트'],
      rows: rows,
    );
  }

  /// 모든 표를 포함한 전체 Markdown 문서 생성
  static String buildAllTables() {
    final buffer = StringBuffer();
    buffer.writeln(buildLicenseTable());
    buffer.writeln();
    buffer.writeln(buildExamTable());
    buffer.writeln();
    buffer.writeln(buildActivityTable());
    return buffer.toString();
  }

  /// Markdown 테이블 문자열 생성
  static String _buildMarkdownTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    
    // 제목
    buffer.writeln(title);
    buffer.writeln();
    
    // 헤더
    buffer.writeln('| ${headers.join(' | ')} |');
    
    // 구분선
    buffer.writeln('| ${headers.map((_) => '---').join(' | ')} |');
    
    // 데이터 행
    for (final row in rows) {
      // 빈 셀은 공백으로 표시
      final cells = row.map((cell) => cell.isEmpty ? ' ' : cell).toList();
      buffer.writeln('| ${cells.join(' | ')} |');
    }
    
    return buffer.toString();
  }
}

