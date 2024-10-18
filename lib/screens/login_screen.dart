import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Заголовок экрана
              Text(
                'Добро пожаловать',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900, // Цвет заголовка
                ),
              ),
              const SizedBox(height: 15),

              // Подзаголовок
              Text(
                'Войдите, чтобы продолжить',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey, // Цвет подзаголовка
                ),
              ),
              const SizedBox(height: 50),

              // Кнопка для входа через Microsoft
              ElevatedButton(
                onPressed: () async {
                  // Показываем индикатор загрузки
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );

                  // Попытка авторизации через Microsoft
                  try {
                    // Вход через Microsoft
                    final provider = OAuthProvider("microsoft.com");

                    // Открываем Microsoft OAuth через Firebase
                    final UserCredential userCredential =
                        await FirebaseAuth.instance.signInWithPopup(provider);

                    // Успешный вход
                    final user = userCredential.user;
                    if (user != null) {
                      print("Вход выполнен: ${user.displayName}");
                    }
                  } catch (e) {
                    print("Ошибка авторизации: $e");
                  }
                  //
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700, // Цвет кнопки
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Скругленные углы
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 40), // Отступы внутри кнопки
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.login,
                        color: Colors.white), // Иконка "вход"
                    const SizedBox(width: 10),
                    const Text(
                      'Войти через Microsoft',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // Цвет текста на кнопке
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Метод для показа сообщения об ошибке
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Домашняя страница'),
      ),
      body: const Center(
        child: Text('Добро пожаловать в приложение после авторизации!'),
      ),
    );
  }
}
