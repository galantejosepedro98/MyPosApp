enum POS2CartItemType {
  ticket,
  extra,
  qrScan,
  paidInviteActivation,
}

extension POS2CartItemTypeExtension on POS2CartItemType {
  String get value {
    switch (this) {
      case POS2CartItemType.ticket:
        return 'ticket';
      case POS2CartItemType.extra:
        return 'extra';
      case POS2CartItemType.qrScan:
        return 'qr_scan';
      case POS2CartItemType.paidInviteActivation:
        return 'paid_invite_activation';
    }
  }
  
  static POS2CartItemType fromString(String value) {
    switch (value) {
      case 'ticket':
        return POS2CartItemType.ticket;
      case 'extra':
        return POS2CartItemType.extra;
      case 'qr_scan':
        return POS2CartItemType.qrScan;
      case 'paid_invite_activation':
        return POS2CartItemType.paidInviteActivation;
      default:
        throw ArgumentError('Unknown cart item type: $value');
    }
  }
}

class POS2CartItem {
  final String id;
  final POS2CartItemType type;
  final String? qrCode;
  final dynamic product; // POS2Product or POS2Extra
  final double basePrice;
  final double? specialPrice; // Para paid invites
  final int quantity;
  final List<POS2CartExtra> extras;
  final Map<String, dynamic>? customerInfo;
  final Map<String, dynamic> metadata;
  final String? ticketId; // Para extras adicionados via scanner
  final String? name; // Para preservar o nome do extra
  final double? price; // Para preservar o preço do extra

  POS2CartItem({
    required this.id,
    required this.type,
    this.qrCode,
    required this.product,
    required this.basePrice,
    this.specialPrice,
    required this.quantity,
    this.extras = const [],
    this.customerInfo,
    this.metadata = const {},
    this.ticketId,
    this.name,
    this.price,
  });

  double get totalPrice {
    final itemPrice = specialPrice ?? price ?? basePrice;
    final itemTotal = itemPrice * quantity;
    final extrasTotal = extras.fold(0.0, (sum, extra) => sum + extra.totalPrice);
    return itemTotal + extrasTotal;
  }

  String get displayName {
    return name ?? product?.name ?? 'Item';
  }

  factory POS2CartItem.fromJson(Map<String, dynamic> json) {
    return POS2CartItem(
      id: json['id'] as String,
      type: POS2CartItemTypeExtension.fromString(json['type'] as String),
      qrCode: json['qrCode'] as String?,
      product: json['product'],
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      specialPrice: json['specialPrice']?.toDouble(),
      quantity: json['quantity'] as int,
      extras: json['extras'] != null 
          ? (json['extras'] as List).map((e) => POS2CartExtra.fromJson(e)).toList()
          : [],
      customerInfo: json['customerInfo'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      ticketId: json['ticket_id'] as String?,
      name: json['name'] as String?,
      price: json['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'qrCode': qrCode,
      'product': product,
      'basePrice': basePrice,
      'specialPrice': specialPrice,
      'quantity': quantity,
      'extras': extras.map((e) => e.toJson()).toList(),
      'customerInfo': customerInfo,
      'metadata': metadata,
      'ticket_id': ticketId,
      'name': name,
      'price': price,
    };
  }

  @override
  String toString() {
    return 'POS2CartItem{id: $id, type: ${type.value}, name: $displayName, quantity: $quantity, totalPrice: $totalPrice}';
  }
}

class POS2CartExtra {
  final int id;
  final String name;
  final double price;
  final int quantity;

  POS2CartExtra({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get totalPrice => price * quantity;

  factory POS2CartExtra.fromJson(Map<String, dynamic> json) {
    return POS2CartExtra(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'POS2CartExtra{id: $id, name: $name, quantity: $quantity, totalPrice: $totalPrice}';
  }
}

class POS2CartTotals {
  final double subtotal;
  final double discounts;
  final double total;

  POS2CartTotals({
    required this.subtotal,
    required this.discounts,
    required this.total,
  });

  factory POS2CartTotals.fromJson(Map<String, dynamic> json) {
    return POS2CartTotals(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discounts: (json['discounts'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'discounts': discounts,
      'total': total,
    };
  }

  @override
  String toString() {
    return 'POS2CartTotals{subtotal: $subtotal, discounts: $discounts, total: $total}';
  }
}