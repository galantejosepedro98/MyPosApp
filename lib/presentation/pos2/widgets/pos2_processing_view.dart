import 'package:flutter/material.dart';

/// Widget para mostrar tela de processamento durante operações
class POS2ProcessingView extends StatelessWidget {
  final String message;
  
  const POS2ProcessingView({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51), // 0.2 * 255 = ~51
                blurRadius: 10,
                spreadRadius: 5,
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}