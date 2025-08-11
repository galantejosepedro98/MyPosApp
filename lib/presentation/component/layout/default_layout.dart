import 'dart:convert';

import 'package:essenciacompany_mobile/presentation/component/custom_app_bar.dart';
import 'package:essenciacompany_mobile/presentation/component/custom_app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DefaultLayout extends StatefulWidget {
  final Widget child;
  final bool scroll;
  const DefaultLayout({super.key, required this.child, this.scroll = true});

  @override
  State<DefaultLayout> createState() => _DefaultLayoutState();
}

class _DefaultLayoutState extends State<DefaultLayout> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    load();
  }

  load() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final userData = _prefs.getString('user');
    if (userData != null) {
      final user = jsonDecode(userData) as Map<String, dynamic>;
      setState(() {
        _user = user;
      });
    }
  }

  onLogout() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    await _prefs.remove('token');
    await _prefs.remove('user');
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar.showCustomAppBar(context),
        drawer: CustomAppDrawer.showCustomAppDrawer(context,
            user: _user, onLogout: onLogout),
        body: SafeArea(
            child: widget.scroll
                ? SingleChildScrollView(child: widget.child)
                : widget.child));
  }
}
