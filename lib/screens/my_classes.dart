import 'package:baysa_app/models/cst_class.dart';
import 'package:baysa_app/screens/dopScreens/add_special_class_page.dart';
import 'package:baysa_app/screens/dopScreens/edit_class.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baysa_app/services/user_service.dart';

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({Key? key}) : super(key: key);

  @override
  _MyClassesPageState createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _classesData = [];

  @override
  void initState() {
    super.initState();
    _fetchClassesData();
  }

  Future<void> _fetchClassesData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getInt('userId');
    final schoolYear = prefs.getInt('schoolYear') ?? 2024;

    if (teacherId != null) {
      final classesResponse = await _userService.getListClass17(
        teacherId: teacherId,
        schoolYear: schoolYear,
        context: context,
      );
      setState(() {
        _classesData = classesResponse;
        _isLoading = false;
      });
    }
  }

  _navigateToEditClass(
      BuildContext context, Map<String, dynamic> classItem) async {
    // Navigate to the edit class page with classItem data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClassPage(classItem: classItem),
      ),
    );

    if (result == 'success') {
      _fetchClassesData();
    }
  }

  Widget _buildClassesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_classesData.isEmpty) {
      return const Center(child: Text('Нет данных для отображения.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _classesData.length,
          itemBuilder: (context, index) {
            final classItem = _classesData[index];
            return GestureDetector(
              onTap: () {
                _navigateToEditClass(context, classItem);
              },
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${classItem['className']} ${classItem['subjectName']} ${classItem['typeClass'] == 1 ? 'Спец.класс' : ''}',
                    ),
                    const SizedBox(height: 10),
                    Text('${classItem['dayNum']}'),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cst.backgroundApp,
      appBar: AppBar(
        title: const Text('Мои классы'),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: Cst.backgroundAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Navigate to add special class page and wait for result
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddSpecialClassPage(userService: _userService),
                ),
              );

              // Check if the result is 'success' and call _fetchClassesData
              if (result == 'success') {
                _fetchClassesData();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: CustomCard(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildClassesList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
