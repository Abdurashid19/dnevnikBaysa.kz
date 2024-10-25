import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String text;
  final VoidCallback onClose;

  const ErrorDialog({Key? key, required this.text, required this.onClose})
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
              Icons.error_outline,
              color: Colors.redAccent,
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

        // child: Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     const Icon(
        //       Icons.error_outline,
        //       color: Colors.redAccent,
        //       size: 36.0,
        //     ),
        //     const SizedBox(height: 15),
        //     Text(
        //       text,
        //       maxLines: null,
        //       softWrap: true,
        //       style: const TextStyle(fontSize: 16),
        //     ),
        //   ],
        // ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: const Color.fromARGB(221, 255, 255, 255),
            backgroundColor: Colors.redAccent,
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
