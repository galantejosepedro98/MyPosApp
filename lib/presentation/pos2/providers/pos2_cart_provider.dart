import 'package:flutter/foundation.dart';
import '../models/pos2_cart.dart';
import '../services/pos2_debug_helper.dart';
import '../models/pos2_product.dart';

class POS2CartProvider extends ChangeNotifier {
  final List<POS2CartItem> _items = [];
  POS2CartTotals _totals = POS2CartTotals(subtotal: 0, discounts: 0, total: 0);
  Map<String, dynamic> _customerInfo = {
    'name': '',
    'email': '',
    'phone': '',
    'vatNumber': '',
  };

  // Getters
  List<POS2CartItem> get items => _items;
  POS2CartTotals get totals => _totals;
  Map<String, dynamic> get customerInfo => _customerInfo;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Adicionar item ao carrinho
  void addItem({
    required POS2CartItemType type,
    required dynamic product,
    int quantity = 1,
    String? qrCode,
    String? ticketId,
    String? name,
    double? price,
    double? specialPrice,
    Map<String, dynamic>? customerInfo,
    Map<String, dynamic>? metadata,
  }) {
    final itemId = 'cart_item_${DateTime.now().millisecondsSinceEpoch}_${_items.length}';
    final basePrice = price ?? (product is POS2Product ? product.price : product is POS2Extra ? product.price : 0.0);
    
    final newItem = POS2CartItem(
      id: itemId,
      type: type,
      qrCode: qrCode,
      product: product,
      basePrice: basePrice,
      specialPrice: specialPrice,
      quantity: quantity,
      extras: [],
      customerInfo: customerInfo,
      metadata: metadata ?? {},
      ticketId: ticketId,
      name: name,
      price: price,
    );

    _items.add(newItem);
    _calculateTotals();
    notifyListeners();

    POS2DebugHelper.logCart('Item adicionado - ${newItem.displayName} x$quantity');
  }

  /// Remover item do carrinho
  void removeItem(String itemId) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      final removedItem = _items.removeAt(itemIndex);
      _calculateTotals();
      notifyListeners();
      
