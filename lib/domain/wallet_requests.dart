import 'dart:convert';

import 'package:http/http.dart' as http;

String baseUrl = 'https://events.essenciacompany.com/api/app';

Future<Map<String, dynamic>> getWalletData({String? token}) async {
  Map<String, dynamic> res = {'success': false};

  if (token == null) return res;

  Uri url = Uri.parse('$baseUrl/wallet');
  var response = await http.get(url, headers: <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  });
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } catch (error) {
      print(error.toString());
    }
  }
  return res;
}

Future<Map<String, dynamic>> getWalletUser(
    {String? token, String? code}) async {
  Map<String, dynamic> res = {'success': false};
  if (token == null || code == null) return res;

  Uri url = Uri.parse('$baseUrl/wallet/customer');
  var response = await http.post(url, headers: <String, String>{
    // 'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  }, body: {
    'qr': code
  });
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } catch (error) {
      print(error.toString());
    }
  }
  return res;
}

Future<Map<String, dynamic>> makeWalletTransaction(
    {String? token, int? userId, int? amount, String? type}) async {
  Map<String, dynamic> res = {'success': false};
  if (token == null || userId == null || amount == null || type == null) {
    return res;
  }

  Uri url = Uri.parse('$baseUrl/wallet/withdraw');
  var response = await http.post(url, headers: <String, String>{
    // 'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  }, body: {
    'user': '$userId',
    'amount': '$amount',
    'type': type
  });
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data['user']};
    } catch (error) {
      print(error.toString());
    }
  }
  return res;
}
