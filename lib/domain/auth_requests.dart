import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('https://events.essenciacompany.com/api/app/login'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'password': password,
    }),
  );
  try {
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'token': data['token'],
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': data['error'],
      };
    }
  } catch (e) {
    print(e);
    return {
      'success': false,
      'message': 'An error occurred: $e',
    };
  }
}

Future<Map<String, dynamic>> getUser({String? token}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.get(
    Uri.parse('https://events.essenciacompany.com/api/app/user'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );
  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return {'success': true, 'data': data};
  } else {
    return {
      'success': false,
      'message': data['error'],
    };
  }
}

Future<Map<String, dynamic>> getSettings({String? token}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.get(
    Uri.parse('https://events.essenciacompany.com/api/app/settings'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );
  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return {'success': true, 'data': data};
  } else {
    return {
      'success': false,
      'message': data['error'],
    };
  }
}

Future<Map<String, dynamic>> createQrUser(Map<String, String?> data,
    {String? token}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.post(
    Uri.parse('https://events.essenciacompany.com/api/app/qr-user/create'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
    body: jsonEncode(data),
  );
  try {
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': data['error'],
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'An error occurred: $e',
    };
  }
}
