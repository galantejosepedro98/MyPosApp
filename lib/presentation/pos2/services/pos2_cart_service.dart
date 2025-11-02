import 'dart:convert';
import 'package:essenciacompany_mobile/core/cart_service.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';

/// Extensão para capitalizar a primeira letra de uma string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/// Serviço de carrinho específico para o POS2
/// Utiliza o CartService existente como base
class POS2CartService {
  static final POS2CartService _instance = POS2CartService._internal();
  static POS2CartService get instance => _instance;
  factory POS2CartService() => _instance;
  POS2CartService._internal();

  // Instância do serviço de carrinho base
  final CartService _cartService = CartService();

  /// Adicionar bilhete ao carrinho
  bool addTicket(Map<String, dynamic> ticket) {
    try {
      final ticketItem = {
        'id': 'ticket_${ticket['id']}',
        'name': ticket['name'] ?? ticket['product_name'] ?? 'Bilhete',
        'price': _parsePrice(ticket['price']),
        'quantity': 1,
        'type': 'ticket',
        'ticket_id': ticket['id'],
        'event_id': ticket['event_id'],
        'product_type': ticket['product_type'] ?? 'ticket',
        'metadata': {
          'ticket': ticket,
        },
      };

      return _cartService.addItem(ticketItem);
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao adicionar bilhete', error: e);
      return false;
    }
  }

  /// Adicionar convite pago ao carrinho (para ativação)
  bool addPaidInviteActivation(Map<String, dynamic> ticket) {
    try {
      final activationItem = {
        'id': 'activation_${ticket['id']}',
        'name': 'Ativação: ${ticket['name'] ?? 'Convite Pago'}',
        'price': _parsePrice(ticket['price']),
        'quantity': 1,
        'type': 'paid_invite_activation',
        'ticket_id': ticket['id'],
        'metadata': {
          'ticket': ticket,
        },
      };

      return _cartService.addItem(activationItem);
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao adicionar ativação de convite', error: e);
      return false;
    }
  }

  /// Adicionar extra ao carrinho
  bool addExtra(Map<String, dynamic> extra, {String? ticketCode, int? ticketId, int? eventId, int quantity = 1}) {
    try {
      // IMPORTANTE: Usar ID composto para distinguir extras standalone de extras de bilhetes
      // - Extra standalone: 'extra_6'
      // - Extra de bilhete: 'extra_6_ticket_55647'
      // Isso permite que o CartService trate como items separados
      final String itemId = ticketId != null 
          ? 'extra_${extra['id']}_ticket_$ticketId'
          : 'extra_${extra['id']}';
      
      final extraItem = {
        'id': itemId,
        'name': extra['name'] ?? 'Extra',
        'price': _parsePrice(extra['price']),
        'quantity': quantity, // Usar quantity passado como parâmetro
        'type': 'extra',
        'extra_id': extra['id'],
        'event_id': extra['event_id'] ?? eventId,
        'ticket_id': ticketId,
        'metadata': {
          'ticketCode': ticketCode,
          'extra': extra,
        },
      };

      return _cartService.addItem(extraItem, quantityToAdd: quantity);
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao adicionar extra', error: e);
      return false;
    }
  }

  /// Atualizar quantidade de um item
  bool updateQuantity(String id, int change) {
    try {
      final item = _cartService.getItem(id);
      if (item.isEmpty) {
        return false;
      }
      return _cartService.updateQuantity(item, change);
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao atualizar quantidade', error: e);
      return false;
    }
  }

  /// Remover item do carrinho
  bool removeItem(String id) {
    try {
      final item = _cartService.getItem(id);
      if (item.isEmpty) {
        return false;
      }
      // Remover o item definindo quantidade para 0
      return _cartService.updateQuantity(item, -item['quantity']);
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao remover item', error: e);
      return false;
    }
  }

  /// Decrementar a quantidade de um item em 1 unidade
  bool decrementItem(String id) {
    try {
      final item = _cartService.getItem(id);
      if (item.isEmpty) {
        return false;
      }
      // Decrementar apenas 1 unidade
      return _cartService.updateQuantity(item, -1);
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao decrementar item', error: e);
      return false;
    }
  }

  /// Limpar o carrinho
  void clear() {
    _cartService.resetCart();
  }

  /// Obter todos os itens do carrinho
  List<Map<String, dynamic>> get items => _cartService.items;

  /// Obter o número total de itens no carrinho
  int get totalItems => _cartService.totalItems;

  /// Obter o preço total do carrinho
  double get totalPrice => _cartService.totalPrice;

