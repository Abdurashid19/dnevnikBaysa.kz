import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String text;
  final VoidCallback onClose;

  const SuccessDialog({Key? key, required this.text, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Выровняем по центру вертикально
          children: [
            const Icon(
              Icons.task_alt,
              color: Color.fromARGB(221, 12, 184, 0),
              size: 36.0,
            ),
            const SizedBox(width: 15),
            Expanded(
              // Если нужно, чтобы текст занимал оставшееся пространство
              child: Text(
                text,
                maxLines: null,
                softWrap: true,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: const Color.fromARGB(221, 255, 255, 255),
            backgroundColor: const Color.fromRGBO(19, 153, 124, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: onClose,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
