import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobline/features/auth/services/auth_service.dart';

class NicknameChangeScreen extends StatefulWidget {
  const NicknameChangeScreen({super.key});
  @override
  State<NicknameChangeScreen> createState() => _NicknameChangeScreenState();
}

class _NicknameChangeScreenState extends State<NicknameChangeScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  // 로딩 상태 및 초기 닉네임 저장 변수
  bool _isLoading = true;
  String _initialNickname = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentNickname();
  }

  // 현재 닉네임 불러오기
  Future<void> _loadCurrentNickname() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      if (mounted) {
        _showSnackBar('로그인 정보가 없습니다.');
        Navigator.pop(context);
      }
      return;
    }

    try {
      // AuthService에 닉네임 가져오는 함수가 없으므로, Firestore에 직접 접근
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _initialNickname = data['nickname'] ?? ''; // 닉네임 필드 값 저장
            _nicknameController.text = _initialNickname!; // 컨트롤러에 초기값 설정
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _nicknameController.text = '';
            _isLoading = false;
          });
        }
      }

    } catch (e) {
      debugPrint("닉네임 로드 오류: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('닉네임 로드 중 오류가 발생했습니다.');
      }
    }
  }

  // 변경 완료 버튼 클릭 시 닉네임 업데이트
  Future<void> _updateNickname() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요.');
      return;
    }

    if (newNickname == _initialNickname) {
      _showSnackBar('기존 닉네임과 동일합니다.');
      return;
    }

    try {
      // 2. AuthService의 updateUserData 함수를 사용하여 Firestore 데이터 업데이트
      await _authService.updateUserData(nickname: newNickname);

      // 닉네임 업데이트 후 initialNickname을 업데이트하여 다음 동일 입력 방지
      _initialNickname = newNickname;

      // 성공 처리 및 화면 종료
      if (mounted) {
        _showSnackBar('닉네임이 성공적으로 변경되었습니다.');
        Navigator.pop(context, true); // 변경 성공을 알리며 이전 화면으로 돌아감
      }

    } catch (e) {
      _showSnackBar('닉네임 변경에 실패했습니다.');
      debugPrint("닉네임 업데이트 오류: $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController nicknameController = TextEditingController(text: "기존");
    // 로딩 중일 때 로딩 인디케이터 표시
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "닉네임 변경",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "닉네임",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nicknameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "변경 완료",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}