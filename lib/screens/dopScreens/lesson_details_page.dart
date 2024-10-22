import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LessonDetailsPage extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const LessonDetailsPage({Key? key, required this.lesson}) : super(key: key);

  @override
  _LessonDetailsPageState createState() => _LessonDetailsPageState();
}

class _LessonDetailsPageState extends State<LessonDetailsPage> {
  late TextEditingController _dateController;
  late TextEditingController _periodController;
  late TextEditingController _themeController;
  late TextEditingController _cntRatesController;
  late TextEditingController _maxPointController;

  @override
  void initState() {
    super.initState();

    // Форматируем дату для отображения
    DateTime parsedDate = DateTime.parse(widget.lesson['date2']);
    String formattedDate = DateFormat('dd.MM.yyyy').format(parsedDate);

    _dateController = TextEditingController(text: formattedDate);
    _periodController =
        TextEditingController(text: widget.lesson['typePeriod']);
    _themeController = TextEditingController(text: widget.lesson['themeName']);
    _cntRatesController =
        TextEditingController(text: widget.lesson['cntRates'].toString());
    _maxPointController =
        TextEditingController(text: widget.lesson['maxPoint'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '-_@_-',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 10, 84, 255),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поля Класс и Предмет в одном ряду
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.lesson['className'],
                    decoration: const InputDecoration(
                      labelText: 'Класс',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Запрещаем редактирование
                    maxLines: null, // Автоматический перенос текста
                  ),
                ),
                const SizedBox(width: 10), // Отступ между полями
                Expanded(
                  child: TextFormField(
                    initialValue: widget.lesson['subjectName'],
                    decoration: const InputDecoration(
                      labelText: 'Предмет',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Запрещаем редактирование
                    maxLines: null, // Автоматический перенос текста
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child:
                      // Поле Дата (можно редактировать)
                      TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Дата',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () =>
                            _selectDate(context), // Функция выбора даты
                      ),
                    ),
                    keyboardType: TextInputType.datetime,
                    maxLines: null, // Автоматический перенос текста
                  ),
                ),
                const SizedBox(width: 10), // Отступ между полями
                Expanded(
                  child:

                      // Поле Период (можно редактировать)
                      TextFormField(
                    controller: _periodController,
                    decoration: const InputDecoration(
                      labelText: 'Период',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null, // Автоматический перенос текста
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            const SizedBox(height: 10),

            // Поле Тема (можно редактировать)
            TextFormField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'Тема',
                border: OutlineInputBorder(),
              ),
              maxLines: null, // Автоматический перенос текста
            ),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _cntRatesController,
                  decoration: const InputDecoration(
                    labelText: 'Оценки',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLines: null, // Автоматический перенос текста
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    // Поле Максимальный балл (можно редактировать)
                    TextFormField(
                  controller: _maxPointController,
                  decoration: const InputDecoration(
                    labelText: 'Максимальный балл',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLines: null, // Автоматический перенос текста
                ),
              )
            ]),
            // Поле Оценки (можно редактировать)

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Функция для выбора даты с использованием DatePicker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('dd.MM.yyyy').parse(_dateController.text);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != initialDate) {
      setState(() {
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _periodController.dispose();
    _themeController.dispose();
    _cntRatesController.dispose();
    _maxPointController.dispose();
    super.dispose();
  }
}
