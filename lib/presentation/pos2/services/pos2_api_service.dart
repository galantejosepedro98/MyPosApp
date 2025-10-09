import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pos2_event.dart';
import '../models/pos2_product.dart';
import 'pos2_debug_helper.dart';

class POS2ApiService {
  // Base URL para as APIs do POS2 (mesmo servidor que o sistema atual)
  static const String baseUrl = 'https://events.essenciacompany.com/api/app/';
  
  // Headers padrão para todas as requisições
  static Future<Map<String, String>> get headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// Buscar eventos disponíveis
  static Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}events'), // Mesmo endpoint do sistema atual
        headers: await headers,
      );

      POS2DebugHelper.logApi('events', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = (data['data'] as List)
            .map((eventJson) => POS2Event.fromJson(eventJson))
            .toList();
        
        return {
          'success': true,
          'data': events,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao buscar eventos',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar eventos', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Buscar bilhetes/produtos de um evento (POS2 API)
  static Future<Map<String, dynamic>> getTickets(int eventId) async {
    try {
      // Usar a API da app que funciona com Sanctum auth
      final response = await http.get(
        Uri.parse('${baseUrl}pos2/tickets/$eventId'),
        headers: await headers,
      );

      POS2DebugHelper.logApi('pos2/tickets/$eventId', response.statusCode);
      POS2DebugHelper.log('Resposta bilhetes: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        POS2DebugHelper.log('Bilhetes retornados: ${data['data']?.length ?? 0}');
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao buscar bilhetes',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar bilhetes', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Buscar extras de um evento (POS2 API)
  static Future<Map<String, dynamic>> getExtras(int eventId) async {
    try {
      // Usar a API da app que funciona com Sanctum auth
      final response = await http.get(
        Uri.parse('${baseUrl}pos2/extras/$eventId'),
        headers: await headers,
      );

      POS2DebugHelper.logApi('pos2/extras/$eventId', response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        POS2DebugHelper.log('Extras retornados: ${data['data']?.length ?? 0}');
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao buscar extras',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar extras', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Fazer checkout (finalizar compra)
  static Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}pos2/checkout'),
        headers: await headers,
        body: jsonEncode(checkoutData),
      );

      POS2DebugHelper.logApi('checkout', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'order': data['order'],
          'tickets': data['tickets'],
          'invoice_url': data['invoice_url'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro no checkout',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro no checkout', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Buscar informações de um bilhete via QR code
  static Future<Map<String, dynamic>> getTicketByQR(String qrCode) async {
    try {
      // Usar a API existente do sistema atual para compatibilidade
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final response = await http.post(
        Uri.parse('https://events.essenciacompany.com/api/tickets/get'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'ticket': qrCode}),
      );

      POS2DebugHelper.logApi('ticket-qr', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Bilhete não encontrado',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar ticket por QR', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Buscar produtos/extras de um evento (mesma API do sistema atual)
  static Future<Map<String, dynamic>> getProducts(int eventId, {String? categoryId, String? query}) async {
    try {
      // Usar exatamente a mesma URL que o sistema atual - sem filtros para pegar tudo
      String url = '${baseUrl}extras/all?&event_id=$eventId&per_page=100';
      
      POS2DebugHelper.log('URL de requisição: $url');
      
      if (categoryId != null && categoryId.isNotEmpty) {
        url += '&category_id=$categoryId';
      }
      
      if (query != null && query.isNotEmpty) {
        url += '&query=$query';
      }
      
      final uri = Uri.parse(url);
      
      final response = await http.get(
        uri,
        headers: await headers,
      );

      POS2DebugHelper.logApi('extras/all', response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        POS2DebugHelper.log('Total de itens retornados: ${data['data']?.length ?? 0}');
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao buscar produtos',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar produtos', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Buscar métodos de pagamento disponíveis
  static Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}payment-methods'),
        headers: await headers,
      );

      POS2DebugHelper.logApi('payment-methods', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        // Fallback para métodos padrão se a API falhar
        return {
          'success': true,
          'data': [
            {'value': 'Cash', 'label': 'Dinheiro'},
            {'value': 'Card', 'label': 'Cartão'},
            {'value': 'Transfer', 'label': 'Transferência'},
            {'value': 'Other', 'label': 'Outro'},
          ],
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar métodos de pagamento', error: e);
      // Fallback para métodos padrão
      return {
        'success': true,
        'data': [
          {'value': 'Cash', 'label': 'Dinheiro'},
          {'value': 'Card', 'label': 'Cartão'},
          {'value': 'Transfer', 'label': 'Transferência'},
          {'value': 'Other', 'label': 'Outro'},
        ],
      };
    }
  }
}