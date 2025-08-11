import 'package:flutter/material.dart';

class ProcessingView extends StatelessWidget {
  final String message;
  const ProcessingView({Key? key, this.message = 'Em processamento / imprimindo'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 8,
                color: Color(0xff28badf),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              message,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
