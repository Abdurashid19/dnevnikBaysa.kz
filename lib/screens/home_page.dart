import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // Метод для получения данных пользователя из SharedPreferences
  Future<Map<String, String?>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? displayName = prefs.getString('userDisplayName');
    final String? email = prefs.getString('userEmail');
    final String? uid = prefs.getString('userUID');

    return {
      'displayName': displayName,
      'email': email,
      'uid': uid,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Домашняя страница'),
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Ошибка загрузки данных'));
          } else if (snapshot.hasData) {
            final userData = snapshot.data;
            final displayName = userData?['displayName'] ?? 'Пользователь';
            final email = userData?['email'] ?? 'Не указан';
            final uid = userData?['uid'] ?? 'Нет UID';

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Добро пожаловать, $displayName!',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Text('Email: $email'),
                  const SizedBox(height: 20),
                  Text('UID: $uid'),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Нет данных пользователя'));
          }
        },
      ),
    );
  }
}
