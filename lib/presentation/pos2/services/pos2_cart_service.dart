import 'package:essenciacompany_mobile/core/cart_service.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';

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
  bool addExtra(Map<String, dynamic> extra, {String? ticketCode, int? ticketId, int? eventId}) {
    try {
      final extraItem = {
        'id': 'extra_${extra['id']}',
        'name': extra['name'] ?? 'Extra',
        'price': _parsePrice(extra['price']),
        'quantity': 1,
        'type': 'extra',
        'extra_id': extra['id'],
        'event_id': extra['event_id'] ?? eventId,
        'ticket_id': ticketId,
        'metadata': {
          'ticketCode': ticketCode,
          'extra': extra,
        },
      };

      return _cartService.addItem(extraItem);
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

  /// Processar checkout
  Future<Map<String, dynamic>> checkout({
    required String paymentMethod,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
  }) async {
    try {
      if (_cartService.items.isEmpty) {
        return {
          'success': false,
          'message': 'O carrinho está vazio',
        };
      }

      // Preparar dados para checkout
      final checkoutData = {
        'payment_method': paymentMethod,
        'items': _cartService.items.map((item) {
          return {
            'id': item['id'],
            'type': item['item']['type'],
            'quantity': item['quantity'],
            'price': item['price'],
            'metadata': item['item']['metadata'] ?? {},
          };
        }).toList(),
        'total': _cartService.totalPrice,
        'customer': {
          'name': customerName,
          'email': customerEmail,
          'phone': customerPhone,
        },
        'notes': notes,
      };

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
}