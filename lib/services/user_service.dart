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
      // Enhanced error handling
      if (e is http.ClientException) {
        print('Ошибка запроса: Возможно, это проблема с CORS или URL - $e');
      } else {
        print('Ошибка запроса: $e');
      }
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

  /// Метод для получения списка предметов для класса
  Future<List<Map<String, dynamic>>?> getSubjects({
    required int studentId,
    required String sid,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      // Формируем URL запроса к сервису
      final String url =
          '$baseUrl/GetPredmetsForClass?studentId=$studentId&schoolYear=$schoolYear&sid=$sid';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Обрабатываем ответ с помощью метода _handleResponse
        if (_handleResponse(data, context)) {
          final List<dynamic> subjects = data['lstPredmet'] as List<dynamic>;
          print('Список предметов: $subjects');

          return subjects.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw Exception('Ошибка получения предметов');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении предметов: $e');
    }
    return null;
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

        if (_handleResponseData(data, context)) {
          // Проверка, если поле 'data' не пустое и не null
          final subjectsData = data['data'];
          if (subjectsData != null && subjectsData.isNotEmpty) {
            final subjects = jsonDecode(subjectsData) as List<dynamic>;
            return subjects.map((e) => e as Map<String, dynamic>).toList();
          } else {
            print('No subjects found or data is null.');
            return [];
          }
        }
      } else {
        throw Exception('Ошибка получения предметов');
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      _showErrorDialog(context, 'Произошла ошибка при получении данных');
    }
    return [];
  }

  /// Метод для получения списка оценок для студента
  Future<List<Map<String, dynamic>>?> getLstRateForStudent({
    required int studentId,
    required String date1,
    required String date2,
    required String sid,
    required int subjectId,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      final String url =
          '$baseUrl/getLstRateForStudent?studentId=$studentId&date1=$date1&date2=$date2&sid=$sid&subjectId=$subjectId&schoolYear=$schoolYear';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final List<dynamic> rates =
              data['lstRateForStudent'] as List<dynamic>;
          print('Список оценок: $rates');

          return rates.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw Exception('Ошибка получения списка оценок');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении списка оценок: $e');
    }
    return null;
  }

  // Метод для получения списка классов с помощью сервиса getListClass17
  Future<List<Map<String, dynamic>>> getListClass17({
    required int teacherId,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getListClass17?teacherId=$teacherId&schoolYear=$schoolYear'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final classes = jsonDecode(data['data']) as List<dynamic>;
          print('Список классов: $classes');
          return classes.map((e) => e as Map<String, dynamic>).toList();
        }
      } else {
        throw Exception('Ошибка получения списка классов');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    return []; // Возвращаем пустой список в случае ошибки
  }

