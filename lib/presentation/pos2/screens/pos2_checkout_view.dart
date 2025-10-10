import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/pos2_cart_service.dart';
import '../services/pos2_debug_helper.dart';
import '../services/pos2_permission_helper.dart';
import '../widgets/pos2_loading_overlay.dart';

/// Tela de checkout para o sistema POS2
/// Implementada de acordo com o design do website
class POS2CheckoutView extends StatefulWidget {
  const POS2CheckoutView({super.key});

  @override
  State<POS2CheckoutView> createState() => _POS2CheckoutViewState();
}

class _POS2CheckoutViewState extends State<POS2CheckoutView> {
  // Serviço de carrinho
  final POS2CartService _cartService = POS2CartService.instance;
  
  // Form key para validação
  final _formKey = GlobalKey<FormState>();
  
  // Estado da tela
  bool _isProcessing = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Controladores para campos de texto
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerVatNumberController = TextEditingController();
  final _paidAmountController = TextEditingController();
  
  // Payment method
  String _selectedPaymentMethod = 'card'; // Padrão é cartão
  
  // Opções adicionais
  bool _sendToMail = false;
  bool _sendToPhone = true; // SMS habilitado por padrão
  bool _printInvoice = false;
  bool _sendInvoiceEmail = false;
  bool _withdraw = false;
  bool _physicalQr = false;
  double _paidAmount = 0.0;
  
  // Métodos de pagamento disponíveis
  List<String> _availablePaymentMethods = ['card', 'cash', 'transfer'];

  @override
  void initState() {
    super.initState();
    _paidAmountController.text = _cartService.totalPrice.toStringAsFixed(2);
    _loadPosData();
  }
  
  // Carregar dados do POS, incluindo métodos de pagamento permitidos
  Future<void> _loadPosData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Obter dados do usuário/POS atual
      final userData = await POS2PermissionHelper.getUserData();
      
