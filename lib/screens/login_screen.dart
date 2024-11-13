import 'package:baysa_app/models/cst_class.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      print(e);
      return 'Неизвестная версия';
    }
  }

  bool _isTestEnvironment() {
    // Проверка на тестовую среду для веба
    if (kIsWeb) {
      final uri = Uri.base.toString();
      return uri.contains('test') || uri.contains('localhost');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isTestEnvironment =
        _isTestEnvironment(); // Проверка на тестовую среду

    return Scaffold(
      backgroundColor: Cst.backgroundApp,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Добро пожаловать',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Войдите, чтобы продолжить',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );

                  final AuthService authService =
                      Provider.of<AuthService>(context, listen: false);
                  final user = kIsWeb
                      ? await authService
                          .signInWithMicrosoftWeb(context) // Call for web
                      : await authService
                          .signInWithMicrosoft(context); // Call for mobile

                  Navigator.of(context).pop();

                  if (user != null) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.login, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text(
                      'Войти через Microsoft',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<String>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Загрузка версии...');
                  } else if (snapshot.hasError) {
                    return const Text('Ошибка загрузки версии');
                  } else {
                    return Text(
                      'Version: ${snapshot.data}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 5),
              if (isTestEnvironment)
                Center(
                  child: Text(
                    'Тестовая версия',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
