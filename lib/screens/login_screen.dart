import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_page.dart'; // Импорт HomePage

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
                  final user =
                      await Provider.of<AuthService>(context, listen: false)
                          .signInWithMicrosoft(context);

                  // Закрываем индикатор загрузки
                  Navigator.of(context).pop();

                  if (user != null) {
                    // Если авторизация успешна, перенаправляем на HomePage и передаем данные пользователя
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HomePage(), // Передаем объект User
                      ),
                    );
                  }
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
}
