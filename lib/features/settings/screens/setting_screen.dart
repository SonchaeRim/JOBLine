import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import '../../../routes/app_routes.dart';

/// 설정 메인 화면 (임시)
class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MainScreen에서 이미 Scaffold와 AppBar를 제공하므로 body만 반환
    return ListView(
        children: [
          // 프로필 정보 섹션
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                SizedBox(height: 12),
                Text(
                  '사용자 이름',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '@user_id',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // 계정 설정
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('계정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 계정 설정 화면
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('아이디 변경'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.idChange);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('비밀번호 변경'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.passwordChange);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('닉네임 변경'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.nicknameChange);
            },
          ),
          const Divider(),
          
          // 게시물
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('내가 쓴 게시물'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.myPosts);
            },
          ),
          ListTile(
            leading: const Icon(Icons.comment),
            title: const Text('내가 쓴 댓글'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.myComments);
            },
          ),
          const Divider(),
          
          // 커뮤니티
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('커뮤니티 변경'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.communityChange);
            },
          ),
        ],
    );
  }
}

