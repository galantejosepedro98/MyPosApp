import 'package:flutter/material.dart';
import 'package:essenciacompany_mobile/presentation/pos2/widgets/universal_scanner_new.dart';
import 'package:provider/provider.dart';
import '../providers/pos2_cart_provider.dart';

class ScannerDemoView extends StatefulWidget {
  const ScannerDemoView({super.key});

  @override
  State<ScannerDemoView> createState() => _ScannerDemoViewState();
}

class _ScannerDemoViewState extends State<ScannerDemoView> {
  Map<String, dynamic>? lastScanResult;

  void _handleScanResult(Map<String, dynamic> result) {
    setState(() {
      lastScanResult = result;
    });
    
    // Exibir toast ou snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código escaneado: ${result['ticket'] ?? 'Desconhecido'}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleAddToCart(Map<String, dynamic> item) {
    // Adicionar ao carrinho usando o provider
    final cartProvider = Provider.of<POS2CartProvider>(context, listen: false);
    cartProvider.addItem(item);
    
    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} adicionado ao carrinho'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<POS2CartProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Universal'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Implementar navegação para o carrinho
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner universal
              UniversalScannerNew(
                onScanResult: _handleScanResult,
                onAddToCart: _handleAddToCart,
                selectedEventId: 1, // ID do evento selecionado (exemplo)
              ),
            ],
          ),
        ),
      ),
    );
  }
}