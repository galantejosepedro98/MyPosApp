import 'package:flutter/material.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  const AuthLayout({super.key, required this.child});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: SingleChildScrollView(child: widget.child)));
  }
}
