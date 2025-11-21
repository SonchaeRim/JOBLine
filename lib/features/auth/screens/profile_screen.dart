//닉네임, 이메일, 프로필 이미지, 한 줄 소개 등 표시용 위젯

import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 1. 자격증 보유 여부를 확인하는 리스트 (초기에는 비어있음)
  List<String> _certifications = [];
  // List<String> _certifications = ['XX 국가 기술 자격증 보유', 'OO 국가 기술 자격증 보유']; // 보유 시 테스트용

  // 2. 임시 사용자 데이터 (나중에 서버에서 받아올 값)
  final String _currentUserId = 'UserID';
  final String _currentNickname = '취뽀';
  final String _currentJob = 'IT개발';
  final String _currentCommunity = 'IT개발 • 데이터';
  final String _currentRank = 'SILVER';

  // 일반 메뉴 항목 위젯 (ListTile 스타일)
  Widget _buildMenuItem({
    required String title,
    String? trailingText, // 오른쪽에 표시될 텍스트 (아이디 등)
    VoidCallback? onTap,
    bool isAction = true, // 오른쪽에 화살표 표시 여부
  }) {
    return InkWell( // 탭 가능하도록 설정
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Row(
              children: [
                if (trailingText != null) // 오른쪽에 텍스트 표시 (아이디 등)
                  Text(
                    trailingText,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                if (isAction) // 변경 가능한 항목에만 화살표 아이콘 표시
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 프로필 카드 위젯
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 (임시)
          Stack(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black12,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '이미지 변경',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          // 닉네임, 직무, 배지
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닉네임과 임시 ID
              Text(
                '$_currentNickname # 0000',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // 직무/커뮤니티
              Text(
                _currentCommunity,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              // 등급 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade300],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _currentRank,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 자격증/수상 정보 섹션
  Widget _buildCertificatesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // 배경색을 밝은 회색으로 설정
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _certifications.isEmpty
            ? [
          // 1. 자격증이 없을 때: 회색 글씨로 안내 문구 표시 (요청 사항)
          Text(
            '보유한 자격증이 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ]
            : [
          // 2. 자격증이 있을 때: 리스트를 표시
          ..._certifications.map((cert) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)), // 아이콘
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    cert,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )),
          // 수상 경력 추가 (이미지 참고)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'SW 융합 해커톤 대회 [우수상] 수상',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 제목과 구분선
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Divider(color: Colors.black, thickness: 1.0), // 검은색 구분선
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('내 프로필', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // 프로필 카드
              _buildProfileCard(),

              // 자격증/수상 섹션
              _buildCertificatesSection(),

              // === 계정 섹션 ===
              _buildSectionHeader('계정'),
              // 아이디 (읽기 전용 값 표시)
              _buildMenuItem(
                title: '아이디',
                trailingText: _currentUserId, // 나중에 사용자 ID가 로드될 영역
                isAction: false, // 아이디는 변경 항목이 아니므로 화살표 제거
                onTap: () {
                  // 아이디는 보통 변경 불가
                },
              ),
              const Divider(color: Colors.black12, height: 1),

              // 비밀번호 변경
              _buildMenuItem(
                title: '비밀번호 변경',
                onTap: () {
                  // 비밀번호 변경 화면 이동
                },
              ),
              const Divider(color: Colors.black12, height: 1),

              // 닉네임 변경
              _buildMenuItem(
                title: '닉네임 변경',
                onTap: () {
                  // 닉네임 변경 화면 이동
                },
              ),
              const Divider(color: Colors.black12, height: 1),

