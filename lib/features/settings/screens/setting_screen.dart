import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobline/features/auth/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; // File 사용을 위해 추가

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _displayName = '사용자 이름';
  String _displayId = 'user_id';
  String? _profileImageUrl;   // 프로필 이미지 URL 저장

  List<String> _certifications = []; // DB에서 로드될 예정
  final String _currentCommunity = 'IT개발 • 데이터';
  final String _currentRank = 'SILVER';
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Firestore에서 사용자 프로필 정보 로드
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // 닉네임 및 ID 처리
        final nickname = data['nickname'] ?? '닉네임 없음';
        final userId = data['name'] ?? 'ID 없음';
        final imageUrl = data['profileImageUrl'] as String?;

        // 자격증/수상 데이터 처리 (DB에 필드가 없으면 빈 리스트)
        final List<String> loadedCertifications =
            (data['certifications'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];

        if (mounted) {
          setState(() {
            _displayName = nickname;
            _displayId = userId;
            _certifications = loadedCertifications;
            _profileImageUrl = imageUrl;
            _isLoading = false;
          });
        }
      } else {
        // 문서 없는 경우 처리
        if (mounted) {
          setState(() {
            _displayName = user.email?.split('@').first ?? '사용자';
            _displayId = user.email?.split('@').first ?? 'ID 없음';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("설정 화면 프로필 로드 오류: $e");
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 이미지 선택 및 업로드 로직 추가
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackbar('로그인이 필요합니다.');
      return;
    }

    // 1. 이미지 선택
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // 이미지 선택 취소 시 종료

    if (mounted) setState(() { _isLoading = true; }); // 로딩 시작

    try {
      final file = File(pickedFile.path);
      final fileName = 'profile_image_${user.uid}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('user_profiles').child(fileName);

      // 2. Firebase Storage에 업로드
      await storageRef.putFile(file);

      // 3. 다운로드 URL 획득
      final downloadUrl = await storageRef.getDownloadURL();

      // 4. Firestore에 URL 업데이트
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      // 5. 상태 업데이트 및 성공 메시지
      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _isLoading = false;
        });
        _showSnackbar('프로필 이미지가 성공적으로 변경되었습니다.');
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase 이미지 업로드/업데이트 오류: $e');
      _showSnackbar('이미지 변경에 실패했습니다. (${e.message})');
      if (mounted) setState(() { _isLoading = false; });
    } catch (e) {
      debugPrint('일반 이미지 업로드 오류: $e');
      _showSnackbar('이미지 변경 중 알 수 없는 오류가 발생했습니다.');
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 스낵바 표시 유틸리티
  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 메뉴 항목 위젯 (ListTile 디자인 대체)
  Widget _buildMenuItem({
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    bool isAction = true,
  }) {
    return InkWell(
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
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                if (isAction)
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
    final String nickname = _displayName;
    // 이메일 ID의 뒷 4자리를 추출 (DB에 별도 UID 4자리 필드가 없으므로 임시로 사용)
    final String displaySuffix = _authService.currentUserId != null && _authService.currentUserId!.length > 4
        ? _authService.currentUserId!.substring(_authService.currentUserId!.length - 4)
        : '0000';

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
          // 프로필 이미지 (url있으면 NetworkImage, 없으면 기본 아이콘)
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black12,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!) as ImageProvider
                    : null, // NetworkImage가 없으면 null
                child: _profileImageUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null, // URL이 없으면 기본 아이콘 표시
              ),
              Positioned(
                bottom: -5,
                left: 0,
                right: 0,
                child: InkWell( // 탭 가능하게 InkWell 사용
                  onTap: _pickAndUploadImage, // 이미지 변경 함수 호출
                  borderRadius: BorderRadius.circular(40), // 탭 영역 시각화
                  child: Container(
                    height: 18, // 높이를 사진에 맞게 조정
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // 사진의 어두운 하단 박스 모양 구현
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(40), // 원 모양에 맞게
                    ),
                  child: const Text(
                    '이미지 변경',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
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
                '$nickname # $displaySuffix',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // 직무/커뮤니티 (임시 값)
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _certifications.isEmpty
            ? [
          // 자격증이 없을 때
          Text(
            '보유한 자격증이 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ]
            : [
          // 자격증이 있을 때: 리스트 표시 (DB 필드가 'certifications'라고 가정)
          ..._certifications.map((cert) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
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
          // 수상 경력 (임시)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'SW 융합 해커톤 대회 [우수상] 수상',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
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
        const Divider(color: Colors.black, thickness: 1.0),
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

  // 로그아웃 로직 (옵션)
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.login,
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('내 프로필', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildProfileCard(),

            _buildCertificatesSection(),

            // 계정 섹션
            _buildSectionHeader('계정'),

            _buildMenuItem(
              title: '아이디',
              trailingText: _displayId,
              isAction: false,
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '비밀번호 변경',
              onTap: () {
                Navigator.pushNamed(context, RouteNames.passwordChange);
              },
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '닉네임 변경',
              onTap: () {
                Navigator.pushNamed(context, RouteNames.nicknameChange);
              },
            ),
            const Divider(color: Colors.black12, height: 1),

            // 게시물 섹션
            _buildSectionHeader('게시물'),

            _buildMenuItem(
              title: '내가 쓴 게시물',
              onTap: () {
                Navigator.pushNamed(context, RouteNames.myPosts);
              },
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '내가 쓴 댓글',
              onTap: () {
                Navigator.pushNamed(context, RouteNames.myComments);
              },
            ),
            const Divider(color: Colors.black12, height: 1),

            // 커뮤니티 섹션
            _buildSectionHeader('커뮤니티'),

            _buildMenuItem(
              title: '커뮤니티 변경',
              onTap: () {
                Navigator.pushNamed(context, RouteNames.communityChange);
              },
            ),
            const Divider(color: Colors.black12, height: 1),

            // 로그아웃 버튼
            _buildMenuItem(
              title: '로그아웃',
              //onTap: _signOut,
              isAction: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}