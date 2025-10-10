import 'package:flutter/material.dart';
import '../services/pos2_cart_service.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';

/// Tela de checkout do sistema POS2
/// Permite informar dados do cliente e finalizar a compra
class POS2CheckoutView extends StatefulWidget {
  const POS2CheckoutView({super.key});

  @override
  State<POS2CheckoutView> createState() => _POS2CheckoutViewState();
}

class _POS2CheckoutViewState extends State<POS2CheckoutView> {
  // Instância do serviço de carrinho
  final POS2CartService _cartService = POS2CartService.instance;
  
  // Estados para exibição
  bool _isLoading = false;
  String _selectedPaymentMethod = 'Cash';
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Lista de métodos de pagamento
  List<Map<String, String>> _paymentMethods = [
    {'value': 'Cash', 'label': 'Dinheiro'},
    {'value': 'Card', 'label': 'Cartão'},
    {'value': 'Transfer', 'label': 'Transferência'},
    {'value': 'Other', 'label': 'Outro'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Carregar métodos de pagamento da API
  Future<void> _loadPaymentMethods() async {
    try {
      setState(() => _isLoading = true);
      final response = await POS2ApiService.getPaymentMethods();
      
      if (response['success'] && response['data'] is List) {
        setState(() {
          _paymentMethods = List<Map<String, String>>.from(
            (response['data'] as List).map((method) => {
              'value': method['value']?.toString() ?? '',
              'label': method['label']?.toString() ?? '',
            })
          );
        });
        
        if (_paymentMethods.isNotEmpty) {
          setState(() => _selectedPaymentMethod = _paymentMethods.first['value'] ?? 'Cash');
        }
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao carregar métodos de pagamento', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Processar checkout
  Future<void> _handleCheckout() async {
    if (_cartService.items.isEmpty) {
      _showMessage('O carrinho está vazio', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _cartService.checkout(
        paymentMethod: _selectedPaymentMethod,
        customerName: _customerNameController.text.isEmpty ? null : _customerNameController.text,
        customerEmail: _customerEmailController.text.isEmpty ? null : _customerEmailController.text,
        customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (result['success']) {
        _showMessage('Compra finalizada com sucesso!');
        
        // Exibir dados do pedido
        if (mounted) {
          _showOrderSuccessDialog(result);
        }
      } else {
        _showMessage(result['message'] ?? 'Erro ao finalizar compra', isError: true);
      }
    } catch (e) {
      _showMessage('Erro ao processar pagamento: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mostrar diálogo com informações do pedido bem-sucedido
  void _showOrderSuccessDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Compra Finalizada!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido #${orderData['order']?['id'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Total: €${(orderData['order']?['total'] ?? 0.0).toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              
              // Bilhetes
              if (orderData['tickets'] != null && orderData['tickets'] is List && (orderData['tickets'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bilhetes:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...List.from((orderData['tickets'] as List).map((ticket) => 
                      Text('${ticket['name'] ?? 'Bilhete'} - ${ticket['code'] ?? 'N/A'}')
                    )),
                  ],
                ),
                
              const SizedBox(height: 16),
              
              // Link para a fatura
              if (orderData['invoice_url'] != null)
                InkWell(
                  onTap: () {
                    // Abrir URL da fatura
                  },
                  child: Text(
                    'Ver Fatura',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Voltar à tela anterior e depois à tela inicial
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  // Exibir mensagem na snackbar
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartService.items.isEmpty
              ? _buildEmptyCart()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumo dos itens
                      _buildOrderSummary(),
                      
                      // Informações do cliente
                      const SizedBox(height: 24),
                      const Text(
                        'Informações do Cliente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Campos do cliente
                      TextField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome (opcional)',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _customerEmailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail (opcional)',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _customerPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Observações
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações (opcional)',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      
                      // Método de pagamento
                      const Text(
                        'Método de Pagamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethod,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.payment),
                          border: OutlineInputBorder(),
                        ),
                        items: _paymentMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method['value'],
                            child: Text(method['label'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value ?? 'Cash');
                        },
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _cartService.items.isEmpty ? null : _buildCheckoutBar(),
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

  // Resumo dos itens do pedido
  Widget _buildOrderSummary() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do Pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista resumida de itens
            ...List.generate(_cartService.items.length, (index) {
              final item = _cartService.items[index];
              final itemData = item['item'];
              final price = item['price'] as double? ?? 0.0;
              final quantity = item['quantity'] as int? ?? 1;
              final itemTotal = (price * quantity);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        '${itemData['name'] ?? 'Item'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$quantity x €${price.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '€${itemTotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€${_cartService.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Voltar para o carrinho
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para o carrinho'),
              ),
            ),
          ],
        ),
      ),
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
            onPressed: _isLoading ? null : _handleCheckout,
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
                : const Text('FINALIZAR COMPRA'),
          ),
        ],
      ),
    );
  }
}