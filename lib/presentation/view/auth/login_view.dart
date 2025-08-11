import 'dart:convert';

import 'package:essenciacompany_mobile/domain/auth_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/form_widget.dart';
import 'package:essenciacompany_mobile/presentation/component/layout/auth_layout.dart';
import 'package:essenciacompany_mobile/presentation/component/text_input.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  SharedPreferences? prefs;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  _onLogin() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        prefs == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Email and Password is required',
          style: GoogleFonts.roboto(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        backgroundColor: const Color(0xF2760000),
      ));
      return;
    }
    final res = await login(_emailController.text, _passwordController.text);
    if (res['success']) {
      await prefs!.setString('token', res['token']);
      await prefs!.setString('user', jsonEncode(res['user']));
      if (res['user']['role_id'] == 6) {
        Navigator.pushNamed(context, '/pos/shop');
      } else if (res['user']['role_id'] == 8) {
        Navigator.pushNamed(context, '/wallet');
      } else {
        Navigator.pushNamed(context, '/enter-code');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Welcome back ${res['user']['name']} ${res['user']['l_name']}',
          style: GoogleFonts.roboto(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        backgroundColor: const Color(0xF2005316),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          res['message'],
          style: GoogleFonts.roboto(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        backgroundColor: const Color(0xF2760000),
      ));
    }
    setState(() {
      _isSubmitting = false;
    });
  }

  loadData() async {
    var ins = await SharedPreferences.getInstance();
    setState(() {
      prefs = ins;
    });
    final token = prefs!.getString('token');
    final user = prefs!.getString('user');
    if (token != null && token.isNotEmpty) {
      if (user != null && user.isNotEmpty) {
        final userData = jsonDecode(user);
        if (userData['role_id'] == 6) {
          Navigator.pushNamed(context, '/pos/shop');
          return;
        } else if (userData['role_id'] == 8) {
          Navigator.pushNamed(context, '/wallet');
          return;
        }
      }
      Navigator.pushNamed(context, '/enter-code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/logo.png'),
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(
                  height: 50,
                ),
                FormWidget(
                  children: [
                    TextInput(controller: _emailController, hintText: 'Email'),
                    const SizedBox(
                      height: 30,
                    ),
                    TextInput(
                        controller: _passwordController,
                        hintText: 'Password',
                        obscureText: true),
                    const SizedBox(
                      height: 50,
                    ),
                    _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF36A30),
                            ),
                          )
                        : GestureDetector(
                            onTap: _onLogin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF36A30),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'LOGIN',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          )
                  ],
                )
              ],
            )));
  }
}