      // Verificar se temos informações do POS
      if (userData['pos'] != null) {
        final pos = userData['pos'];
        
        // Verificar métodos de pagamento disponíveis
        if (pos['payment_methods'] != null) {
          Map<String, dynamic> paymentMethods;
          
          // Pode estar como String JSON ou já como Map
          if (pos['payment_methods'] is String) {
            paymentMethods = jsonDecode(pos['payment_methods']);
          } else {
            paymentMethods = pos['payment_methods'];
          }
          
          // Filtrar apenas os métodos habilitados (valor 1 ou true)
          final availableMethods = <String>[];
          paymentMethods.forEach((key, value) {
            if (value == 1 || value == '1' || value == true) {
              availableMethods.add(key.toLowerCase());
            }
          });
          
          // Se não houver métodos disponíveis, usar card como padrão
          if (availableMethods.isEmpty) {
            availableMethods.add('card');
          }
          
          // Atualizar estado
          setState(() {
            _availablePaymentMethods = availableMethods;
            _selectedPaymentMethod = availableMethods.first;
          });
          
          POS2DebugHelper.log('Métodos de pagamento disponíveis: $_availablePaymentMethods');
        }
      }
      
    } catch (e) {
      POS2DebugHelper.logError('Erro ao carregar dados do POS', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerVatNumberController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Método para processar o checkout
  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _cartService.checkout(
        paymentMethod: _selectedPaymentMethod,
        customerName: _customerNameController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        notes: _notesController.text.trim(),
        sendSms: _sendToPhone,
        sendEmail: _sendToMail,
        printInvoice: _printInvoice,
        sendInvoiceEmail: _sendInvoiceEmail,
        withdraw: _withdraw,
        physicalQr: _physicalQr,
      );

      if (!mounted) return;

      if (result['success']) {
        // Mostrar diálogo de sucesso
        _showSuccessDialog(result);
      } else {
        // Mostrar mensagem de erro
        setState(() {
          _errorMessage = result['message'] ?? 'Ocorreu um erro durante o processamento do pagamento.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao processar checkout', error: e);
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado: $e';
        _isProcessing = false;
      });
    }
  }

  // Diálogo de sucesso
  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Pagamento Concluído'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O pagamento foi processado com sucesso!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Detalhes do pedido
              if (result['order'] != null) ...[
                const Text('Detalhes do Pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Número: #${result['order']['reference_number'] ?? 'N/A'}'),
                Text('Total: €${result['order']['total']?.toStringAsFixed(2) ?? '0.00'}'),
                const SizedBox(height: 16),
              ],
              
              // Ações disponíveis
              if (result['invoice_url'] != null || (result['tickets'] != null && (result['tickets'] as List).isNotEmpty)) ...[
                const Text('Ações disponíveis:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              
              // Botão para fatura se disponível
              if (result['invoice_url'] != null)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar abertura da fatura
                    Navigator.of(context).pop(); // Fecha o diálogo
                  },
                  icon: const Icon(Icons.receipt),
                  label: const Text('Ver Fatura'),
                ),
              
              // Botão para imprimir tickets se disponível
              if (result['tickets'] != null && (result['tickets'] as List).isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar impressão de tickets
                    Navigator.of(context).pop(); // Fecha o diálogo
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir Tickets'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              // Retorna à tela anterior
              Navigator.of(context).pop();
            },
            child: const Text('CONCLUIR'),
          ),
        ],
      ),
    );
  }

  double _calculateReturnAmount() {
    return _selectedPaymentMethod == 'cash' && _paidAmount > _cartService.totalPrice 
      ? _paidAmount - _cartService.totalPrice 
      : 0;
  }

  @override
  Widget build(BuildContext context) {
    return POS2LoadingOverlay(
      isLoading: _isProcessing,
      message: 'Processando pagamento...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finalizar Compra'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando métodos de pagamento...'),
                ],
              ),
            )
          : _buildCheckoutForm(),
      ),
    );
  }

  // Formulário principal de checkout
  Widget _buildCheckoutForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumo do pedido
          _buildOrderSummary(),
          const SizedBox(height: 20),
          
          // Seção Cliente
          _buildCustomerSection(),
          const SizedBox(height: 20),
          
          // Seção Pagamento
          _buildPaymentSection(),
          const SizedBox(height: 20),
          
          // Opções adicionais
          _buildOptionsSection(),
          const SizedBox(height: 20),
          
          // Mensagem de erro (se houver)
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Botão de finalizar compra
          ElevatedButton(
            onPressed: _isProcessing ? null : _processCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'CONFIRMAR PAGAMENTO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Resumo do pedido
  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shopping_cart),
                SizedBox(width: 8),
                Text(
                  'Resumo do Carrinho',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Lista de itens
            ..._cartService.items.map((item) {
              final itemData = item['item'];
              final price = item['price'] as double? ?? 0.0;
              final quantity = item['quantity'] as int? ?? 1;
              final itemTotal = price * quantity;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Ícone baseado no tipo de item
                    Icon(
                      itemData['type'] == 'ticket'
                          ? Icons.confirmation_number
                          : itemData['type'] == 'extra'
                              ? Icons.fastfood
                              : Icons.shopping_bag,
                      color: itemData['type'] == 'ticket'
                          ? Colors.blue
                          : itemData['type'] == 'extra'
                              ? Colors.amber
                              : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    
                    // Nome e detalhes
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemData['name'] ?? 'Item',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (quantity > 1)
                            Text(
                              '€${price.toStringAsFixed(2)} x $quantity',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Preço total
                    Text(
                      '€${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€${_cartService.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Seção de informações do cliente
  Widget _buildCustomerSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 8),
                Text(
                  'Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nome do cliente (obrigatório)
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Email (opcional)
            TextFormField(
              controller: _customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Validação básica de email
                  final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailPattern.hasMatch(value)) {
                    return 'Por favor, insira um email válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Telefone (opcional)
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: '+351...',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            
            // NIF (opcional)
            TextFormField(
              controller: _customerVatNumberController,
              decoration: const InputDecoration(
                labelText: 'NIF (opcional)',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  // Seção de métodos de pagamento
  Widget _buildPaymentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment),
                SizedBox(width: 8),
                Text(
                  'Pagamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Método de pagamento
            const Text('Método de Pagamento:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Opções de métodos de pagamento
            if (_availablePaymentMethods.contains('card'))
              _buildPaymentMethod('card', 'Cartão de Crédito/Débito', Icons.credit_card),
            if (_availablePaymentMethods.contains('cash'))
              _buildPaymentMethod('cash', 'Dinheiro', Icons.attach_money),
            if (_availablePaymentMethods.contains('transfer'))
              _buildPaymentMethod('transfer', 'Transferência', Icons.account_balance),
            if (_availablePaymentMethods.contains('mbway'))
              _buildPaymentMethod('mbway', 'MB WAY', Icons.phone_android),
            
            // Campo de valor pago (para pagamento em dinheiro)
            if (_selectedPaymentMethod == 'cash') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _paidAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Valor Pago (€)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _paidAmount = double.tryParse(value) ?? 0.0;
                        });
                      },
                      validator: (value) {
                        if (_selectedPaymentMethod == 'cash') {
                          final amount = double.tryParse(value ?? '0') ?? 0;
                          if (amount < _cartService.totalPrice) {
                            return 'Valor deve ser maior ou igual ao total';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _calculateReturnAmount() > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _calculateReturnAmount() > 0 ? Colors.green.shade300 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Troco:'),
                          const SizedBox(height: 4),
                          Text(
                            '€${_calculateReturnAmount().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _calculateReturnAmount() > 0 ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Método de pagamento individual
  Widget _buildPaymentMethod(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade700 : Colors.black,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // Seção de opções adicionais
  Widget _buildOptionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text(
                  'Opções',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Opções em grid de 2x3
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildOptionSwitch(
                        'Enviar Email', 
                        _sendToMail, 
                        (value) => setState(() => _sendToMail = value),
                      ),
                      _buildOptionSwitch(
                        'Enviar SMS', 
                        _sendToPhone, 
                        (value) => setState(() => _sendToPhone = value),
                      ),
                      _buildOptionSwitch(
                        'Fatura Email', 
                        _sendInvoiceEmail, 
                        (value) => setState(() => _sendInvoiceEmail = value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildOptionSwitch(
                        'Imprimir Fatura', 
                        _printInvoice, 
                        (value) => setState(() => _printInvoice = value),
                      ),
                      _buildOptionSwitch(
                        'Levantar', 
                        _withdraw, 
                        (value) => setState(() => _withdraw = value),
                      ),
                      _buildOptionSwitch(
                        'QR Físico', 
                        _physicalQr, 
                        (value) => setState(() => _physicalQr = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Switch para opções
  Widget _buildOptionSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).primaryColor.withAlpha(128),
            activeThumbColor: Theme.of(context).primaryColor,
          ),
          Text(label),
        ],
      ),
    );
  }
}