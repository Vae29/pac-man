import 'package:flutter/material.dart';

void showLoseDialog(BuildContext context, VoidCallback onPlayAgain) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          '¡Te atraparon!',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          'Un fantasma atrapó a Pac-Man.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPlayAgain();
            },
            child: const Text(
              'Jugar de nuevo',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      );
    },
  );
}
