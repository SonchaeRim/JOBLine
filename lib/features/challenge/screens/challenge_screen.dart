import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import '../../../routes/route_names.dart';
import '../services/proof_service.dart';
import '../models/certification.dart';
import '../screens/photo_proof_form_screen.dart';
import '../utils/admin_utils.dart';
import '../../xp/services/xp_service.dart';
import '../widgets/challenge_card.dart';
import '../widgets/review_status_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/rank_system.dart';
import '../widgets/description_text.dart';

/// 챌린지 화면
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final XpService _xpService = XpService();
  String? _currentUserId;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    // Firebase Auth에서 현재 사용자 ID 가져오기
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      _checkAdminStatus();
    } else {
      _isCheckingAdmin = false;
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminUtils.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('챌린지'),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 챌린지 카드
            const ChallengeCard(),
            const SizedBox(height: 16),
            // 검토 상태
            FutureBuilder<int>(
              future: _getPendingReviewCount(),
              builder: (context, snapshot) {
                return ReviewStatusCard(
                  pendingCount: snapshot.data ?? 0,
                );
              },
            ),
            const SizedBox(height: 16),
            // 액션 버튼들
            ActionButtons(
              onPhotoCertificationTap: _navigateToPhotoCertification,
              onProofListTap: _navigateToProofList,
            ),
            const SizedBox(height: 24),
            // 등급 시스템
            StreamBuilder<Map<String, dynamic>>(
              stream: _xpService.getUserXpStream(_currentUserId!),
              builder: (context, snapshot) {
                // 데이터가 로드되기 전까지는 아무 등급도 하이라이트하지 않음
                if (!snapshot.hasData) {
                  return RankSystem(
                    totalXp: 0,
                    rankString: null,
                    isLoading: true,
                  );
                }
                final xpData = snapshot.data!;
                final totalXp = (xpData['totalXp'] as int?) ?? 0;
                final rankString = xpData['rank'] as String?;
                return RankSystem(
                  totalXp: totalXp,
                  rankString: rankString,
                  isLoading: false,
                );
              },
            ),
            const SizedBox(height: 24),
            // 설명 텍스트
            const DescriptionText(),
          ],
        ),
      ),
    );
  }


  Future<int> _getPendingReviewCount() async {
    if (_currentUserId == null) return 0;
    try {
      final ProofService proofService = ProofService();
      final certifications = await proofService.getUserCertifications(_currentUserId!).first;
      return certifications.where((cert) => cert.reviewStatus == ReviewStatus.pending).length;
    } catch (e) {
      return 0;
    }
  }


  /// 문서 스캔을 시작하고 결과를 폼 화면으로 전달
  Future<void> _navigateToPhotoCertification() async {
    if (_currentUserId == null) return;

    try {
      final scanner = FlutterDocScanner();
      final dynamic scanResult = await scanner.getScannedDocumentAsImages();

      // 사용자가 취소한 경우
      if (scanResult == null) {
        return;
      }

      // 스캔 결과에서 이미지 경로 추출
      String? firstImagePath;
      int pageCount = 0; // 스캔된 페이지 수 추적
      if (scanResult is Map && scanResult.containsKey('Uri')) {
        final uriValue = scanResult['Uri'];
        
        if (uriValue is List && uriValue.isNotEmpty) {
          pageCount = uriValue.length;
          
          // 여러 페이지가 스캔된 경우 사용자에게 알림
          if (pageCount > 1 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
          
          final firstPage = uriValue.first;
          if (firstPage is Map && firstPage.containsKey('imageUri')) {
            final imageUri = firstPage['imageUri'];
            if (imageUri is String) {
              firstImagePath = imageUri;
            }
          } else if (firstPage is String) {
            final uriMatch = RegExp(r'file://(/[^\s}]+)').firstMatch(firstPage);
            if (uriMatch != null) {
              firstImagePath = uriMatch.group(1);
            }
          }
        } else if (uriValue is String) {
          final uriMatch = RegExp(r'file://(/[^\s}]+)').firstMatch(uriValue);
          if (uriMatch != null) {
            firstImagePath = uriMatch.group(1);
          }
        }
      } else if (scanResult is List && scanResult.isNotEmpty && scanResult.first is String) {
        pageCount = scanResult.length;
        
        // 여러 페이지가 스캔된 경우 사용자에게 알림
        if (pageCount > 1 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        firstImagePath = scanResult.first as String;
      }

      // file:// URI를 일반 파일 경로로 변환
      if (firstImagePath != null && firstImagePath.startsWith('file://')) {
        firstImagePath = firstImagePath.replaceFirst('file://', '');
      }

      // 파일 경로 정규화
      if (firstImagePath != null) {
        final normalizedPath = firstImagePath.replaceAll(RegExp(r'[/]+'), '/');
        final imageFile = File(normalizedPath);

        // 파일 존재 여부 확인
        if (await imageFile.exists() && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoProofFormScreen(
                userId: _currentUserId!,
                imageFile: imageFile,
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('스캔된 이미지 파일을 찾을 수 없습니다.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('스캔 결과를 처리할 수 없습니다.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('문서 스캔 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToProofList() {
    Navigator.pushNamed(
      context,
      RouteNames.proofList,
      arguments: {
        'userId': _currentUserId!,
      },
    );
  }
}

