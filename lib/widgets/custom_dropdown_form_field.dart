import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropdownFormField extends StatelessWidget {
  final Map<String, dynamic>? selectedValue;
  final List<Map<String, dynamic>> values;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final String hintText;
  final String labelText;

  CustomDropdownFormField({
    required this.selectedValue,
    required this.values,
    required this.onChanged,
    required this.hintText,
    required this.labelText,
  });

  InputDecoration inputDecoration(
    BuildContext context,
    String hintText,
    String labelText,
  ) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 214, 212, 211)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      hintText: hintText,
      labelText: labelText,
      hintMaxLines: 2,
      alignLabelWithHint: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField2<Map<String, dynamic>?>(
      value: selectedValue,
      items: values.map<DropdownMenuItem<Map<String, dynamic>?>>((item) {
        return DropdownMenuItem<Map<String, dynamic>?>(
          value: item,
          child: Text(
            item['name'],
            softWrap: true,
            maxLines: null, // Разрешаем до 2 строк для отображения
            overflow: TextOverflow.visible,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: inputDecoration(context, hintText, labelText),
      isExpanded: true,
    );
  }
}
