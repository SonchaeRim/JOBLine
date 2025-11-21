import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../../xp/models/xp_rule.dart';
import '../../../core/theme/app_colors.dart';

/// 인증 업로드 화면 (텍스트 위주)
class ProofCameraScreen extends StatefulWidget {
  final String challengeId;
  final String userId;

  const ProofCameraScreen({
    super.key,
    required this.challengeId,
    required this.userId,
  });

  @override
  State<ProofCameraScreen> createState() => _ProofCameraScreenState();
}

class _ProofCameraScreenState extends State<ProofCameraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ProofService _proofService = ProofService();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitProof() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final certification = Certification(
        id: '',
        challengeId: widget.challengeId,
        userId: widget.userId,
        description: _descriptionController.text.trim(),
        proofDate: now,
        createdAt: now,
        isApproved: true,
        xpEarned: XpRule.getXpForAction('challenge_proof'),
      );

      await _proofService.createCertification(certification);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증이 완료되었습니다! +${certification.xpEarned} XP'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인증하기'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 메시지
              Card(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '챌린지 인증을 완료해주세요.\n인증 시 ${XpRule.getXpForAction('challenge_proof')} XP를 획득합니다.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 날짜 표시
              Text(
                '인증 날짜: ${DateFormat('yyyy년 M월 d일', 'ko_KR').format(DateTime.now())}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // 설명 입력
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '인증 설명 *',
                  hintText: '오늘의 활동을 설명해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '인증 설명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // 제출 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '인증 제출',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

