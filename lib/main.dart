import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'widgets/bottom_nav_bar.dart'; // Импортируем BottomNavBar
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация Flutter
  // await Firebase.initializeApp(); // Инициализация Firebase
  await initializeDefault();
  runApp(MyApp());
}

Future<void> initializeDefault() async {
  FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Initialized default app $app');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(
          primaryColor: Colors.blue,
          dialogBackgroundColor:
              Colors.white, // Устанавливаем фон диалогов на белый
          colorScheme: ColorScheme.light(
            primary: Colors.blue, // Цвет верхней панели диалога
            onPrimary: Colors.white, // Цвет текста на верхней панели
            surface: Colors.white, // Фон основной части диалога
            onSurface: Colors.black, // Цвет текста в диалоге
          ),
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ru', 'RU'),
        ],
        debugShowCheckedModeBanner: false,
        title: 'BaysaApp',
        navigatorKey: navigatorKey, // Передаем ключ навигатора в приложение
        initialRoute: '/', // Задаем начальный маршрут
        routes: {
          '/': (context) => const Wrapper(), // Главная страница
          '/login': (context) => const LoginScreen(), // Экран авторизации
          '/home': (context) =>
              BottomNavBar(user: FirebaseAuth.instance.currentUser!),
        },
        onUnknownRoute: (settings) {
          // Обработчик для неопределенных маршрутов
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Страница не найдена')),
            ),
          );
        },
      ),
    );
  }
}

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _checkUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем индикатор загрузки, пока ждем данные
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Произошла ошибка'));
        } else {
          final userData = snapshot.data;
          if (userData != null && userData['uid'] != null) {
            // Если данные о пользователе сохранены, перенаправляем на BottomNavBar
            return BottomNavBar(
                user: FirebaseAuth.instance.currentUser!); // Меню с навигацией
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