// Метод для получения списка типов оценивания
  Future<List<Map<String, dynamic>>> getLstRateType(
      int subjectId, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getLstRateType?subjectId=$subjectId'),
        headers: {
          'accept': 'application/json, text/plain, */*',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final rateTypes = jsonDecode(data['data']) as List<dynamic>;
          return rateTypes.map((e) => e as Map<String, dynamic>).toList();
        } else {
          _showErrorDialog(
              context, data['message'] ?? 'Ошибка получения типов оценивания');
          return [];
        }
      } else {
        throw Exception('Ошибка получения типов оценивания');
      }
    } catch (e) {
      print('Ошибка: $e');
      _showErrorDialog(context, 'Произошла ошибка при получении данных.');
      return [];
    }
  }

  /// Метод для добавления учеников
  Future<bool> addStudentForSpecClass({
    required int classId,
    required int studentId,
    required int schoolYear,
    required BuildContext context,
  }) async {
    final url =
        '$baseUrl/addStudentForSpecClass?classId=$classId&studentId=$studentId&schoolYear=$schoolYear';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'accept': 'application/json, text/plain, */*',
      });

      final data = json.decode(response.body);

      if (_handleResponse(data, context)) {
        return true;
      } else {
        _showErrorDialog(
            context, data['message'] ?? 'Ошибка при добавлении ученика');
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, 'Произошла ошибка при добавлении ученика.');
      return false;
    }
  }

  // Метод для получения списка учеников в спец.классе
  Future<List<Map<String, dynamic>>> getListStudentForSpecClass({
    required int classId,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getListStudentForSpecClass?classId=$classId&schoolYear=$schoolYear'),
        headers: {
          'accept': 'application/json, text/plain, */*',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final students = jsonDecode(data['data']) as List<dynamic>;
          return students.map((e) => e as Map<String, dynamic>).toList();
        } else {
          _showErrorDialog(
              context, data['message'] ?? 'Ошибка получения списка учеников');
          return [];
        }
      } else {
        throw Exception('Ошибка получения списка учеников');
      }
    } catch (e) {
      print('Ошибка: $e');
      _showErrorDialog(context, 'Произошла ошибка при получении данных.');
      return [];
    }
  }

  // Метод для поиска учеников по спец.классу для добавления
  Future<List<Map<String, dynamic>>> getListStudentForSpecClassForSelect({
    required int schoolYear,
    required String query,
    required BuildContext context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getListStudentForSpecClassForSelect?schoolYear=$schoolYear&val=$query'),
        headers: {
          'accept': 'application/json, text/plain, */*',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          final students = jsonDecode(data['data']) as List<dynamic>;
          return students.map((e) => e as Map<String, dynamic>).toList();
        } else {
          _showErrorDialog(
              context, data['message'] ?? 'Ошибка поиска учеников');
          return [];
        }
      } else {
        throw Exception('Ошибка поиска учеников');
      }
    } catch (e) {
      print('Ошибка: $e');
      _showErrorDialog(context, 'Произошла ошибка при поиске данных.');
      return [];
    }
  }

  // Метод для
  Future<bool> saveSpecialClass({
    required int classId,
    required int teacherId,
    required int subjectId,
    required int schoolYear,
    required String className,
    required List<Map<String, dynamic>> jsonLstDayNum,
    required String periodType,
    required String rateTypeId,
    required BuildContext context,
  }) async {
    final url =
        '$baseUrl/recSpecClass?classId=$classId&teacherId=$teacherId&subjectId=$subjectId&schoolYear=$schoolYear&className=$className&jsonLstDayNum=${Uri.encodeComponent(json.encode(jsonLstDayNum))}&periodType=$periodType&rateTypeId=$rateTypeId';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'accept': 'application/json, text/plain, */*',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (_handleResponse(data, context)) {
          if (data['code'] == 0) {
            return true;
          } else {
            _showErrorDialog(
                context, data['message'] ?? 'Ошибка сохранения спец.класса');
            return false;
          }
        } else {
          _showErrorDialog(
              context, data['message'] ?? 'Ошибка обработки ответа сервера');
          return false;
        }
      } else {
        throw Exception('Ошибка сохранения спец.класса');
      }
    } catch (e) {
      print("Ошибка: $e");
      _showErrorDialog(context, 'Произошла ошибка при сохранении данных.');
      return false;
    }
  }

  /// Извлекает список предметов, доступных для указанного преподавателя и учебного года
  Future<List<Map<String, dynamic>>> getListPredmetForSpecClass({
    required int teacherId,
    required int schoolYear,
    required BuildContext context,
  }) async {
    try {
      // Build the API request URL
      final response = await http.get(
        Uri.parse(
            '$baseUrl/getListPredmetForSpecClass?teacherId=$teacherId&schoolYear=$schoolYear'),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Validate the response code and handle errors
        if (_handleResponse(data, context)) {
          // Parse and return the subject data
          final subjects = jsonDecode(data['data']) as List<dynamic>;
          return subjects.map((e) => e as Map<String, dynamic>).toList();
        } else {
          _showErrorDialog(
              context, data['message'] ?? 'Ошибка получения списка предметов');
          return [];
        }
      } else {
        throw Exception('Ошибка получения списка предметов');
      }
    } catch (e) {
      print('Ошибка: $e');
      _showErrorDialog(context, 'Произошла ошибка при получении данных.');
      return [];
    }
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

  bool _handleResponseData(Map<String, dynamic> data, BuildContext context) {
    if (data['code'] != null) {
      int retNum = data['code'];

      if (retNum == -2) {
        // Сессия неактивна
        _showSessionInactiveDialog(context, data['message'] ?? '');
        _clearStorage();
        return false;
      } else if (retNum == -1) {
        // Общая ошибка
        _showErrorDialog(context, data['message'] ?? '');
        return false;
      } else if (retNum < 0) {
        // Обработка других отрицательных кодов ошибок
        _showErrorDialog(context, data['message'] ?? 'Неизвестная ошибка.');
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
