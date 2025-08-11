import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  const TextInput(
      {super.key,
      required this.controller,
      this.hintText,
      this.obscureText = false});

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF36A30)),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        style: GoogleFonts.roboto(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          hintStyle: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
