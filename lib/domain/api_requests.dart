import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> checkinRequest(
    String? token, String? ticket, String? zone) async {
  if (token == null ||
      token.isEmpty ||
      ticket == null ||
      ticket.isEmpty ||
      zone == null ||
      zone.isEmpty) {
    return {
      'success': false,
      'message': 'Invalid',
    };
  }
  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/checkin'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'ticket': ticket,
        'zone_id': zone,
      }));

  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return {
      'success': true,
      'data': data['data'],
    };
  } else {
    return {
      'success': false,
      'message': data['error'] ?? data['message'],
    };
  }
}

Future<Map<String, dynamic>> checkoutRequest(
    String? token, String? ticket, String? zone) async {
  if (token == null ||
      token.isEmpty ||
      ticket == null ||
      ticket.isEmpty ||
      zone == null ||
      zone.isEmpty) {
    return {
      'success': false,
      'message': 'Invalid',
    };
  }
  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/checkout'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'ticket': ticket,
        'zone_id': zone,
      }));

  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return {'success': true, 'data': data['data'], 'message': data['message']};
  } else {
    return {
      'success': false,
      'message': data['error'] ?? data['message'],
    };
  }
}

Future<Map<String, dynamic>> getExtrasRequest(
    String? token, String? ticket) async {
  if (token == null || token.isEmpty || ticket == null || ticket.isEmpty) {
    return {
      'success': false,
      'message': 'Invalid',
    };
  }
  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/extras'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'ticket': ticket,
      }));
  try {
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final extras = (data['extras'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return {
        'success': true,
        'ticket': data['ticket'],
        'message': data['message'] ?? 'SCAN SUCCESSFULL',
        'extras': extras,
      };
    } else {
      return {
        'success': false,
        'message': data['error'] ?? data['message'],
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'An error occurred: $e',
    };
  }
}

Future<Map<String, dynamic>> withdrawExtraRequest(
    String? token, String? ticket, Map<String, dynamic>? withdraw) async {
  if (token == null ||
      token.isEmpty ||
      ticket == null ||
      ticket.isEmpty ||
      withdraw == null) {
    return {
      'success': false,
      'message': 'Invalid',
    };
  }
  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/withdraw'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(
          <String, dynamic>{'ticket': ticket, 'withdraw': withdraw}));
  try {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'],
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? data['message'],
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'An error occurred: $e',
    };
  }
}

Future<Map<String, dynamic>> getZoneType(String? token, String? zone) async {
  Map<String, dynamic> res = {"success": false, "message": "Invalid"};

  if (token == null || token.isEmpty || zone == null || zone.isEmpty) {
    return res;
  }

  final response = await http.post(
      Uri.parse('https://events.essenciacompany.com/api/app/zone-type'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'zone': zone,
      }));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'success': true,
      'type': data['food_zone'] == true ? 'food' : 'checkin-checkout',
      'message': data['message'] ?? data['food_zone'] == true
          ? 'Food & Products zone'
          : 'Check in & Check out zone',
      'data': data['zone']
    };
  } else if (response.statusCode == 401) {
    final data = jsonDecode(response.body);
    return {'success': false, 'message': data['error']};
  }

  return res;
}
