import 'package:flutter/material.dart';

class DatabaseLoader extends StatelessWidget {
  final String message;

  const DatabaseLoader({
    super.key,
    this.message = "Please wait...",
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.12),
        child: Center(
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 22,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF3155C6),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202124),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}