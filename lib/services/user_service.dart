import 'dart:convert';
import 'package:baysa_app/models/cst_class.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserService {
  // final String baseUrl = 'https://dnevnik.baysa.kz/tWcf/Service1.svc/';
  final String baseUrl = 'https://dnevnik.baysa.kz/tWcfTest/Service1.svc';

  // Метод для проверки пользователя по email
  Future<void> checkUserMs(String userName, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkUserMs?userName=$userName'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (_handleResponse(data, context)) {
          // Сохраняем данные в SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userFio', data['fio']);
          await prefs.setInt('schoolYear', data['schoolYear']);
          await prefs.setString('sid', data['sid']);
          await prefs.setInt('typeUser', data['typeUser']);
          await prefs.setInt('userId', data['userId']);
          print('Данные пользователя успешно сохранены');
        }
      } else {
        throw Exception('Ошибка запроса: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка запроса: $e');
    }
  }

  // Получаем начало и конец периода
  Future<List<String>> getFirstAndLastDate(
      int schoolYear, BuildContext context) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/getFirstAndLastDate?schoolYear=$schoolYear'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (_handleResponse({
          'rv': {'retNum': 0}
        }, context)) {
          // В данном случае, предположим, что проверка сессии всегда успешна
          List<String> dates = List<String>.from(data);
          print('Начало и конец периода: $dates');
          return dates;
        }
      } else {
        throw Exception('Ошибка получения дат');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

  // Получаем список классов для учителя
  Future<List<Map<String, dynamic>>> getClassesForTeacher(
      int teacherId, String sid, int schoolYear, BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/getClassesForTeacher?teacherId=$teacherId&sid=$sid&schoolYear=$schoolYear'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (_handleResponse(data, context)) {
          final classes = data['lstClass'] as List<dynamic>;
          print('Список классов: $classes');
          return classes.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Ошибка получения классов');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

  // Получаем список предметов для выбранного класса
  Future<List<Map<String, dynamic>>> getAllSubjectsForClass(int classId,
      int teacherId, String sid, int schoolYear, BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/getAllPredmetsForClass?classId=$classId&teacherId=$teacherId&sid=$sid&schoolYear=$schoolYear'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (_handleResponse(data, context)) {
          final subjects = data['lstPredmet'] as List<dynamic>;
          print('Список предметов: $subjects');
          return subjects.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Ошибка получения предметов');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

// Метод для получения списка занятий
  Future<List<Map<String, dynamic>>> getLessons({
    required int teacherId,
    required String date1,
    required String date2,
    required int classId,
    required String sid,
    required int schoolYear,
    required int subjectId,
    required BuildContext context, // Добавляем контекст для _handleResponse
  }) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/getLessons?teacherId=$teacherId&date1=$date1&date2=$date2&classId=$classId&sid=$sid&schoolYear=$schoolYear&subjectId=$subjectId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Проверяем ответ с помощью _handleResponse
        if (_handleResponse(data, context)) {
          final lessons = data['lstLesson'] as List<dynamic>;
          print('Список занятий: $lessons');
          return lessons.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Ошибка получения занятий');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

  // Метод для получения списка типов занятий
  Future<List<Map<String, dynamic>>> getGradeTypes(
      int teacherId, String sid, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getGradeTypes?teacherId=$teacherId&sid=$sid'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final gradeTypes = data['lstGradeType'] as List<dynamic>;
          print('Типы занятий: $gradeTypes');
          return gradeTypes.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Ошибка получения типов занятий');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

  // Метод для получения списка тем
  Future<List<Map<String, dynamic>>> getThemes(
      int subjectId, int classId, int schoolYear, int teacherId, String sid,
      {required int lessonId, required BuildContext context}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getThemes?predmet=$subjectId&classId=$classId&schoolYear=$schoolYear&teacherId=$teacherId&sid=$sid&lessonId=$lessonId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final themes = data['lstPredmet'] as List<dynamic>;
          print('Темы занятий: $themes');
          return themes.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Ошибка получения тем');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

// Метод для проверки наличия дублирующего урока
  Future<Map<String, dynamic>?> checkDoubleLesson({
    required int classId,
    required String date,
    required int subjectId,
    required int gradeType,
    required String sid,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/checkDoubleLesson?classId=$classId&date3=$date&predmetId=$subjectId&gradeType=$gradeType'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          print('Duplicate lesson check passed: $data');
          return data;
        }
      } else {
        throw Exception('Ошибка при проверке дублирующего урока.');
      }
    } catch (e) {
      print('Ошибка при проверке дублирующего урока: $e');
    }
    return null; // Возвращаем null в случае ошибки
  }

// Метод для проверки урока в расписании
  Future<Map<String, dynamic>?> checkWithSchedule({
    required int classId,
    required int subjectId,
    required int teacherId,
    required String date,
    required String sid,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/checkWithSchedule?classId=$classId&subjectId=$subjectId&teacherId=$teacherId&dt1=$date'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          print('Schedule check passed: $data');
          return data;
        }
      } else {
        throw Exception('Ошибка при проверке расписания урока.');
      }
    } catch (e) {
      print('Ошибка при проверке расписания урока: $e');
    }
    return null; // Возвращаем null в случае ошибки
  }

// Метод для сохранений оценок
  Future<Map<String, dynamic>?> putRate({
    required int lessonId,
    required int studentId,
    required int rate,
    required int notPresence,
    required int schoolYear,
    required int userId,
    required String comments,
    required String sid,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/putRate?lessonId=$lessonId&studentId=$studentId&rate=$rate&notPresence=$notPresence&schoolYear=$schoolYear&userId=$userId&comments=${Uri.encodeComponent(comments)}&sid=$sid'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (_handleResponse(data, context)) {
          print('Успешное сохранение оценки: $data');
          return data;
        }
      } else {
        throw Exception('Ошибка при сохранении оценки');
      }
    } catch (e) {
      print('Ошибка при сохранении оценки: $e');
    }
    return null; // Возвращаем null в случае ошибки
  }

  /// Метод для получения списка оценок учеников для определенного урока.
  Future<Map<String, dynamic>?> getRates({
    required int lessonId,
    required int teacherId,
    required String sid,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      // Отправляем запрос к API для получения оценок
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getRates?lessonId=$lessonId&schoolYear=$schoolYear&teacherId=$teacherId&sid=$sid'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          print('Успешное получение данных об оценках: $data');
          return data;
        }
      } else {
        throw Exception('Ошибка при получении оценок');
      }
    } catch (e) {
      print('Ошибка при получении оценок: $e');
    }
    return null; // Возвращаем null в случае ошибки
  }

  // Метод для сохранения изм
  recLesson({
    required int recId,
    required int classId,
    required String date,
    required int subjectId,
    required int teacherId,
    required int themeId,
    required int maxPoint,
    required int gradeType,
    required String sid,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/recLesson?recId=$recId&classId=$classId&date3string=$date&predmetId=$subjectId&teacherId=$teacherId&themeId=$themeId&maxPoint=$maxPoint&gradeType=$gradeType&sid=$sid&teacherId2=0&schoolYear=$schoolYear'),
        headers: {
          'accept': 'application/json, text/plain, */*',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          print('Урок сохранен успешно.');
          return data;
        }
      } else {
        throw Exception('Ошибка сохранения урока.');
      }
    } catch (e) {
      print('Ошибка при сохранении урока: $e');
    }
    return false;
  }

  // Метод выборки классов для добавления урока
  Future<List<Map<String, dynamic>>> getClassesForAddLesson(
      int teacherId, String sid, int schoolYear, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getClassesForAddLesson?teacherId=$teacherId&sid=$sid&schoolYear=$schoolYear'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if the response is successful
        if (_handleResponse(data, context)) {
          final classes = data['lstClass'] as List<dynamic>;
          print('Classes for add lesson: $classes');
          return classes.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Failed to fetch classes');
      }
    } catch (e) {
      print('Error fetching classes: $e');
    }
    return [];
  }

  // Метод выборки предметов для выбранного класса при добавлении урока
  Future<List<Map<String, dynamic>>> getPredmetsForAddLesson(int teacherId,
      int classId, String sid, int schoolYear, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getPredmetsForAddLesson?teacherId=$teacherId&classId=$classId&sid=$sid&schoolYear=$schoolYear'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if the response is successful
        if (_handleResponse(data, context)) {
          final subjects = data['lstPredmet'] as List<dynamic>;
          print('Subjects for add lesson: $subjects');
          return subjects.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Failed to fetch subjects');
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
    return [];
  }

  // Общий метод для обработки ответа
  bool _handleResponse(Map<String, dynamic> data, BuildContext context) {
    if (data['rv'] != null) {
      int retNum = data['rv']['retNum'];

      if (retNum == -2) {
        // Сессия неактивна
        _showSessionInactiveDialog(context, data['rv']['retStr'] ?? '');
        _clearStorage();
        return false;
      } else if (retNum == -1) {
        // Общая ошибка
        _showErrorDialog(context, data['rv']['retStr'] ?? '');
        return false;
      } else if (retNum < 0) {
        // Обработка других отрицательных кодов ошибок
        _showErrorDialog(
            context, data['rv']['retStr'] ?? 'Неизвестная ошибка.');
        return false;
      }
    }
    return true; // Если retNum == 0, считаем, что все прошло успешно
  }

  // Показ диалога об ошибке сессии
  void _showSessionInactiveDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Сессия неактивна'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('ОК'),
              onPressed: () {
                Navigator.of(context).pop();
                // Перенаправляем на экран авторизации после закрытия диалога
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog(
          message: message,
        );
      },
    );
  }

  // Очистка SharedPreferences и перенаправление на страницу авторизации
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('SharedPreferences очищены');
  }
}
