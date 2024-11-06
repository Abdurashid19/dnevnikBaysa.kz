import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования дат
import 'package:shared_preferences/shared_preferences.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final UserService _userService = UserService();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _grades = [];
  Map<String, dynamic>? _selectedSubject;
  int? _savedSubjectId; // Добавлено
  bool _isLoading = false;
  String? sid;
  int? studentId;
  int? schoolYear;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _initializeDates();
    await _loadSavedParameters();
    await _fetchSubjects();

    // После загрузки предметов устанавливаем выбранный предмет
    if (_savedSubjectId != null) {
      final subject = _subjects.firstWhere(
        (subject) => subject['id'] == _savedSubjectId,
        orElse: () => _subjects.first,
      );
      setState(() {
        _selectedSubject = subject;
      });
    } else {
      setState(() {
        _selectedSubject = _subjects.first;
      });
    }

    // Если все параметры присутствуют, обновляем список
    if (_startDateController.text.isNotEmpty &&
        _endDateController.text.isNotEmpty &&
        _selectedSubject != null) {
      _onUpdatePressed();
    }
  }

  // Открытие диалога выбора даты
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('dd.MM.yyyy').parse(controller.text);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      locale: const Locale('ru', 'RU'),
      context: context,
      initialDate: initialDate.isAfter(today) ? today : initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        controller.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context, controller),
            ),
          ),
          keyboardType: TextInputType.datetime,
        ),
      ],
    );
  }

  void _initializeDates() {
    final today = DateTime.now();
    final formattedToday = DateFormat('dd.MM.yyyy').format(today);

    _startDateController.text = formattedToday;
    _endDateController.text = formattedToday;
  }

  Future<void> _loadSavedParameters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStartDate = prefs.getString('startDate');
    final savedEndDate = prefs.getString('endDate');
    final savedSubjectId = prefs.getInt('selectedSubjectId');

    if (savedStartDate != null &&
        savedEndDate != null &&
        savedSubjectId != null) {
      setState(() {
        _startDateController.text = savedStartDate;
        _endDateController.text = savedEndDate;
        _savedSubjectId = savedSubjectId;
      });
    }
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      sid = prefs.getString('sid');
      studentId = prefs.getInt('userId');
      schoolYear = prefs.getInt('schoolYear') ?? 2024;

      if (sid == null || studentId == null || schoolYear == null) {
        final userEmail = prefs.getString('userEmail') ?? '';
        await _userService.checkUserMs(userEmail, context);

        // Повторно получаем данные после загрузки
        sid = prefs.getString('sid');
        studentId = prefs.getInt('userId');
        schoolYear = prefs.getInt('schoolYear') ?? 2024;
      }

      // Используем метод из UserService для получения предметов
      final response = await _userService.getSubjects(
        studentId: studentId!,
        sid: sid!,
        schoolYear: schoolYear!,
        context: context,
      );

      setState(() {
        _subjects = response!;
      });
    } catch (e) {
      print('Ошибка при получении предметов: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog(
          message: message,
        );
      },
    );
  }

  bool _validateDates() {
    try {
      final startDate =
          DateFormat('dd.MM.yyyy').parse(_startDateController.text);
      final endDate = DateFormat('dd.MM.yyyy').parse(_endDateController.text);

      if (startDate.isAfter(endDate)) {
        _showErrorDialog('Начальная дата не может быть позже конечной даты.');
        return false;
      }

      return true;
    } catch (e) {
      _showErrorDialog('Некорректный формат дат.');
      return false;
    }
  }

  Widget _buildGradeItem(Map<String, dynamic> grade) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Дата урока
          Text(
            '${formatDateString(grade['lessonDateString']) ?? ''}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),

          // Предмет
          Text(
            grade['subjectName'] ?? 'Предмет не указан',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Тип оценки и оценка
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                grade['gradeTypeName'] ?? '',
                style: TextStyle(fontSize: 16),
              ),
              if (grade['presence'] != true)
                Text(
                  grade['rateString'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Присутствие
          if (grade['presence'] == true)
            Text(
              '${grade['presence'] == true ? 'Отсутствовал' : 'Присутствовал'}',
              style: TextStyle(
                color: grade['presence'] == true ? Colors.red : Colors.green,
              ),
            ),
          // Учитель
          Text(
            'Учитель: ${grade['teacherName'] ?? ''}',
          ),
          // Комментарий (если есть)
          if (grade['comment'] != null &&
              grade['comment'].toString().isNotEmpty)
            Text(
              'Комментарий:  ${grade['comment']}',
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      isDense: true,
      isExpanded: true,
      dropdownColor: Colors.white,
      value: _selectedSubject,
      decoration: InputDecoration(
        labelText: 'Предмет',
        border: OutlineInputBorder(),
      ),
      items: _subjects.map((subject) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: subject,
          child: Text(subject['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSubject = value;
        });
      },
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _onUpdatePressed,
      child: Text('Обновить'),
    );
  }

  void _onUpdatePressed() async {
    if (!_validateDates()) {
      return;
    } else if (_selectedSubject == null) {
      return _showErrorDialog('Не выбран предмет');
    } else {
      // Сохраняем выбранные параметры
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('startDate', _startDateController.text);
      await prefs.setString('endDate', _endDateController.text);
      await prefs.setInt('selectedSubjectId', _selectedSubject!['id']);

      setState(() {
        _isLoading = true;
        _grades.clear(); // Очищаем предыдущие оценки
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final sid = prefs.getString('sid');
        final studentId = prefs.getInt('userId');
        final schoolYear = prefs.getInt('schoolYear') ?? 2024;

        if (sid == null || studentId == null) {
          throw Exception('Необходимые данные отсутствуют');
        }

        final String date1 = _startDateController.text;
        final String date2 = _endDateController.text;
        final int subjectId = _selectedSubject?['id'] ?? 0;

        // Форматируем даты в нужный формат для запроса
        final dateFormat = DateFormat('EEE MMM dd yyyy', 'en_US');
        final date1Formatted =
            dateFormat.format(DateFormat('dd.MM.yyyy').parse(date1));
        final date2Formatted =
            dateFormat.format(DateFormat('dd.MM.yyyy').parse(date2));

        final grades = await _userService.getLstRateForStudent(
          studentId: studentId,
          date1: date1Formatted,
          date2: date2Formatted,
          sid: sid,
          subjectId: subjectId,
          schoolYear: schoolYear,
          context: context,
        );

        if (grades != null) {
          setState(() {
            _grades = sortByLessonDateDescending(grades);
          });
        } else {
          // Обработка ошибки
          print('Ошибка при получении оценок');
        }
      } catch (e) {
        print('Ошибка при получении оценок: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> sortByLessonDateDescending(
      List<Map<String, dynamic>> data) {
    data.sort((a, b) {
      DateTime dateA = DateTime.parse(a['lessonDateString']);
      DateTime dateB = DateTime.parse(b['lessonDateString']);
      return dateB.compareTo(dateA); // Сортировка: от последней даты к ранней
    });
    return data;
  }

  // Метод для выхода и очистки данных
  Future<void> _logout() async {
    // Очищаем данные в SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Выходим из Firebase
    await FirebaseAuth.instance.signOut();

    // Переход на экран входа после небольшой задержки
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cst.backgroundApp,
      appBar: AppBar(
        title: Text('Дневник'),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  CustomCard(
                    child: Column(
                      children: [
                        // Поля выбора дат
                        Row(
                          children: [
                            Expanded(
                                child: _buildDateField(
                                    'Начало периода', _startDateController)),
                            const SizedBox(width: 16), // Отступ между полями
                            Expanded(
                                child: _buildDateField(
                                    'Конец периода', _endDateController)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Выпадающий список предметов
                        _buildSubjectDropdown(),
                        const SizedBox(height: 16),
                        // Кнопка "Обновить"
                        _buildUpdateButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Отображение списка оценок
                  _grades.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _grades.length,
                          itemBuilder: (context, index) {
                            return _buildGradeItem(_grades[index]);
                          },
                        )
                      : Text('Нет данных для отображения'),
                ],
              ),
            ),
    );
  }
}
