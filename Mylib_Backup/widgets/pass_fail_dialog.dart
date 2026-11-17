import 'package:flutter/material.dart';

class PassFailDialog extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onFail;

  const PassFailDialog({super.key, required this.onPass, required this.onFail});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Inspection", textAlign: TextAlign.center),

      content: const Text("Select Result", textAlign: TextAlign.center),

      actionsAlignment: MainAxisAlignment.spaceEvenly,

      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: onPass,
          child: const Text("PASS", style: TextStyle(color: Colors.white)),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: onFail,
          child: const Text("FAIL", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
