import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Future<User?> signInWithMicrosoftWeb(BuildContext context) async {
    try {
      // Вход через Microsoft
      final provider = OAuthProvider("microsoft.com");

      provider.setCustomParameters({
        'tenant': 'd424a0c8-160a-46e7-8127-0d7b243d9809', // Ваш tenant
        'prompt': 'login',
      });

      // Выполняем аутентификацию через всплывающее окно для веб
      final UserCredential userCredential =
          await _firebaseAuth.signInWithPopup(provider);

      // Получаем информацию о пользователе
      final User? user = userCredential.user;

      // Проверяем, что авторизация прошла успешно
      if (user != null) {
        print("Успешная авторизация пользователя: ${user.displayName}");

        // Сохраняем данные пользователя в SharedPreferences
        await _saveUserData(user);

        return user;
      } else {
        print("Авторизация не удалась.");
        return null;
      }
    } catch (e) {
      print("Ошибка авторизации: $e");

      // Показываем ошибку через AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка авторизации"),
            content: Text("Не удалось выполнить вход: $e"),
            actions: [
              TextButton(
                child: const Text("ОК"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      return null;
    }
  }

  // Метод для авторизации через Microsoft
  Future<User?> signInWithMicrosoft(BuildContext context) async {
    try {
      // Вход через Microsoft
      final provider = OAuthProvider("microsoft.com");

      provider.setCustomParameters({
        'tenant': 'd424a0c8-160a-46e7-8127-0d7b243d9809', // Ваш tenant
        'prompt': 'login',
      });

      // Выполняем аутентификацию
      final UserCredential userCredential =
          await _firebaseAuth.signInWithProvider(provider);

      // Получаем информацию о пользователе
      final User? user = userCredential.user;

      // Проверяем, что авторизация прошла успешно
      if (user != null) {
        print("Успешная авторизация пользователя: ${user.displayName}");

        // Сохраняем данные пользователя в SharedPreferences
        await _saveUserData(user);

        return user;
      } else {
        print("Авторизация не удалась.");
        return null;
      }
    } catch (e) {
      print("Ошибка авторизации: $e");

      // Показываем ошибку через AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка авторизации"),
            content: Text("Не удалось выполнить вход: $e"),
            actions: [
              TextButton(
                child: const Text("ОК"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      return null;
    }
  }

  // Метод для сохранения данных пользователя
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userUID', user.uid);
    await prefs.setString('userEmail', user.email ?? '');
    await prefs.setString('userDisplayName', user.displayName ?? '');
  }

  // Метод для получения данных пользователя
  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('userUID');
    final String? email = prefs.getString('userEmail');
    final String? displayName = prefs.getString('userDisplayName');

    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }

  // Метод для удаления данных пользователя
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userUID');
    await prefs.remove('userEmail');
    await prefs.remove('userDisplayName');
  }
}
