import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_page.dart'; // Подключаем главный экран (HomePage)

class BottomNavBar extends StatefulWidget {
  final User user; // Передаем объект User

  const BottomNavBar({Key? key, required this.user}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  // Список виджетов для Учителя
  static const List<Widget> _teacherPages = <Widget>[
    HomePage(),
    Center(child: Text('Задания')),
    Center(child: Text('Студенты')),
  ];

  // Список виджетов для Ученика
  static const List<Widget> _studentPages = <Widget>[
    HomePage(),
    Center(child: Text('Уроки')),
    Center(child: Text('Оценки')),
  ];

  // Метод для определения, какое меню показывать (Учитель или Ученик)
  bool isTeacher() {
    // Пока по дефолту считаем, что это учитель
    // В будущем можно добавить логику определения роли пользователя
    return true; // Вернет true, если пользователь — Учитель, иначе Ученик
  }

  // Список названий пунктов меню для Учителя
  static const List<BottomNavigationBarItem> _teacherMenuItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Главная',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Задания',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Студенты',
    ),
  ];

  // Список названий пунктов меню для Ученика
  static const List<BottomNavigationBarItem> _studentMenuItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Главная',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'Уроки',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.grade),
      label: 'Оценки',
    ),
  ];

  // Обработка нажатия на элемент нижнего меню
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isTeacher()
          ? _teacherPages[
              _selectedIndex] // Если учитель — показываем страницы для учителя
          : _studentPages[_selectedIndex], // Если ученик — страницы для ученика
      bottomNavigationBar: BottomNavigationBar(
        items: isTeacher() ? _teacherMenuItems : _studentMenuItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
