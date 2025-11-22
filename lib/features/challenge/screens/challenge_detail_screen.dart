import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../routes/route_names.dart';
import '../models/challenge.dart';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// 챌린지 상세 화면
class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  final String userId;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    required this.userId,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final ProofService _proofService = ProofService();
  int _certificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCertificationCount();
  }

  Future<void> _loadCertificationCount() async {
    final count = await _proofService.getCertificationCount(
      widget.userId,
      widget.challenge.id,
    );
    setState(() {
      _certificationCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.challenge.targetCount > 0
        ? (_certificationCount / widget.challenge.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지 상세'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 챌린지 정보
            Text(
              widget.challenge.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.challenge.description,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // 진행도
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '진행도',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_certificationCount / ${widget.challenge.targetCount}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toInt()}% 완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 챌린지 정보 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.calendar_today,
                      '기간',
                      '${DateFormat('yyyy년 M월 d일', 'ko_KR').format(widget.challenge.startDate)} ~ ${DateFormat('yyyy년 M월 d일', 'ko_KR').format(widget.challenge.endDate)}',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.flag,
                      '목표',
                      '${widget.challenge.targetCount}회 인증',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.star,
                      '보상',
                      '${widget.challenge.xpReward} XP',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 인증 목록
            const Text(
              '인증 내역',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Certification>>(
              stream: _proofService.getCertificationsByChallenge(
                widget.userId,
                widget.challenge.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final certifications = snapshot.data ?? [];

                if (certifications.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          '아직 인증이 없습니다',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: certifications.map((cert) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green),
                        title: Text(
                          DateFormat('yyyy년 M월 d일', 'ko_KR')
                              .format(cert.proofDate),
                        ),
                        subtitle: cert.description != null
                            ? Text(cert.description!)
                            : null,
                        trailing: Text(
                          '+${cert.xpEarned} XP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            RouteNames.proofCamera,
            arguments: {
              'challengeId': widget.challenge.id,
              'userId': widget.userId,
            },
          );

          if (result == true) {
            _loadCertificationCount();
            // 챌린지 완료 확인
            await _proofService.checkChallengeCompletion(
              widget.userId,
              widget.challenge.id,
              widget.challenge.targetCount,
              widget.challenge.xpReward,
            );
          }
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('인증하기'),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

