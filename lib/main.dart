import 'package:baysa_app/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';

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
        home: const LoginScreen(),
      ),
    );
  }
}
