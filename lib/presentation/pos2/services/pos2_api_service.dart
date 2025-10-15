import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pos2_event.dart';
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

  /// Buscar histórico de vendas/orders do POS2
  static Future<Map<String, dynamic>> getOrders(String token) async {
    try {
      // Usar o endpoint staff-orders do POS2 (orders criadas pelo POS2)
      final response = await http.get(
        Uri.parse('${baseUrl}pos2/staff-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      POS2DebugHelper.logApi('pos2/staff-orders', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data is List ? data : (data['data'] ?? []),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao buscar histórico',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar histórico de vendas POS2', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Limpar o cache de dados da API
  static Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Encontra todas as chaves que começam com 'pos2_cache_'
      final keys = prefs.getKeys().where((key) => key.startsWith('pos2_cache_')).toList();
      
      // Remove cada chave do cache
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      POS2DebugHelper.log('Cache API limpo: ${keys.length} entradas removidas');
      return true;
    } catch (e) {
      POS2DebugHelper.logError('Erro ao limpar cache', error: e);
      return false;
    }
  }

  /// Buscar bilhetes/produtos de um evento (POS2 API)
  static Future<Map<String, dynamic>> getTickets(int eventId, {bool forceRefresh = false, DateTime? timestamp}) async {
    try {
      // Gerar chave de cache
      final cacheKey = 'pos2_cache_tickets_$eventId';
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar se temos dados em cache (e se não estamos forçando refresh)
      if (!forceRefresh && prefs.containsKey(cacheKey)) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          POS2DebugHelper.log('Bilhetes carregados do cache: ${data['data']?.length ?? 0}');
          return data;
        }
      }
      
      // Se forçar refresh ou não tiver cache, buscar da API
      String url = '${baseUrl}pos2/tickets/$eventId';
      if (timestamp != null) {
        // Adicionar timestamp para evitar cache do servidor
        url += '?t=${timestamp.millisecondsSinceEpoch}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await headers,
      );

      POS2DebugHelper.logApi(url, response.statusCode);
      POS2DebugHelper.log('Resposta bilhetes: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = {
          'success': true,
          'data': data['data'] ?? [],
        };
        
        // Salvar no cache
        await prefs.setString(cacheKey, jsonEncode(result));
        
        POS2DebugHelper.log('Bilhetes retornados: ${result['data']?.length ?? 0}');
        return result;
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
  static Future<Map<String, dynamic>> getExtras(int eventId, {bool forceRefresh = false, DateTime? timestamp}) async {
    try {
      // Gerar chave de cache
      final cacheKey = 'pos2_cache_extras_$eventId';
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar se temos dados em cache (e se não estamos forçando refresh)
      if (!forceRefresh && prefs.containsKey(cacheKey)) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          POS2DebugHelper.log('Extras carregados do cache: ${data['data']?.length ?? 0}');
          return data;
        }
      }
      
      // Se forçar refresh ou não tiver cache, buscar da API
      String url = '${baseUrl}pos2/extras/$eventId';
      if (timestamp != null) {
        // Adicionar timestamp para evitar cache do servidor
        url += '?t=${timestamp.millisecondsSinceEpoch}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await headers,
      );

      POS2DebugHelper.logApi(url, response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = {
          'success': true,
          'data': data['data'] ?? [],
        };
        
        // Salvar no cache
        await prefs.setString(cacheKey, jsonEncode(result));
        
        POS2DebugHelper.log('Extras retornados: ${result['data']?.length ?? 0}');
        return result;
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
          // Adicionar dados do QR Físico
          'hasPhysicalQr': data['hasPhysicalQr'] ?? false,
          'physicalQrTickets': data['physicalQrTickets'] ?? [],
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

  /// Buscar informações de um bilhete pelo código QR (Scanner Universal)
  static Future<Map<String, dynamic>> getTicketByCode(String ticketCode) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}tickets/get'),
        headers: await headers,
        body: jsonEncode({
          'ticket': ticketCode,
        }),
      );

      POS2DebugHelper.logApi('tickets/get', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Se não existir a propriedade extras ou se ela estiver vazia, buscar extras específicos
        if (data['extras'] == null || 
            (data['extras'] is Map && data['extras'].isEmpty) || 
            (data['extras'] is List && data['extras'].isEmpty)) {
          
          // Buscar extras específicos do bilhete usando a API padrão do sistema
          final extrasResponse = await getTicketExtras(ticketCode);
          
          if (extrasResponse['success'] && extrasResponse['extras'] != null) {
            // Adicionar extras ao response
            data['extras'] = extrasResponse['extras'];
          }
        }
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Bilhete não encontrado',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar bilhete por código', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
  
  /// Buscar extras específicos de um bilhete (usa a mesma API que o staff-withdraw)
  static Future<Map<String, dynamic>> getTicketExtras(String ticketCode) async {
    try {
      POS2DebugHelper.log('Buscando extras específicos do bilhete: $ticketCode');
      
      final response = await http.post(
        Uri.parse('${baseUrl}extras'),
        headers: await headers,
        body: jsonEncode({
          'ticket': ticketCode,
        }),
      );

      POS2DebugHelper.logApi('extras', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Formatar os extras para o formato esperado
        final extras = data['extras'] ?? [];
        
        return {
          'success': true,
          'ticket': data['ticket'],
          'extras': extras,
          'message': data['message'] ?? 'Extras encontrados',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao buscar extras do bilhete',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar extras do bilhete', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
  
  /// Levantar um extra associado a um bilhete
  static Future<Map<String, dynamic>> withdrawExtra(String ticketCode, int extraId, {int quantity = 1}) async {
    try {
      // Primeiro, tentar com o endpoint específico do POS2
      POS2DebugHelper.log('Tentando levantar extra via API /api/pos2/withdraw-extra');
      
      final response = await http.post(
        Uri.parse('${baseUrl}pos2/withdraw-extra'),
        headers: await headers,
        body: jsonEncode({
          'ticket': ticketCode,
          'extra_id': extraId,
          'quantity': quantity,
        }),
      );

      POS2DebugHelper.logApi('pos2/withdraw-extra', response.statusCode, body: response.body);
      
      // Se for bem-sucedido, retornar os dados
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? {},
            'message': 'Extra levantado com sucesso!',
          };
        } else {
          // Se falhar, tentar com o endpoint padrão
          return await _withdrawExtraLegacy(ticketCode, extraId, quantity: quantity);
        }
      } else {
        // Se falhar, tentar com o endpoint padrão
        return await _withdrawExtraLegacy(ticketCode, extraId, quantity: quantity);
      }
    } catch (e) {
      // Em caso de erro, tentar com o endpoint padrão
      POS2DebugHelper.logError('Erro ao levantar extra via POS2 API', error: e);
      return await _withdrawExtraLegacy(ticketCode, extraId, quantity: quantity);
    }
  }
  
  /// Método legado para levantar extras usando a API padrão do sistema
  static Future<Map<String, dynamic>> _withdrawExtraLegacy(String ticketCode, int extraId, {int quantity = 1}) async {
    try {
      POS2DebugHelper.log('Tentando levantar extra via API padrão /api/app/withdraw');
      
      // Formatar no formato que a API padrão espera
      Map<String, dynamic> withdraw = {
        '$extraId': quantity
      };
      
      final response = await http.post(
        Uri.parse('${baseUrl}withdraw'),
        headers: await headers,
        body: jsonEncode({
          'ticket': ticketCode,
          'withdraw': withdraw,
        }),
      );

      POS2DebugHelper.logApi('withdraw (legacy)', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': data['message'] ?? 'Extra levantado com sucesso!',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao levantar extra',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao levantar extra via API legada', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
  
  /// Obter dados de impressão para um pedido específico (Vendus)
  /// Esta função usa a rota correta /api/pos2/vendus/print/{orderId}
  static Future<Map<String, dynamic>> getReceiptPrintData(int orderId) async {
    try {
      POS2DebugHelper.log('Obtendo dados de impressão para pedido #$orderId');
      
      // Usar a URL correta para impressão (baseada no orderId)
      // A URL correta para o servidor é com /api/app/ no caminho
      final url = 'https://events.essenciacompany.com/api/app/pos2/vendus/print/$orderId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await headers,
      );

      POS2DebugHelper.logApi('vendus/print/$orderId', response.statusCode, 
          body: response.body.length > 1000 
              ? '${response.body.substring(0, 500)}... [truncado]' 
              : response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        POS2DebugHelper.log('Estrutura completa da resposta: ${jsonEncode(data)}');
        
        if (data['success'] == true && data['data'] != null) {
          // SIMPLIFICADO! Usar dados limpos diretamente
          final innerData = data['data'];
          
          if (innerData['dados_para_fatura'] != null) {
            final dadosParaFatura = innerData['dados_para_fatura'];
            
            POS2DebugHelper.log('Dados limpos recebidos - usando diretamente!');
            
            return {
              'success': true,
              'dados_limpos': dadosParaFatura, // Dados limpos diretos!
              'invoice_number': dadosParaFatura['invoice_number'],
              'invoice_date': dadosParaFatura['invoice_time'],
              'print_format': 'dados_limpos', // Novo formato simplificado
            };
          }
        }
        
        return {
          'success': false,
          'message': data['message'] ?? 'Dados de impressão não encontrados',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao obter dados de impressão',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao obter dados de impressão', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Sinalizar problema em uma ordem
  static Future<Map<String, dynamic>> markOrder(String token, int orderId, String note) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}pos2/mark-order/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'note': note}),
      );

      POS2DebugHelper.logApi('pos2/mark-order/$orderId', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Problema sinalizado com sucesso',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao sinalizar problema',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao sinalizar problema', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Reenviar email da ordem
  static Future<Map<String, dynamic>> resendEmail(String token, int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}pos2/send-email/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      POS2DebugHelper.logApi('pos2/send-email/$orderId', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Email reenviado com sucesso',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao reenviar email',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao reenviar email', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Reenviar SMS da ordem
  static Future<Map<String, dynamic>> resendSMS(String token, int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}pos2/send-sms/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      POS2DebugHelper.logApi('pos2/send-sms/$orderId', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'SMS reenviado com sucesso',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao reenviar SMS',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao reenviar SMS', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Atualizar dados de contato da ordem
  static Future<Map<String, dynamic>> updateContact(
    String token, 
    int orderId, 
    {String? email, String? phone}
  ) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;

      final response = await http.put(
        Uri.parse('${baseUrl}pos2/update-contact/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      POS2DebugHelper.logApi('pos2/update-contact/$orderId', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Contactos atualizados com sucesso',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao atualizar contactos',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao atualizar contactos', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}
