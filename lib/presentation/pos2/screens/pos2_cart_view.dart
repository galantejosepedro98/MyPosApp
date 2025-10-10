import 'package:flutter/material.dart';
import '../services/pos2_cart_service.dart';
import 'pos2_checkout_view.dart';

/// Tela do carrinho de compras para o sistema POS2
/// Mostra os itens adicionados e permite prosseguir para o checkout
class POS2CartView extends StatefulWidget {
  const POS2CartView({super.key});

  @override
  State<POS2CartView> createState() => _POS2CartViewState();
}

class _POS2CartViewState extends State<POS2CartView> {
  // Instância do serviço de carrinho
  final POS2CartService _cartService = POS2CartService.instance;
  
  // Estados para exibição
  final bool _isLoading = false;

  // Navegar para a tela de checkout
  void _navigateToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const POS2CheckoutView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cartService.items;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho de Compras'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpar carrinho',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Limpar carrinho?'),
                    content: const Text('Todos os itens serão removidos do carrinho.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CANCELAR'),
                      ),
                      TextButton(
                        onPressed: () {
                          _cartService.clear();
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('LIMPAR'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? _buildEmptyCart()
            : _buildCartContent(),
      bottomNavigationBar: items.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  // Widget para carrinho vazio
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'O carrinho está vazio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione itens ao carrinho para continuar',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('VOLTAR'),
          ),
        ],
      ),
    );
  }

  // Widget para conteúdo do carrinho
  Widget _buildCartContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartService.items.length,
      itemBuilder: (context, index) {
        final item = _cartService.items[index];
        final itemData = item['item'];
        final itemType = itemData['type'] ?? 'item';
        final price = item['price'] as double? ?? 0.0;
        final quantity = item['quantity'] as int? ?? 1;
        final itemTotal = (price * quantity);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ícone com base no tipo
                    Icon(
                      itemType == 'ticket'
                          ? Icons.confirmation_number
                          : itemType == 'extra'
                              ? Icons.fastfood
                              : Icons.shopping_bag,
                      color: itemType == 'ticket'
                          ? Colors.blue
                          : itemType == 'extra'
                              ? Colors.amber
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    // Nome do item
                    Expanded(
                      child: Text(
                        itemData['name'] ?? 'Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Botão para remover
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _cartService.removeItem(item['id']);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Informações do item
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Preço: €${price.toStringAsFixed(2)}'),
                    // Exibição estática da quantidade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Quantidade: $quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                // Total do item
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total: €${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Barra de checkout
  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${_cartService.totalItems} ${_cartService.totalItems == 1 ? 'item' : 'itens'}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '€${_cartService.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _navigateToCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('PROSSEGUIR'),
          ),
        ],
      ),
    );
  }
}