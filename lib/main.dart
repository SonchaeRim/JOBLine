import 'package:flutter/material.dart';
import 'routes/app_routes.dart';             // 라우팅 설정
import 'core/theme/app_colors.dart';        // 색상 테마
import 'core/theme/app_text_styles.dart';   // 텍스트 스타일
import 'package:firebase_core/firebase_core.dart';

// Flutter 앱 실행 진입점
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ Firebase 준비
  await Firebase.initializeApp();

  runApp(const MyApp());
}

// 앱 전체를 감싸는 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Line',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        textTheme: AppTextStyles.textTheme,
      ),
      initialRoute: AppRoutes.initial,   // 시작 화면
      routes: AppRoutes.routes,          // 라우트 매핑
    );
  }
}