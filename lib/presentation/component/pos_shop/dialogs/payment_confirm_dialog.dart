import 'package:flutter/material.dart';

class PaymentConfirmDialog extends StatelessWidget {
  const PaymentConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.credit_card_rounded,
            size: 300,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          const Text(
            'Confirme Success',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            color: Colors.green,
            child: const Text(
              'Success',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/pos/shop');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                color: const Color(0xff28badf),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              )),
        ],
      ),
    );
  }
}
