import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffMenuDialog extends StatefulWidget {
  const StaffMenuDialog({super.key});

  @override
  State<StaffMenuDialog> createState() => _StaffMenuDialogState();
}

class _StaffMenuDialogState extends State<StaffMenuDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
          child: Text(
        'Menu',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      )),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/wallet');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff28badf),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Wallet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
              )),
          const SizedBox(
            height: 10,
          ),
          GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/physical-qr');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff28badf),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Physical QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
              )),
          const SizedBox(
            height: 10,
          ),
          GestureDetector(
              onTap: () async {
                SharedPreferences _prefs =
                    await SharedPreferences.getInstance();
                await _prefs.remove('token');
                await _prefs.remove('user');
                Navigator.pushNamed(context, '/login');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff28badf),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Logout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
              )),
        ],
      ),
    );
  }
}
