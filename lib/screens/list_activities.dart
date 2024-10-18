import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class ListActivities extends StatefulWidget {
  const ListActivities({Key? key}) : super(key: key);

  @override
  _ListActivitiesState createState() => _ListActivitiesState();
}

class _ListActivitiesState extends State<ListActivities> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Метод для загрузки данных пользователя
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userEmail = prefs.getString('userEmail');

    if (userEmail != null) {
      // Вызываем сервис для проверки пользователя и сохранения данных
      await _userService.checkUserMs(userEmail);

      // Загружаем сохраненные данные
      final userData = await _userService.getUserData();

      setState(() {
        _userData = userData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список занятий'),
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text('ФИО: ${_userData?['fio'] ?? 'Нет данных'}'),
                ),
                ListTile(
                  title: Text(
                      'Год обучения: ${_userData?['schoolYear'] ?? 'Нет данных'}'),
                ),
                ListTile(
                  title: Text('SID: ${_userData?['sid'] ?? 'Нет данных'}'),
                ),
                ListTile(
                  title: Text(
                      'Тип пользователя: ${_userData?['typeUser'] == 1 ? 'Учитель' : 'Ученик'}'),
                ),
                ListTile(
                  title: Text(
                      'ID пользователя: ${_userData?['userId'] ?? 'Нет данных'}'),
                ),
              ],
            ),
    );
  }
}
