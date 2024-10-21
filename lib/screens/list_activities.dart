import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class ListActivities extends StatefulWidget {
  const ListActivities({Key? key}) : super(key: key);

  @override
  _ListActivitiesState createState() => _ListActivitiesState();
}

class _ListActivitiesState extends State<ListActivities> {
  final UserService _userService = UserService();

  // Контроллеры для полей даты
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  // Переменные для хранения данных
  String? _fio;
  String? _sid;
  int? _schoolYear;
  int? _teacherId;

  List<String> _classes = [];
  String? _selectedClass;
  Map<String, int> _classMap =
      {}; // Для хранения соответствия между именами и ID классов

  List<String> _subjects = [];
  String? _selectedSubject;
  Map<String, int> _subjectMap =
      {}; // Для хранения соответствия между именами и ID предметов

  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Метод для загрузки начальных данных
  Future<void> _loadInitialData() async {
    try {
      // Получаем данные пользователя из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _fio = prefs.getString('userFio');
      _sid = prefs.getString('sid');
      _schoolYear = prefs.getInt('schoolYear') ?? 2024;
      _teacherId = prefs.getInt('userId');

      // Если данных нет, необходимо их загрузить
      if (_fio == null || _sid == null || _teacherId == null) {
        final userEmail = prefs.getString('userEmail') ?? '';
        await _userService.checkUserMs(userEmail, context);

        // Повторно получаем данные после загрузки
        _fio = prefs.getString('userFio');
        _sid = prefs.getString('sid');
        _schoolYear = prefs.getInt('schoolYear') ?? 2024;
        _teacherId = prefs.getInt('userId');
      }

      // Получаем даты начала и конца периода
      final dates =
          await _userService.getFirstAndLastDate(_schoolYear!, context);
      _startDateController.text = _formatDate(dates[0]);
      _endDateController.text = _formatDate(dates[1]);

      // Получаем список классов
      final classData = await _userService.getClassesForTeacher(
          _teacherId!, _sid!, _schoolYear!, context);

      // Заполняем _classes и _classMap
      _classes = [];
      _classMap = {};
      for (var cls in classData) {
        _classes.add(cls['clsName']);
        _classMap[cls['clsName']] = cls['id'];
      }

      // Устанавливаем выбранный класс по умолчанию
      _selectedClass = _classes.isNotEmpty ? _classes[0] : null;

      // Загружаем предметы для выбранного класса
      if (_selectedClass != null) {
        await _loadSubjects(_classMap[_selectedClass]!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  // Метод для загрузки предметов по ID класса
  Future<void> _loadSubjects(int classId) async {
    final subjectData = await _userService.getAllSubjectsForClass(
        classId, _teacherId!, _sid!, _schoolYear!, context);

    // Заполняем _subjects и _subjectMap
    _subjects = [];
    _subjectMap = {};
    for (var subj in subjectData) {
      _subjects.add(subj['name']);
      _subjectMap[subj['name']] = subj['id'];
    }

    // Устанавливаем выбранный предмет по умолчанию
    setState(() {
      _selectedSubject = _subjects.isNotEmpty ? _subjects[0] : null;
    });
  }

  // Метод для форматирования даты
  String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }

  Future<void> _updateLessons() async {
    try {
      final classId = _classMap[_selectedClass]!;
      final subjectId = _subjectMap[_selectedSubject]!;

      final startDate = DateFormat('EEE MMM dd yyyy')
          .format(DateFormat('dd.MM.yyyy').parse(_startDateController.text));
      final endDate = DateFormat('EEE MMM dd yyyy')
          .format(DateFormat('dd.MM.yyyy').parse(_endDateController.text));

      final lessons = await _userService.getLessons(
        teacherId: _teacherId!,
        date1: startDate,
        date2: endDate,
        classId: classId,
        sid: _sid!,
        schoolYear: _schoolYear!,
        subjectId: subjectId,
        context: context,
      );

      setState(() {
        _lessons = lessons;
      });
    } catch (e) {
      print('Ошибка при обновлении данных: $e');
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

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        controller.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Список занятий',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 10, 84, 255),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ФИО преподавателя
                  Text(
                    'ФИО: $_fio',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Поля для выбора дат с возможностью изменения
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
                  const SizedBox(height: 20),

                  // Выпадающие меню для класса и предмета
                  _buildClassDropdown(),
                  const SizedBox(height: 20),
                  _buildSubjectDropdown(),
                  const SizedBox(height: 30),

                  // Кнопка обновить
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateLessons,
                      child: const Text('Обновить'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLessonsTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildLessonsTable() {
    if (_lessons.isEmpty) {
      return const Center(child: Text('Нет данных для отображения.'));
    }

    return Column(
      children: [
        Text(
          'Класс: $_selectedClass',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FractionColumnWidth(0.1),
            1: FractionColumnWidth(0.2),
            2: FractionColumnWidth(0.2),
            3: FractionColumnWidth(0.5),
          },
          children: [
            _buildTableHeader(),
            ..._lessons.map((lesson) => _buildLessonRow(lesson)).toList(),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.grey),
      children: const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('№', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Дата', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Период', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Тема', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  TableRow _buildLessonRow(Map<String, dynamic> lesson) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('${lesson['id']}'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('${lesson['date2']}'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('${lesson['typePeriod']}'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('${lesson['themeName']}'),
        ),
      ],
    );
  }

  // Виджет для поля даты
  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
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

  // Виджет для выпадающего списка классов
  Widget _buildClassDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Класс', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _selectedClass,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (String? newValue) async {
            setState(() {
              _selectedClass = newValue!;
            });
            // Загружаем предметы для выбранного класса
            await _loadSubjects(_classMap[_selectedClass]!);
          },
          items: _classes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Виджет для выпадающего списка предметов
  Widget _buildSubjectDropdown() {
    // Если список предметов содержит только один элемент, выбираем его автоматически
    if (_subjects.length == 1) {
      _selectedSubject = _subjects[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Предмет', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _selectedSubject != null && _selectedSubject!.isNotEmpty
              ? _selectedSubject
              : null, // Показать пустое поле, если нет значения
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSubject = newValue!;
            });
          },
          items: _subjects.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
