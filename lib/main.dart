import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Обеспечиваем инициализацию биндингов Flutter
  await Firebase
      .initializeApp(); // Инициализация Firebase перед запуском приложения
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'BaysaApp',
        navigatorKey: navigatorKey, // Передаем ключ навигатора в приложение
        home: const Wrapper(), // Используем новый экран Wrapper
      ),
    );
  }
}

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkUserLoggedIn(),
      builder: (context, AsyncSnapshot<Map<String, String?>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем индикатор загрузки, пока ждем данные
          return const Center(child: CircularProgressIndicator());
        } else {
          final userData = snapshot.data;
          if (userData != null && userData['uid'] != null) {
            // Если данные о пользователе сохранены, перенаправляем на HomePage
            return HomePage(
              user: FirebaseAuth.instance
                  .currentUser!, // Мы можем использовать текущего пользователя
            );
          } else {
            // Если данных нет, показываем LoginScreen
            return const LoginScreen();
          }
        }
      },
    );
  }

  // Проверяем, есть ли данные пользователя в SharedPreferences
  Future<Map<String, String?>> _checkUserLoggedIn() async {
    final authService = AuthService();
    return await authService.getUserData();
  }
}
