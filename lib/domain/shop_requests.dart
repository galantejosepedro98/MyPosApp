import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getEvents({String? token}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.get(
    Uri.parse('https://events.essenciacompany.com/api/app/events'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data['data']};
    } catch (error) {
      print(error.toString());
    }
  }
  return {'success': false, 'message': 'Unexpected error'};
}

Future<Map<String, dynamic>> getExtrasCategories(
    {String? token, String? eventId}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.get(
    Uri.parse(
        'https://events.essenciacompany.com/api/app/extras/categories?event=${eventId ?? ''}'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data['data']};
    } catch (error) {
      print(error.toString());
    }
  }
  return {'success': false, 'message': 'Unexpected error'};
}

Future<Map<String, dynamic>> getProducts(
    {String? token, String? eventId, String? categoryId, String? query}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.get(
    Uri.parse(
        'https://events.essenciacompany.com/api/app/extras/all?${eventId != null && eventId.isNotEmpty ? '&event_id=$eventId' : ''}'
        '${categoryId != null && categoryId.isNotEmpty ? '&category_id=$categoryId' : ''}'
        '${query != null && query.isNotEmpty ? '&query=$query' : ''}'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data['data']};
    } catch (error) {
      print(error.toString());
    }
  }
  return {'success': false, 'message': 'Unexpected error'};
}

Future<Map<String, dynamic>> getOrders({String? token}) async {
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.get(
    Uri.parse('https://events.essenciacompany.com/api/app/orders'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } catch (error) {
      print(error.toString());
    }
  }
  return {'success': false, 'message': 'Unexpected error'};
}

Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData,
    {String? token}) async {
  Map<String, dynamic> res = {'success': false};
  if (token == null) return {'success': false, 'message': 'Login again'};
  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/order/create'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(orderData));
  try {
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      res = {'success': true, 'data': data['order']};
    } else {
      res['message'] = data['message'];
    }
  } catch (error) {
    res = {'success': false, 'message': 'Unexpected error'};
  }
  return res;
}

Future<Map<String, dynamic>> getUserFromQr({String? qrCode}) async {
  Map<String, dynamic> res = {'success': false};
  if (qrCode == null) return res;
  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/user-from-qr'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': qrCode}));
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      res = {'success': true, 'data': data['user']};
    } catch (error) {
      print(error.toString());
    }
  } else {
    try {
      final data = jsonDecode(response.body);
      res['message'] = data['error'] ?? data['message'];
    } catch (error) {
      print(error.toString());
    }
  }
  return res;
}