  /// Verificar se o carrinho tem produtos (bilhetes/tickets)
  /// Retorna true se há bilhetes, false se há apenas extras
  bool get hasProducts {
    final result = _cartService.items.any((item) {
      // O CartService guarda o item dentro de item['item']
      final innerItem = item['item'] as Map<String, dynamic>?;
      final type = innerItem?['type'];
      return type == 'ticket' || type == 'paid_invite_activation';
    });
    POS2DebugHelper.log('hasProducts check: $result');
    if (_cartService.items.isNotEmpty) {
      POS2DebugHelper.log('Itens no carrinho: ${_cartService.items.map((e) {
        final inner = e['item'] as Map<String, dynamic>?;
        return '${e['id']}: ${inner?['type']}';
      }).join(', ')}');
    }
    return result;
  }

  /// Verificar se o carrinho tem apenas extras (sem produtos)
  bool get hasOnlyExtras {
    final hasProds = hasProducts;
    final hasExtras = _cartService.items.any((item) {
      // O CartService guarda o item dentro de item['item']
      final innerItem = item['item'] as Map<String, dynamic>?;
      return innerItem?['type'] == 'extra';
    });
    final result = !hasProds && hasExtras;
    POS2DebugHelper.log('hasOnlyExtras - hasProducts: $hasProds, hasExtras: $hasExtras, result: $result');
    return result;
  }

  /// Processar checkout
  Future<Map<String, dynamic>> checkout({
    required String paymentMethod,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerVatNumber,
    String? notes,
    bool sendSms = false,
    bool sendEmail = false,
    bool printInvoice = false,
    bool physicalQr = false,
    bool withdraw = false,
    bool sendInvoiceEmail = false,
  }) async {
    try {
      if (_cartService.items.isEmpty) {
        return {
          'success': false,
          'message': 'O carrinho está vazio',
        };
      }

      // Preparar dados para checkout exatamente como na versão web
      final checkoutData = {
        'items': _cartService.items.map((item) {
          // Transformar item para o formato esperado pela API (exatamente como na versão web)
          final itemData = item['item'];
          final Map<String, dynamic> mappedItem = {
            'id': item['id'],
            'name': itemData['name'] ?? 'Produto',
            'type': itemData['type'],
            'quantity': item['quantity'],
            'price': item['price'],
            // Incluir produto completo como na versão web
            'product': {
              'id': itemData['type'] == 'ticket' ? itemData['ticket_id'] : itemData['extra_id'],
              'name': itemData['name'] ?? 'Produto',
              'price': item['price'],
              'type': itemData['type'],
            },
            // Metadados importantes para rastreabilidade
            'metadata': {
              ...(itemData['metadata'] ?? {}),
              'eventId': itemData['event_id'], // Importante para o backend vincular o pedido ao evento
            },
          };

          // Adicionar ticket_id se presente (importante para extras)
          if (itemData['ticket_id'] != null) {
            mappedItem['ticket_id'] = itemData['ticket_id'];
          }

          // Verificar e adicionar extras se existirem
          if (itemData['extras'] != null && itemData['extras'] is List && (itemData['extras'] as List).isNotEmpty) {
            mappedItem['extras'] = itemData['extras'];
          }

          return mappedItem;
        }).toList(),
        'totals': {
          'subtotal': _cartService.totalPrice,
          'total': _cartService.totalPrice,
          'final_total': _cartService.totalPrice,
          'itemsSubtotal': _cartService.totalPrice,
          'extrasTotal': 0.0, // Caso não tenha extras separados
          'discounts': 0.0, // Sem descontos no POS2
        },
        'billing': {
          'name': customerName ?? '',
          'email': customerEmail ?? '',
          'phone': customerPhone ?? '', // Enviar o número como está (o indicativo será adicionado pelo backend)
          'vatNumber': customerVatNumber ?? '',
          'address': '',
        },
        'payment': {
          'method': paymentMethod.capitalize(),
        },
        'options': {
          'sendToMail': sendEmail,
          'sendToPhone': sendSms,
          'withdraw': withdraw,
          'physicalQr': physicalQr,
          'printInvoice': printInvoice,
          'sendInvoiceToMail': sendInvoiceEmail,
        },
      };

      POS2DebugHelper.log('POS2: Checkout data: ${jsonEncode(checkoutData)}');
      
      // Chamar a API de checkout
      final result = await POS2ApiService.checkout(checkoutData);
      
      // Se o checkout for bem-sucedido, limpar o carrinho
      if (result['success']) {
        _cartService.resetCart();
      }
      
      return result;
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha no checkout', error: e);
      return {
        'success': false,
        'message': 'Erro ao processar o checkout: $e',
      };
    }
  }

  // Utilitário para converter preços para double
  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
  
  /// Limpar o carrinho completamente
  void clearCart() {
    try {
      // Limpar itens
      _cartService.items.clear();
      
      // Resetar totais
      _cartService.totalItems = 0;
      _cartService.totalPrice = 0.0;
      
      // Atualizar carrinho
      _cartService.updateCart();
      
      POS2DebugHelper.log('POS2CartService: Carrinho limpo com sucesso');
    } catch (e) {
      POS2DebugHelper.logError('POS2CartService ERROR: Falha ao limpar carrinho', error: e);
    }
  }
}