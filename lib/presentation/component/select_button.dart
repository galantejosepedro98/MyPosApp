import 'package:flutter/material.dart';

class SelectButton extends StatelessWidget {
  final String icon;
  final Function onTap;
  const SelectButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => onTap(),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.width * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black),
            boxShadow: const [
              BoxShadow(
                color: Color(0x8FF36A30),
                spreadRadius: 2,
                blurRadius: 3,
                offset: Offset(8, 8),
              )
            ],
          ),
          child: Center(
            child: Image.asset(
              icon,
              width: 100,
              height: 100,
            ),
          ),
        ));
  }
}
