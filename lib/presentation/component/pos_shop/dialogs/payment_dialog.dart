import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/payment_confirm_dialog.dart';
import 'package:flutter/material.dart';

class PaymentDialog extends StatelessWidget {
  const PaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const PaymentConfirmDialog();
                },
              );
            },
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap to pay \nwith the QR Code',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
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
