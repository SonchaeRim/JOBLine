import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobline/features/auth/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/services/profile_service.dart';
import 'dart:io'; // File 사용

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  String _displayName = '사용자 이름';
  String _displayId = 'user_id';
  String? _profileImageUrl;

  List<String> _certifications = [];

  String _currentCommunity = '미설정';

  final String _currentRank = 'SILVER';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // users/{uid}.mainCommunityId -> communities/{id}.name 가져오는 함수
  Future<String> _loadCommunityName(String mainId) async {
    if (mainId.isEmpty) return '미설정';

    try {
      final commDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(mainId)
          .get();

      if (commDoc.exists && commDoc.data() != null) {
        final commData = commDoc.data() as Map<String, dynamic>;
        final name = (commData['name'] ?? '').toString();
        if (name.isNotEmpty) return name;
      }

      // name이 없거나 문서가 없으면 id라도 표시
      return mainId;
    } catch (_) {
      return mainId;
    }
  }

  // Firestore에서 사용자 프로필 정보 로드
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // 닉네임 및 ID 처리
        final nickname = (data['nickname'] ?? '닉네임 없음').toString();

        // ✅ (중요) 너 문서에 loginId가 있으니까 name 말고 loginId로 읽는 게 맞음
        final userId = (data['loginId'] ?? 'ID 없음').toString();

        final imageUrl = data['profileImageUrl'] as String?;

        // 자격증/수상 데이터 처리
        final List<String> loadedCertifications =
            (data['certifications'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [];

        // ✅ (추가) mainCommunityId 읽어서 커뮤니티 이름 조회
        final mainId = (data['mainCommunityId'] ?? '').toString();
        final communityName = await _loadCommunityName(mainId);

        if (!mounted) return;
        setState(() {
          _displayName = nickname;
          _displayId = userId;
          _certifications = loadedCertifications;
          _profileImageUrl = imageUrl;
          _currentCommunity = communityName; // ✅ 여기서 반영!
          _isLoading = false;
        });
      } else {
        // 문서 없는 경우
        if (!mounted) return;
        final emailId = user.email?.split('@').first ?? '사용자';
        setState(() {
          _displayName = emailId;
          _displayId = emailId;
          _currentCommunity = '미설정';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("설정 화면 프로필 로드 오류: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 프로필 이미지 변경
  Future<XFile?> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      debugPrint("이미지 선택 오류: $e");
      _showSnackbar('이미지 선택에 실패했습니다.');
      return null;
    }
  }

  void _pickAndUploadImage() async {
    if (_profileService.uid == null) {
      _showSnackbar('로그인 정보가 없습니다.');
      return;
    }

    final XFile? pickedFile = await _pickImageFromGallery();

    if (pickedFile != null) {
      if (mounted) setState(() => _isLoading = true);
      try {
        final File imageFile = File(pickedFile.path);
        final newImageUrl = await _profileService.uploadProfileImage(imageFile);

        if (!mounted) return;
        setState(() {
          _profileImageUrl = newImageUrl;
          _isLoading = false;
        });

        _showSnackbar('프로필 이미지가 성공적으로 변경되었습니다.');
      } catch (e) {
        debugPrint("이미지 업로드/저장 오류: $e");
        if (mounted) setState(() => _isLoading = false);
        _showSnackbar('이미지 업로드에 실패했습니다.');
      }
    } else {
      _showSnackbar('이미지 선택이 취소되었습니다.');
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

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
                    style:
                    TextStyle(fontSize: 15, color: Colors.grey.shade600),
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

  Widget _buildProfileCard() {
    final String nickname = _displayName;

    final String displaySuffix =
    _authService.currentUserId != null && _authService.currentUserId!.length > 4
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
          SizedBox(
            height: 100,
            width: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black12,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!) as ImageProvider
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickAndUploadImage,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
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
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$nickname # $displaySuffix',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // ✅ 여기! 고정값 아니고 DB 메인 커뮤니티 이름이 뜸
              Text(
                _currentCommunity,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Text(
            '보유한 자격증이 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ]
            : [
          ..._certifications.map(
                (cert) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      cert,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: const [
                Text('🏅', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
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

  Future<void> _signOut() async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말로 로그아웃 하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (confirm) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.login,
                (Route<dynamic> route) => false,
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃에 실패했습니다.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            const Text('내 프로필',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildProfileCard(),
            _buildCertificatesSection(),

            _buildSectionHeader('계정'),

            _buildMenuItem(
              title: '아이디',
              trailingText: _displayId,
              isAction: false,
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '비밀번호 변경',
              onTap: () => Navigator.pushNamed(context, RouteNames.passwordChange),
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '닉네임 변경',
              onTap: () => Navigator.pushNamed(context, RouteNames.nicknameChange),
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildSectionHeader('게시물'),

            _buildMenuItem(
              title: '내가 쓴 게시물',
              onTap: () => Navigator.pushNamed(context, RouteNames.myPosts),
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '내가 쓴 댓글',
              onTap: () => Navigator.pushNamed(context, RouteNames.myComments),
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildSectionHeader('커뮤니티'),

            _buildMenuItem(
              title: '커뮤니티 변경',
              onTap: () async {
                // 변경 화면 갔다가 돌아오면 다시 로드해서 반영되게
                await Navigator.pushNamed(context, RouteNames.communityChange);
                await _loadUserProfile(); // ✅ 돌아오면 즉시 갱신
              },
            ),
            const Divider(color: Colors.black12, height: 1),

            _buildMenuItem(
              title: '로그아웃',
              onTap: _signOut,
              isAction: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
