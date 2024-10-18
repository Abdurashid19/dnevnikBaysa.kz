import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String baseUrl = 'https://dnevnik.baysa.kz/tWcf/Service1.svc/';

  // Метод для проверки пользователя по email
  Future<void> checkUserMs(String userName) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}checkUserMs?userName=$userName'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Сохраняем данные в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userFio', data['fio']);
        await prefs.setInt('schoolYear', data['schoolYear']);
        await prefs.setString('sid', data['sid']);
        await prefs.setInt('typeUser', data['typeUser']);
        await prefs.setInt('userId', data['userId']);
        print('Данные пользователя успешно сохранены');
      } else {
        throw Exception('Ошибка запроса: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка запроса: $e');
    }
  }

  // Метод для получения данных пользователя из SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fio': prefs.getString('userFio'),
      'schoolYear': prefs.getInt('schoolYear'),
      'sid': prefs.getString('sid'),
      'typeUser': prefs.getInt('typeUser'),
      'userId': prefs.getInt('userId'),
    };
  }
}
