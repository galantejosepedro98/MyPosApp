import 'package:flutter/material.dart';

class FormWidget extends StatelessWidget {
  final List<Widget> children;
  const FormWidget({super.key, this.children = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 36, right: 40, left: 40, bottom: 54),
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
      child: Column(children: children),
    );
  }
}
