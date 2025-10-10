library pos2_models;

/// Modelos para o sistema POS2
/// Incluindo classes para produtos, ingressos, extras, etc.

class POS2Customer {
  String? name;
  String? email;
  String? phone;

  POS2Customer({
    this.name,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory POS2Customer.fromJson(Map<String, dynamic> json) {
    return POS2Customer(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class POS2CheckoutOptions {
  bool sendSms;
  bool sendEmail;
  bool printInvoice;

  POS2CheckoutOptions({
    this.sendSms = false,
    this.sendEmail = false,
    this.printInvoice = false,
  });
}

class POS2Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String type;
  final int? eventId;
  final Map<String, dynamic>? metadata;

  POS2Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    required this.type,
    this.eventId,
    this.metadata,
  });

  factory POS2Product.fromJson(Map<String, dynamic> json) {
    return POS2Product(
      id: json['id'],
      name: json['name'],
      price: json['price'] is String 
        ? double.tryParse(json['price']) ?? 0.0 
        : (json['price'] ?? 0.0).toDouble(),
      description: json['description'],
      type: json['type'] ?? 'ticket',
      eventId: json['event_id'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'type': type,
      'event_id': eventId,
      'metadata': metadata,
    };
  }
}

class POS2Extra {
  final int id;
  final String name;
  final double price;
  final int? eventId;
  final int available;
  final String? description;

  POS2Extra({
    required this.id,
    required this.name,
    required this.price,
    this.eventId,
    required this.available,
    this.description,
  });

  factory POS2Extra.fromJson(Map<String, dynamic> json) {
    return POS2Extra(
      id: json['id'],
      name: json['name'],
      price: json['price'] is String 
        ? double.tryParse(json['price']) ?? 0.0 
        : (json['price'] ?? 0.0).toDouble(),
      eventId: json['event_id'],
      available: json['available'] ?? 0,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'event_id': eventId,
      'available': available,
      'description': description,
    };
  }
}

class POS2Event {
  final int id;
  final String name;
  final String? description;
  final String? date;
  final String? location;
  final String status;

  POS2Event({
    required this.id,
    required this.name,
    this.description,
    this.date,
    this.location,
    required this.status,
  });

  factory POS2Event.fromJson(Map<String, dynamic> json) {
    return POS2Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: json['date'],
      location: json['location'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date,
      'location': location,
      'status': status,
    };
  }
}

class POS2Order {
  final int id;
  final String referenceNumber;
  final double total;
  final String paymentMethod;
  final String status;
  final String? invoiceUrl;

  POS2Order({
    required this.id,
    required this.referenceNumber,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.invoiceUrl,
  });

  factory POS2Order.fromJson(Map<String, dynamic> json) {
    return POS2Order(
      id: json['id'],
      referenceNumber: json['reference_number'] ?? '',
      total: json['total'] is String 
        ? double.tryParse(json['total']) ?? 0.0 
        : (json['total'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'unknown',
      status: json['status'] ?? 'pending',
      invoiceUrl: json['invoice_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_number': referenceNumber,
      'total': total,
      'payment_method': paymentMethod,
      'status': status,
      'invoice_url': invoiceUrl,
    };
  }
}

class POS2Ticket {
  final int id;
  final String code;
  final int productId;
  final int orderId;
  final String status;

  POS2Ticket({
    required this.id,
    required this.code,
    required this.productId,
    required this.orderId,
    required this.status,
  });

  factory POS2Ticket.fromJson(Map<String, dynamic> json) {
    return POS2Ticket(
      id: json['id'],
      code: json['code'] ?? '',
      productId: json['product_id'],
      orderId: json['order_id'],
      status: json['status'] ?? 'valid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'product_id': productId,
      'order_id': orderId,
      'status': status,
    };
  }
}