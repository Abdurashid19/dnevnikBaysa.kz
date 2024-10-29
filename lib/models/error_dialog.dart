import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String text;
  final VoidCallback onClose;

  const ErrorDialog({Key? key, required this.text, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Icon(
        Icons.error_outline,
        size: 50,
        color: Colors.redAccent,
      ),
      content: Text(
        text,
        textAlign: TextAlign.center, // Центрируем текст
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
