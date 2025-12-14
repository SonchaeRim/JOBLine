import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/xp/models/xp_rule.dart';

/// 셀 데이터 모델
class CellData {
  final String text;
  final int? rowSpan;
  final int? columnSpan;
  final bool isHeader;

  CellData({
    required this.text,
    this.rowSpan,
    this.columnSpan,
    this.isHeader = false,
  });
}

/// 심사 기준 확인 화면
class ReviewCriteriaScreen extends StatelessWidget {
  const ReviewCriteriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('심사 기준'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('자격증 경험치 지급 기준'),
            const SizedBox(height: 12),
            _buildTable(
              columnSizes: [3.fr, 3.fr, 2.fr, 2.fr],
              headers: ['유형', '분류', '등급', '포인트'],
              rawData: XpRule.getLicenseTableRows(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('공무원 및 외국어 시험 경험치 지급 기준'),
            const SizedBox(height: 12),
            _buildTable(
              columnSizes: [1.2.fr, 1.5.fr, 2.fr, 1.fr],
              headers: ['유형', '시험', '등급/점수', '포인트'],
              rawData: XpRule.getExamTableRows(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('전시회·공연·공모전·기타활동 경험치 지급 기준'),
            const SizedBox(height: 12),
            _buildTable(
              columnSizes: [1.2.fr, 1.2.fr, 1.5.fr, 1.fr],
              headers: ['유형', '단위', '등급/결과', '포인트'],
              rawData: XpRule.getActivityTableRows(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTable({
    required List<TrackSize> columnSizes,
    required List<String> headers,
    required List<List<String>> rawData,
  }) {
    // 마크다운 테이블 파싱 및 병합 정보 계산
    final parsedData = _parseTableData(rawData);
    
    // 행 개수 계산 (헤더 + 데이터)
    final rowCount = 1 + parsedData.length;
    
    return Card(
      child: LayoutGrid(
        columnSizes: columnSizes,
        rowSizes: List.generate(rowCount, (_) => auto),
        children: [
          // 헤더
          for (int col = 0; col < headers.length; col++)
            _buildCell(headers[col], isHeader: true)
                .withGridPlacement(columnStart: col, rowStart: 0),
          
          // 데이터 행들
          for (int row = 0; row < parsedData.length; row++)
            for (int col = 0; col < parsedData[row].length; col++)
              if (parsedData[row][col].text.isNotEmpty)
                () {
                  final cell = parsedData[row][col];
                  final widget = _buildCell(
                    cell.text,
                    isHeader: cell.isHeader,
                  );
                  
                  // rowSpan과 columnSpan이 null이 아닐 때만 전달
                  if (cell.rowSpan != null && cell.columnSpan != null) {
                    return widget.withGridPlacement(
                      rowStart: row + 1,
                      rowSpan: cell.rowSpan!,
                      columnStart: col,
                      columnSpan: cell.columnSpan!,
                    );
                  } else if (cell.rowSpan != null) {
                    return widget.withGridPlacement(
                      rowStart: row + 1,
                      rowSpan: cell.rowSpan!,
                      columnStart: col,
                    );
                  } else if (cell.columnSpan != null) {
                    return widget.withGridPlacement(
                      rowStart: row + 1,
                      columnStart: col,
                      columnSpan: cell.columnSpan!,
                    );
                  } else {
                    return widget.withGridPlacement(
                      rowStart: row + 1,
                      columnStart: col,
                    );
                  }
                }(),
        ],
      ),
    );
  }

  /// 마크다운 테이블 데이터를 파싱하여 병합 정보 자동 계산
  List<List<CellData>> _parseTableData(List<List<String>> rawData) {
    if (rawData.isEmpty) return [];
    
    final columnCount = rawData[0].length;
    final parsedData = <List<CellData>>[];
    
    // 각 컬럼별로 마지막으로 채워진 값과 행 인덱스 추적
    final lastValue = List<String?>.filled(columnCount, null);
    final lastRowIndex = List<int?>.filled(columnCount, null);
    
    // 먼저 모든 데이터를 CellData로 변환
    for (int row = 0; row < rawData.length; row++) {
      final rowData = <CellData>[];
      
      for (int col = 0; col < columnCount; col++) {
        final cellValue = rawData[row][col].trim();
        
        if (cellValue.isEmpty) {
          // 빈 셀: 위쪽 셀과 병합될 예정
          rowData.add(CellData(text: ''));
        } else {
          // 값이 있는 셀
          rowData.add(CellData(text: cellValue));
          lastValue[col] = cellValue;
          lastRowIndex[col] = row;
        }
      }
      
      parsedData.add(rowData);
    }
    
    // rowSpan 계산: 각 컬럼별로 빈 셀들을 위쪽 셀과 병합
    for (int col = 0; col < columnCount; col++) {
      int? startRow;
      String? startValue;
      
      for (int row = 0; row < parsedData.length; row++) {
        final cell = parsedData[row][col];
        
        if (cell.text.isEmpty) {
          // 빈 셀: 병합 시작점이 있으면 계속 병합
          if (startRow != null && startValue != null) {
            // 계속 병합 중
          } else {
            // 병합 시작점 없음 (이론적으로 발생하지 않아야 함)
          }
        } else {
          // 값이 있는 셀
          if (startRow != null && startValue != null) {
            // 이전 병합 종료: rowSpan 계산
            final span = row - startRow;
            if (span > 1) {
              parsedData[startRow][col] = CellData(
                text: startValue,
                rowSpan: span,
              );
            }
          }
          // 새로운 병합 시작점
          startRow = row;
          startValue = cell.text;
        }
      }
      
      // 마지막 병합 처리
      if (startRow != null && startValue != null) {
        final span = parsedData.length - startRow;
        if (span > 1) {
          parsedData[startRow][col] = CellData(
            text: startValue,
            rowSpan: span,
          );
        }
      }
    }
    
    return parsedData;
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.primary.withOpacity(0.1) : null,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHeader ? 13 : 12,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? AppColors.primary : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

}
