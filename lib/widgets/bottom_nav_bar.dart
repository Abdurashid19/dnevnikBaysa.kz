import 'package:baysa_app/screens/my_classes.dart';
import 'package:baysa_app/screens/studentPages/diary_page.dart';
import 'package:baysa_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/list_activities.dart'; // Подключаем главный экран (HomePage)

class BottomNavBar extends StatefulWidget {
  final User user; // Передаем объект User

  const BottomNavBar({Key? key, required this.user}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final UserService _userService = UserService();

  int _selectedIndex = 0;

  bool? _isTeacher; // Nullable state variable to store user type

  // Список виджетов для Учителя
  static const List<Widget> _teacherPages = <Widget>[
    ListActivities(),
    MyClassesPage(),
    Center(child: Text('Пока здесь пусто, но скоро будет всё и сразу!')),
  ];

  // Список виджетов для Ученика
  static const List<Widget> _studentPages = <Widget>[
    DiaryPage(),
    Center(child: Text('Тишина и покой... Но скоро тут закипит жизнь!')),
  ];

  // Список названий пунктов меню для Учителя
  static const List<BottomNavigationBarItem> _teacherMenuItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book),
      label: 'Список занятий',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Мои классы',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu),
      label: 'Меню',
    ),
  ];

  // Список названий пунктов меню для Ученика
  static const List<BottomNavigationBarItem> _studentMenuItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book),
      label: 'Дневник',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assessment),
      label: 'Итоговые оценки',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determineUserType();
  }

  // Метод для определения, является ли пользователь учителем
  void _determineUserType() async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем, есть ли сохранённый тип пользователя
    var typeUser = prefs.getInt('typeUser');
    if (typeUser == null) {
      final userEmail = prefs.getString('userEmail') ?? '';
      await _userService.checkUserMs(userEmail, context);
      typeUser = prefs.getInt('typeUser');
      setState(() {
        _isTeacher = typeUser == 1;
      });
    } else {
      setState(() {
        _isTeacher = typeUser == 1;
      });
    }
  }

  // Обработка нажатия на элемент нижнего меню
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isTeacher == null) {
      // Пока тип пользователя не определен, показываем индикатор загрузки
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _isTeacher!
          ? _teacherPages[_selectedIndex]
          : _studentPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _isTeacher! ? _teacherMenuItems : _studentMenuItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