      POS2DebugHelper.logCart('Item removido - ${removedItem.displayName}');
    }
  }

  /// Atualizar quantidade de um item
  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      final oldItem = _items[itemIndex];
      final updatedItem = POS2CartItem(
        id: oldItem.id,
        type: oldItem.type,
        qrCode: oldItem.qrCode,
        product: oldItem.product,
        basePrice: oldItem.basePrice,
        specialPrice: oldItem.specialPrice,
        quantity: newQuantity,
        extras: oldItem.extras,
        customerInfo: oldItem.customerInfo,
        metadata: oldItem.metadata,
        ticketId: oldItem.ticketId,
        name: oldItem.name,
        price: oldItem.price,
      );
      
      _items[itemIndex] = updatedItem;
      _calculateTotals();
      notifyListeners();
      
      POS2DebugHelper.logCart('Quantidade atualizada - ${updatedItem.displayName} -> $newQuantity');
    }
  }

  /// Adicionar extra a um item
  void addExtraToItem(String itemId, POS2CartExtra extra) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      final oldItem = _items[itemIndex];
      final newExtras = List<POS2CartExtra>.from(oldItem.extras);
      
      // Verificar se o extra já existe
      final existingExtraIndex = newExtras.indexWhere((e) => e.id == extra.id);
      if (existingExtraIndex >= 0) {
        // Atualizar quantidade do extra existente
        final oldExtra = newExtras[existingExtraIndex];
        newExtras[existingExtraIndex] = POS2CartExtra(
          id: oldExtra.id,
          name: oldExtra.name,
          price: oldExtra.price,
          quantity: oldExtra.quantity + extra.quantity,
        );
      } else {
        // Adicionar novo extra
        newExtras.add(extra);
      }
      
      final updatedItem = POS2CartItem(
        id: oldItem.id,
        type: oldItem.type,
        qrCode: oldItem.qrCode,
        product: oldItem.product,
        basePrice: oldItem.basePrice,
        specialPrice: oldItem.specialPrice,
        quantity: oldItem.quantity,
        extras: newExtras,
        customerInfo: oldItem.customerInfo,
        metadata: oldItem.metadata,
        ticketId: oldItem.ticketId,
        name: oldItem.name,
        price: oldItem.price,
      );
      
      _items[itemIndex] = updatedItem;
      _calculateTotals();
      notifyListeners();
      
      POS2DebugHelper.logCart('Extra adicionado - ${extra.name} ao item ${updatedItem.displayName}');
    }
  }

  /// Remover extra de um item
  void removeExtraFromItem(String itemId, int extraId) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      final oldItem = _items[itemIndex];
      final newExtras = List<POS2CartExtra>.from(oldItem.extras);
      newExtras.removeWhere((extra) => extra.id == extraId);
      
      final updatedItem = POS2CartItem(
        id: oldItem.id,
        type: oldItem.type,
        qrCode: oldItem.qrCode,
        product: oldItem.product,
        basePrice: oldItem.basePrice,
        specialPrice: oldItem.specialPrice,
        quantity: oldItem.quantity,
        extras: newExtras,
        customerInfo: oldItem.customerInfo,
        metadata: oldItem.metadata,
        ticketId: oldItem.ticketId,
        name: oldItem.name,
        price: oldItem.price,
      );
      
      _items[itemIndex] = updatedItem;
      _calculateTotals();
      notifyListeners();
      
      POS2DebugHelper.logCart('Extra removido do item ${updatedItem.displayName}');
    }
  }

  /// Atualizar informações do cliente
  void updateCustomerInfo(Map<String, dynamic> newCustomerInfo) {
    _customerInfo = {..._customerInfo, ...newCustomerInfo};
    notifyListeners();
    
    POS2DebugHelper.logCart('Informações do cliente atualizadas');
  }

  /// Limpar carrinho
  void clearCart() {
    _items.clear();
    _customerInfo = {
      'name': '',
      'email': '',
      'phone': '',
      'vatNumber': '',
    };
    _calculateTotals();
    notifyListeners();
    
    POS2DebugHelper.logCart('Carrinho limpo');
  }

  /// Calcular totais do carrinho
  void _calculateTotals() {
    double subtotal = 0.0;
    
    for (final item in _items) {
      subtotal += item.totalPrice;
    }
    
    // No POS2 não há descontos por enquanto
    const double discounts = 0.0;
    final double total = subtotal - discounts;
    
    _totals = POS2CartTotals(
      subtotal: subtotal,
      discounts: discounts,
      total: total,
    );
  }

  /// Preparar dados para checkout
  Map<String, dynamic> prepareCheckoutData({
    required String paymentMethod,
    required Map<String, dynamic> options,
  }) {
    final checkoutItems = _items.map((item) => {
      'id': item.product is POS2Product ? item.product.id : item.product is POS2Extra ? item.product.id : null,
      'type': item.type.value,
      'quantity': item.quantity,
      'name': item.displayName,
      'price': item.price ?? item.basePrice,
      'product': item.product is POS2Product ? {
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
      } : null,
      'extras': item.extras.map((extra) => {
        'id': extra.id,
        'name': extra.name,
        'price': extra.price,
        'quantity': extra.quantity,
      }).toList(),
      'qrCode': item.qrCode,
      'ticket_id': item.ticketId,
      'metadata': item.metadata,
    }).toList();

    return {
      'items': checkoutItems,
      'totals': {
        'subtotal': _totals.subtotal,
        'discounts': _totals.discounts,
        'total': _totals.total,
        'final_total': _totals.total,
      },
      'billing': {
        'name': _customerInfo['name'] ?? '',
        'email': _customerInfo['email'] ?? '',
        'phone': _customerInfo['phone'] ?? '',
        'vatNumber': _customerInfo['vatNumber'] ?? '',
      },
      'payment': {
        'method': paymentMethod,
      },
      'options': options,
    };
  }

  @override
  String toString() {
    return 'POS2CartProvider{items: ${_items.length}, total: ${_totals.total}}';
  }
}