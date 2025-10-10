import 'package:flutter/material.dart';
import 'dart:convert';
import '../widgets/universal_scanner.dart';
import '../services/pos2_debug_helper.dart';

/// Tela para demonstração do scanner universal
class ScannerDemoView extends StatefulWidget {
  const ScannerDemoView({super.key});

  @override
  State<ScannerDemoView> createState() => _ScannerDemoViewState();
}

class _ScannerDemoViewState extends State<ScannerDemoView> {
  Map<String, dynamic>? _lastScanResult;
  List<Map<String, dynamic>> _cartItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Universal Demo'),
        actions: [
          // Badge com número de itens no carrinho
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  _showCart();
                },
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teste o Scanner Universal',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Scanner Universal
            UniversalScanner(
              onScanResult: _handleScanResult,
              onAddToCart: _handleAddToCart,
              selectedEventId: 1, // Demo apenas
            ),
            
            // Último resultado do scan
            if (_lastScanResult != null) ...[
              const SizedBox(height: 24.0),
              const Divider(),
              const Text(
                'Último resultado do scan:',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  jsonEncode(_lastScanResult),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontFamily: 'Courier',
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Manipular resultado do scan
  void _handleScanResult(Map<String, dynamic> result) {
    POS2DebugHelper.log('Scan result: $result');
    setState(() => _lastScanResult = result);
  }

  /// Adicionar item ao carrinho
  void _handleAddToCart(Map<String, dynamic> item) {
    setState(() {
      _cartItems.add(item);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item "${item['name'] ?? 'Item'}" adicionado ao carrinho'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VER CARRINHO',
          textColor: Colors.white,
          onPressed: () => _showCart(),
        ),
      ),
    );
  }

  /// Mostrar carrinho
  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Carrinho',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(child: Text('Carrinho vazio'))
                  : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return ListTile(
                          title: Text(item['name'] ?? 'Item sem nome'),
                          subtitle: Text(
                            'Preço: €${(item['price'] ?? 0.0).toStringAsFixed(2)} | Tipo: ${item['type'] ?? 'N/A'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _cartItems.removeAt(index);
                              });
                              Navigator.of(context).pop();
                              _showCart(); // Atualizar modal
                            },
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Total: €${_calculateTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            ElevatedButton(
              onPressed: _cartItems.isEmpty ? null : () {
                // Simulação de checkout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Processando checkout... (Demonstração)'),
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text('FINALIZAR COMPRA'),
            ),
          ],
        ),
      ),
    );
  }

  /// Calcular valor total do carrinho
  double _calculateTotal() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item['price'] ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }
}