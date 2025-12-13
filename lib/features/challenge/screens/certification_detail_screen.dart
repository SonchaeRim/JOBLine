import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../utils/admin_utils.dart';
import '../widgets/certification_image.dart';
import '../widgets/certification_basic_info.dart';
import '../widgets/certification_detail_info.dart';
import 'photo_proof_form_screen.dart';

/// 인증 상세 화면
class CertificationDetailScreen extends StatefulWidget {
  final String certificationId;

  const CertificationDetailScreen({
    super.key,
    required this.certificationId,
  });

  @override
  State<CertificationDetailScreen> createState() => _CertificationDetailScreenState();
}

class _CertificationDetailScreenState extends State<CertificationDetailScreen> {
  final ProofService _proofService = ProofService();
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminUtils.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
  }


  Future<void> _navigateToEdit(BuildContext context, Certification cert) async {
    // 수정 화면으로 이동
    // 이미지 파일이 필요하지만, 수정 모드에서는 기존 이미지 URL을 사용하므로 null로 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoProofFormScreen(
          userId: cert.userId,
          imageFile: null, // 수정 모드에서는 null
          certificationId: cert.id,
          existingCertification: cert,
        ),
      ),
    );
  }

  Future<void> _approveCertification(BuildContext context, Certification cert) async {
    // 자동 계산된 XP 가져오기
    int calculatedXp = cert.xpEarned;
    if (calculatedXp == 0 && cert.certificationType != null) {
      calculatedXp = _proofService.calculateCertificationXp(cert);
    }

    // XP 입력 컨트롤러
    final xpController = TextEditingController(
      text: calculatedXp > 0 ? calculatedXp.toString() : '',
    );

    // 승인 확인 다이얼로그 (XP 입력 포함)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인증 승인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 인증을 승인하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: xpController,
              decoration: const InputDecoration(
                labelText: '지급할 경험치 (XP)',
                hintText: '자동 계산된 값 또는 직접 입력',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            if (calculatedXp > 0) ...[
              const SizedBox(height: 8),
              Text(
                '자동 계산된 XP: $calculatedXp',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final xpText = xpController.text.trim();
              int? xpAmount;
              if (xpText.isNotEmpty) {
                xpAmount = int.tryParse(xpText);
                if (xpAmount == null || xpAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('올바른 숫자를 입력해주세요.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }
              Navigator.pop(context, {'approved': true, 'xpAmount': xpAmount});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (result == null || result['approved'] != true) return;

    try {
      final xpAmount = result['xpAmount'] as int?;
      await _proofService.approveCertification(cert.id, xpAmount: xpAmount);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증이 승인되었습니다.${xpAmount != null ? ' (${xpAmount} XP 지급)' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('승인 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCertification(BuildContext context, Certification cert) async {
    // 거부 사유 입력 컨트롤러
    final reasonController = TextEditingController();

    // 거부 확인 다이얼로그 (사유 입력 포함)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인증 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 인증을 거부하시겠습니까?\n거부 시 경험치가 지급되지 않습니다.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '반려 사유',
                hintText: '거부 사유를 입력해주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('반려 사유를 입력해주세요.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {'rejected': true, 'reason': reason});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('거부'),
          ),
        ],
      ),
    );

    if (result == null || result['rejected'] != true) return;

    try {
      final reason = result['reason'] as String? ?? '';
      await _proofService.rejectCertification(cert.id, rejectionReason: reason);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증이 거부되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거부 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCertification(BuildContext context, Certification cert) async {
    // 삭제 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인증 삭제'),
        content: const Text('정말로 이 인증을 삭제하시겠습니까?\n삭제된 인증은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _proofService.deleteCertification(cert.id);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인증 상세'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _proofService.getCertificationStream(widget.certificationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('인증 내역을 찾을 수 없습니다.'),
            );
          }

          final cert = Certification.fromFirestore(snapshot.data!);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isOwner = currentUserId != null && cert.userId == currentUserId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지
                CertificationImage(
                  imageUrl: cert.imageUrl,
                  reviewStatus: cert.reviewStatus,
                ),
                const SizedBox(height: 24),
                // 기본 정보
                CertificationBasicInfo(certification: cert),
                // 상세 정보
                if (cert.certificationDetails != null && cert.certificationDetails!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  CertificationDetailInfo(certification: cert),
                ],
                const SizedBox(height: 24),
                // 관리자 승인/거부 버튼 (관리자이고 검토 중일 때만)
                if (_isAdmin && cert.reviewStatus == ReviewStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveCertification(context, cert),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('승인'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectCertification(context, cert),
                          icon: const Icon(Icons.cancel),
                          label: const Text('거부'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // 수정/삭제 버튼 (본인 게시물이고 검토 중 또는 거부 상태일 때만 표시)
                if (isOwner && (cert.reviewStatus == ReviewStatus.pending || 
                               cert.reviewStatus == ReviewStatus.rejected)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToEdit(context, cert),
                          icon: const Icon(Icons.edit),
                          label: const Text('수정'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteCertification(context, cert),
                          icon: const Icon(Icons.delete),
                          label: const Text('삭제'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

