// Torna CartService singleton para garantir estado global
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<Map<String, dynamic>> items = [];
  int totalItems = 0;
  double totalPrice = 0.00;
  updateCart() {
    try {
      // Contar totalItems como soma das quantities (não apenas items.length)
      totalItems = 0;
      totalPrice = 0;
      
      for (var element in items) {
        // Somar a quantidade de cada item
        int quantity = element['quantity'] as int? ?? 1;
        totalItems += quantity;
        
        double itemTotal = 0.0;
        try {
          itemTotal = element['itemTotal'] as double? ?? 0.0;
        } catch (e) {
          print("Error converting itemTotal to double: $e");
          // Try to recalculate based on price and quantity
          double price = element['price'] as double? ?? 0.0;
          itemTotal = price * quantity;
          // Update the element with the corrected value
          element['itemTotal'] = itemTotal;
        }
        
        totalPrice += itemTotal;
      }
      
      // Round to 2 decimal places to avoid floating point issues
      totalPrice = double.parse(totalPrice.toStringAsFixed(2));
      print("CartService: Cart updated - $totalItems items (sum of quantities), total price: €$totalPrice");
    } catch (e) {
      print("CartService ERROR in updateCart: $e");
    }
  }
  bool addItem(Map<String, dynamic> item, {int quantityToAdd = 1}) {
    try {
      print("CartService: Adding item with ID: ${item['id']}, quantity to add: $quantityToAdd");
      if (!item.containsKey('id')) {
        print("CartService: Item lacks 'id', can't add");
        return false;
      }
      
      final exists = items.indexWhere((element) => element['id'] == item['id']);
      if (exists < 0) {
        // New item
        final double itemPrice = (item['price'] is double) 
            ? item['price'] 
            : double.tryParse(item['price'].toString()) ?? 0.0;
        
        final int initialQuantity = item['quantity'] as int? ?? quantityToAdd;
            
        final newItem = {
          'id': item['id'],
          'quantity': initialQuantity,
          'item': item,
          'price': itemPrice,
          'itemTotal': itemPrice * initialQuantity
        };
        print("CartService: Adding new item: ${item['name']}, price: $itemPrice, quantity: $initialQuantity");
        items.add(newItem);
      } else {
        // Existing item, update quantity
        int newQty = (items[exists]['quantity'] as int? ?? 0) + quantityToAdd;
        double price = (items[exists]['price'] as double? ?? 0.0);
        double newPrice = newQty * price;
        items[exists]['quantity'] = newQty;
        items[exists]['itemTotal'] = newPrice;
        print("CartService: Updated item: ${item['name']}, new quantity: $newQty, new total: $newPrice");
      }
      
      updateCart();
      print("CartService: Cart updated, total items: $totalItems, total price: $totalPrice");
      return true;
    } catch (e) {
      print("CartService ERROR in addItem: $e");
      return false;
    }
  }
  bool updateQuantity(Map<String, dynamic> item, int qty) {
    try {
      print("CartService: Updating quantity for item ID: ${item['id']}, change: $qty");
      
      if (!item.containsKey('id')) {
        print("CartService: Item lacks 'id', can't update quantity");
        return false;
      }
      
      final exists = items.indexWhere((element) => element['id'] == item['id']);
      if (exists < 0 || items[exists]['quantity'] < 1) {
        print("CartService: Item not found in cart or quantity < 1");
        return false;
      }
      
      int currentQty = items[exists]['quantity'] as int? ?? 0;
      print("CartService: Current quantity: $currentQty");
      
      // Remove item if it will reach 0
      if (currentQty == 1 && qty < 0) {
        print("CartService: Removing item from cart as quantity will be 0");
        items.removeAt(exists);
      } else {
        // Update quantity and price
        int newQty = currentQty + qty;
        double price = (items[exists]['price'] as double? ?? 0.0);
        double newPrice = newQty * price;
        
        items[exists]['quantity'] = newQty;
        items[exists]['itemTotal'] = newPrice;
        print("CartService: Updated quantity to: $newQty, new total: $newPrice");
      }
      
      updateCart();
      print("CartService: Cart updated after quantity change, total items: $totalItems, total price: $totalPrice");
      return true;
    } catch (e) {
      print("CartService ERROR in updateQuantity: $e");
      return false;
    }
  }
  Map<String, dynamic> getItem(id) {
    try {
      final product = items.indexWhere((item) => item['id'] == id);
      print("CartService: Getting item with ID: $id, found: ${product >= 0}");
      return product >= 0 ? items[product] : {};
    } catch (e) {
      print("CartService ERROR in getItem: $e");
      return {};
    }
  }

  void resetCart() {
    items = [];
    totalItems = 0;
    totalPrice = 0.00;
  }
}
