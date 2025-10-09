class POS2Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final int eventId;
  final bool active;
  final List<String>? dates;
  final List<POS2Extra> offerExtras;
  final String? image;
  final String? vendusItemCode;
  final String? vendusItemId;

  POS2Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    required this.eventId,
    required this.active,
    this.dates,
    this.offerExtras = const [],
    this.image,
    this.vendusItemCode,
    this.vendusItemId,
  });

  factory POS2Product.fromJson(Map<String, dynamic> json) {
    return POS2Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Produto',
      description: json['description'] as String?,
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      eventId: json['event_id'] ?? 0,
      active: json['active'] == 1 || json['active'] == true,
      dates: json['dates'] != null 
          ? List<String>.from(json['dates']) 
          : null,
      offerExtras: json['extras'] != null 
          ? (json['extras'] as List).map((e) => POS2Extra.fromJson(e)).toList()
          : [],
      image: json['image'] as String?,
      vendusItemCode: json['vendus_item_code'] as String?,
      vendusItemId: json['vendus_item_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'event_id': eventId,
      'active': active ? 1 : 0,
      'dates': dates,
      'extras': offerExtras.map((e) => e.toJson()).toList(),
      'image': image,
      'vendus_item_code': vendusItemCode,
      'vendus_item_id': vendusItemId,
    };
  }

  bool get hasStock => quantity > 0;
  
  bool isAvailableForDate(String date) {
    if (dates == null || dates!.isEmpty) return true;
    return dates!.contains(date);
  }

  @override
  String toString() {
    return 'POS2Product{id: $id, name: $name, price: $price, quantity: $quantity}';
  }
}

class POS2Extra {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int quantity; // Quantidade/stock - sempre 999 para extras (ilimitado)
  final int eventId;
  final bool active;
  final String? image;
  final String? vendusItemCode;
  final String? vendusItemId;

  POS2Extra({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.quantity = 999, // Padrão: extras têm stock ilimitado
    required this.eventId,
    required this.active,
    this.image,
    this.vendusItemCode,
    this.vendusItemId,
  });

  factory POS2Extra.fromJson(Map<String, dynamic> json) {
    return POS2Extra(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Extra',
      description: json['description'] as String?,
      price: (json['price'] ?? 0).toDouble(),
      quantity: 999, // EXTRAS SEMPRE TÊM STOCK ILIMITADO - não há controlo de stock
      eventId: json['event_id'] ?? 0,
      active: json['status'] == 1 || json['active'] == 1 || json['active'] == true,
      image: json['image'] as String?,
      vendusItemCode: json['vendus_item_code'] as String?,
      vendusItemId: json['vendus_item_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'event_id': eventId,
      'active': active ? 1 : 0,
      'image': image,
      'vendus_item_code': vendusItemCode,
      'vendus_item_id': vendusItemId,
    };
  }

  bool get hasStock => quantity > 0;

  @override
  String toString() {
    return 'POS2Extra{id: $id, name: $name, price: $price, quantity: $quantity}';
  }
}