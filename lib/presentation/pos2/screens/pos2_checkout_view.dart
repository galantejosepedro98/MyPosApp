import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:my_pos/my_pos.dart';
import 'package:my_pos/enums/my_pos_currency_enum.dart';
import 'package:my_pos/enums/py_pos_payment_response.dart';
import '../services/pos2_cart_service.dart';
import '../services/pos2_debug_helper.dart';
import '../services/pos2_permission_helper.dart';
import '../services/print_service.dart';
import '../widgets/pos2_loading_overlay.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Tela de checkout para o sistema POS2
/// Implementada de acordo com o design do website
class POS2CheckoutView extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const POS2CheckoutView({super.key, this.onRefresh});

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
  bool _isButtonEnabled = false;
  
  // Controle do passo atual (1 ou 2)
  int _currentStep = 1;
  
  // Variáveis para o telefone internacional
  String? _countryCode = 'PT'; // Portugal como padrão
  String? _dialCode = '+351'; // Código de discagem do Portugal como padrão
  
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
  final bool _printInvoice = false;
  final bool _sendInvoiceEmail = false;
  final bool _withdraw = false;
  bool _physicalQr = false;
  
  // Métodos de pagamento disponíveis
  List<String> _availablePaymentMethods = ['card', 'cash', 'transfer'];

  @override
  void initState() {
    super.initState();
    _paidAmountController.text = _cartService.totalPrice.toStringAsFixed(2);
    // Configurações padrão: SMS selecionado, e-mail/QR desativados
    _sendToPhone = true;
    _sendToMail = false;
    _physicalQr = false;
    
    // Adicionar listeners para os campos de entrada
    _customerNameController.addListener(_updateButtonState);
    _customerEmailController.addListener(_updateButtonState);
    _customerPhoneController.addListener(_updateButtonState);
    
    _loadPosData();
  }
  
  // Método para atualizar o estado do botão baseado nos campos preenchidos
  void _updateButtonState() {
    if (_currentStep == 2) {
      bool nameValid = _customerNameController.text.trim().isNotEmpty;
      bool emailValid = !_sendToMail || (_sendToMail && _customerEmailController.text.trim().isNotEmpty);
      bool phoneValid = !_sendToPhone || (_sendToPhone && _customerPhoneController.text.trim().isNotEmpty);
      
      setState(() {
        _isButtonEnabled = nameValid && emailValid && phoneValid;
      });
    }
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
    // Remover os listeners antes de descartar os controladores
    _customerNameController.removeListener(_updateButtonState);
    _customerEmailController.removeListener(_updateButtonState);
    _customerPhoneController.removeListener(_updateButtonState);
    
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

    // Validações adicionais específicas para os campos condicionais
    // Verificar se o telefone está preenchido quando SMS estiver ativado
    if (_sendToPhone && _customerPhoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Telefone é obrigatório para entrega por SMS.';
      });
      return;
    }
    
    if (_sendToMail && _customerEmailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Email é obrigatório para entrega por email.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Se o método de pagamento for cartão, primeiro processa pelo terminal MyPOS
      if (_selectedPaymentMethod == 'card') {
        try {
          // Mostrar mensagem que estamos processando pagamento
          Fluttertoast.showToast(
            msg: 'Processando pagamento com cartão...',
            gravity: ToastGravity.CENTER,
            backgroundColor: const Color(0xFF28BADF),
            textColor: Colors.white,
            fontSize: 16.0
          );
          
          // Obter valor total do carrinho
          final totalPrice = _cartService.totalPrice;
          
          // Processar pagamento com MyPOS
          final paymentResponse = await MyPos.makePayment(
            amount: totalPrice,
            currency: MyPosCurrency.eur,
            reference: DateTime.now().millisecondsSinceEpoch.toString(),
          );
          
          // Verificar se pagamento foi bem-sucedido
          if (paymentResponse != PaymentResponse.success) {
            // Se falhou, exibir erro e cancelar processo de checkout
            setState(() {
              _isProcessing = false;
              _errorMessage = 'Pagamento com cartão cancelado ou recusado.';
            });
            
            Fluttertoast.showToast(
              msg: 'Pagamento cancelado ou recusado',
              gravity: ToastGravity.CENTER,
              backgroundColor: const Color(0xFFF36A30),
              textColor: Colors.white,
              fontSize: 16.0
            );
            
            return;
          }
          
          // Se chegou aqui, pagamento foi bem-sucedido - informar ao usuário
          Fluttertoast.showToast(
            msg: 'Pagamento com cartão aprovado! Criando pedido...',
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
          );
        } catch (e) {
          // Capturar erros do terminal MyPOS
          POS2DebugHelper.logError('Erro ao processar pagamento com MyPOS', error: e);
          
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Erro no terminal de pagamento: $e';
          });
          
          Fluttertoast.showToast(
            msg: 'Erro ao processar pagamento: $e',
            gravity: ToastGravity.CENTER,
            backgroundColor: const Color(0xFFF36A30),
            textColor: Colors.white,
            fontSize: 16.0
          );
          
          return;
        }
      }
      
      // O pagamento foi bem-sucedido ou não é cartão, então prosseguir com a criação do pedido
      // Construir o número de telefone completo com código do país
      String? fullPhoneNumber;
      if (_customerPhoneController.text.trim().isNotEmpty && _dialCode != null) {
        fullPhoneNumber = '$_dialCode${_customerPhoneController.text.trim()}';
      }
      
      final result = await _cartService.checkout(
        paymentMethod: _selectedPaymentMethod,
        customerName: _customerNameController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerPhone: fullPhoneNumber ?? _customerPhoneController.text.trim(),
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
        // Log do resultado para debug
        POS2DebugHelper.log('Resultado do checkout: ${jsonEncode(result)}');
        
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
              const Text('Detalhes do Pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Tentar obter número da order de várias fontes possíveis
              Text('Número: #${_getOrderNumber(result)}'),
              Text('Total: €${_getOrderTotal(result)}'),
              const SizedBox(height: 16),
              
              // Ações disponíveis
              const Text('Ações disponíveis:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Botão para imprimir fatura
              OutlinedButton.icon(
                onPressed: () async {
                  // Obtém o ID da ORDER (não invoice_id!) do resultado da API 
                  String? orderIdStr;
                  
                  // Tentar result['data']['order']['id'] primeiro (ID da order na nossa BD)
                  if (result['data'] != null && result['data']['order'] != null) {
                    orderIdStr = result['data']['order']['id']?.toString();
                  }
                  
                  // Fallback para result['order_id'] ou result['id']
                  if (orderIdStr == null || orderIdStr.isEmpty) {
                    orderIdStr = result['order_id']?.toString() ?? result['id']?.toString();
                  }
                  
                  final int? orderId = int.tryParse(orderIdStr ?? '');
                  
                  // Fecha o diálogo
                  Navigator.of(context).pop();
                  
                  // IMPORTANTE: Reset do estado de loading
                  setState(() {
                    _isLoading = false;
                  });
                  
                  // Voltar ao dashboard
                  Navigator.of(context).pop();
                  
                  // Executar refresh do dashboard (limpa carrinho + recarrega)
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                  
                  // Chama o novo serviço de impressão Vendus se o ID da ORDER estiver disponível
                  if (orderId != null) {
                    final printResult = await PrintService.printOrderReceipt(orderId);
                    
                    if (printResult['success'] == true) {
                      Fluttertoast.showToast(
                        msg: printResult['message'] ?? "Fatura impressa com sucesso!",
                        backgroundColor: Colors.green,
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: printResult['message'] ?? "Erro ao imprimir fatura",
                        backgroundColor: Colors.red,
                      );
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: "ID da order não disponível para impressão",
                      backgroundColor: Colors.red,
                    );
                  }
                },
                icon: const Icon(Icons.print),
                label: const Text('Imprimir Fatura'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              
              // Reset do estado de loading
              setState(() {
                _isLoading = false;
              });
              
              // Voltar ao dashboard
              Navigator.of(context).pop();
              
              // Executar refresh do dashboard (limpa carrinho + recarrega)
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
            },
            child: const Text('CONCLUIR'),
          ),
        ],
      ),
    );
  }

  // Método para calcular troco foi simplificado para mobile

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
        padding: const EdgeInsets.all(10),
        children: [
          // Botão de voltar (apenas no passo 2)
          if (_currentStep == 2)
            Row(
              children: [
                _buildBackButton(),
                const Spacer(),
              ],
            ),
          if (_currentStep == 2)
            const SizedBox(height: 10),
          
          // Mostrar o resumo do pedido apenas no passo 1
          if (_currentStep == 1) ...[
            _buildOrderSummary(),
            const SizedBox(height: 8),
          ],
          
          // Conteúdo específico do passo atual
          _currentStep == 1 
          ? _buildStep1Content() 
          : _buildStep2Content(),
          
          // Botão para avançar ou confirmar pagamento
          const SizedBox(height: 10),
          _buildStepButton(),
          const SizedBox(height: 8),
          
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
            // Cabeçalho comentado para interface mobile mais limpa
            /*
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
            */
            
            // Lista de itens (comentado para simplificar a experiência mobile)
            /*
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
            */
            
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
            
            // Email (opcional) - só aparece se a opção de entrega for Email
            if (_sendToMail) 
              Column(
                children: [
                  TextFormField(
                    controller: _customerEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (_sendToMail && (value == null || value.isEmpty)) {
                        return 'Email é obrigatório para entrega por email';
                      }
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
                ],
              ),
            
            // Telefone (opcional) - só aparece se a opção de entrega for SMS
            if (_sendToPhone) 
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: InternationalPhoneNumberInput(
                      onInputChanged: (PhoneNumber number) {
                        setState(() {
                          _countryCode = number.isoCode;
                          _dialCode = number.dialCode; // Armazenar o código de discagem
                          // Manter apenas o número no controller, sem o código do país
                          if (number.phoneNumber != null && number.phoneNumber!.contains(number.dialCode!)) {
                            final phoneWithoutCode = number.phoneNumber!.substring(number.dialCode!.length);
                            if (_customerPhoneController.text != phoneWithoutCode) {
                              _customerPhoneController.text = phoneWithoutCode;
                            }
                          }
                        });
                      },
                      initialValue: PhoneNumber(isoCode: _countryCode),
                      textFieldController: _customerPhoneController,
                      inputBorder: InputBorder.none,
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.DIALOG,
                      ),
                      searchBoxDecoration: InputDecoration(
                        hintText: 'Pesquisar país',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        border: const OutlineInputBorder(),
                      ),
                      formatInput: false, // Não formatar o número digitado
                      ignoreBlank: true, // Não validar se estiver em branco
                      autoValidateMode: AutovalidateMode.disabled, // Desativar validação automática
                      validator: (_) => null, // Sem validação personalizada
                      keyboardType: TextInputType.phone,
                      hintText: 'Número de telefone',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              
            // Nota: Se for QR físico, não precisa de email nem telefone
            if (_physicalQr)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'QR Físico selecionado - Não é necessário email ou telefone',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
              ),
            
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
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, size: 16),
                SizedBox(width: 4),
                Text(
                  'Forma de Pagamento',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Texto de seleção
            Text(
              'Escolha uma opção:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            
            // Apenas as opções principais: cartão e dinheiro
            Row(
              children: [
                Expanded(
                  child: _buildDeliveryOption(
                    'card', 
                    'Cartão', 
                    Icons.credit_card, 
                    _selectedPaymentMethod == 'card',
                    (value) => setState(() => _selectedPaymentMethod = 'card')
                  ),
                ),
                Expanded(
                  child: _buildDeliveryOption(
                    'cash', 
                    'Dinheiro', 
                    Icons.payments,
                    _selectedPaymentMethod == 'cash',
                    (value) => setState(() => _selectedPaymentMethod = 'cash')
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Seção de opções adicionais
  Widget _buildOptionsSection() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.delivery_dining, size: 16),
                SizedBox(width: 4),
                Text(
                  'Forma de Entrega',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Texto de seleção
            Text(
              'Escolha uma opção:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            
            // Opções de entrega em formato de rádio (simplificado para mobile)
            Row(
              children: [
                Expanded(
                  child: _buildDeliveryOption('sms', 'SMS', Icons.sms, 
                    _sendToPhone, 
                    (value) {
                      setState(() {
                        _sendToPhone = value;
                        if (value) {
                          _sendToMail = false;
                          _physicalQr = false;
                        }
                      });
                    }),
                ),
                Expanded(
                  child: _buildDeliveryOption('email', 'Email', Icons.email,
                    _sendToMail, 
                    (value) {
                      setState(() {
                        _sendToMail = value;
                        if (value) {
                          _sendToPhone = false;
                          _physicalQr = false;
                        }
                      });
                    }),
                ),
                Expanded(
                  child: _buildDeliveryOption('qr', 'QR Físico', Icons.qr_code,
                    _physicalQr, 
                    (value) {
                      setState(() {
                        _physicalQr = value;
                        if (value) {
                          _sendToMail = false;
                          _sendToPhone = false;
                        }
                      });
                    }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para criar opção de entrega em formato de rádio
  Widget _buildDeliveryOption(String id, String label, IconData icon, bool isSelected, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withAlpha(26) : null,  // 0.1 aproximadamente convertido para alpha (255 * 0.1 ≈ 26)
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            // Substituímos o Radio por um ícone visível apenas quando selecionado
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // Opções de switch simplificadas para interface mobile
  
  // Conteúdo do Passo 1: Opções de entrega e pagamento
  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Opções de entrega
        _buildOptionsSection(),
        const SizedBox(height: 8),
        
        // Opções de pagamento
        _buildPaymentSection(),
      ],
    );
  }

  // Conteúdo do Passo 2: Dados do cliente
  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumo compacto das seleções e valor total
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.blue, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Resumo do Pedido',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 16),
                // Total - formato simples
                Text(
                  'Total: ${_cartService.totalPrice.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                    color: Theme.of(context).primaryColor
                  ),
                ),
                const SizedBox(height: 6),
                // Forma de Entrega
                Row(
                  children: [
                    const Text('Entrega:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(
                      _sendToPhone ? Icons.sms : 
                      _sendToMail ? Icons.email : 
                      _physicalQr ? Icons.qr_code : Icons.help,
                      size: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _sendToPhone ? 'SMS' : 
                      _sendToMail ? 'Email' : 
                      _physicalQr ? 'QR Físico' : '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Forma de Pagamento
                Row(
                  children: [
                    const Text('Pagamento:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(
                      _selectedPaymentMethod == 'card' ? Icons.credit_card : 
                      _selectedPaymentMethod == 'cash' ? Icons.payments : 
                      Icons.payment,
                      size: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedPaymentMethod == 'card' ? 'Cartão' : 
                      _selectedPaymentMethod == 'cash' ? 'Dinheiro' : 
                      'Outro',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Dados do cliente
        _buildCustomerSection(),
      ],
    );
  }
  
  // Botão para avançar entre passos ou finalizar
  Widget _buildStepButton() {
    // Verificar se o botão deve estar habilitado no passo 2
    bool isButtonDisabled = _isProcessing || 
        (_currentStep == 2 && !_isButtonEnabled);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isButtonDisabled
          ? null 
          : () {
              if (_currentStep == 1) {
                // Verificar se opções de entrega e pagamento foram selecionadas
                if ((_sendToPhone || _sendToMail || _physicalQr) && 
                    (_selectedPaymentMethod.isNotEmpty)) {
                  setState(() {
                    _currentStep = 2;
                    _errorMessage = null;
                    // Atualizar estado do botão ao mudar para o passo 2
                    _updateButtonState();
                  });
                } else {
                  // Mostrar mensagem de erro se alguma opção não foi selecionada
                  setState(() {
                    _errorMessage = 'Por favor, selecione uma forma de entrega e uma forma de pagamento.';
                  });
                }
              } else {
                // No passo 2, validar o formulário e processar o pagamento
                if (_formKey.currentState?.validate() ?? false) {
                  // Verificar se os campos obrigatórios estão preenchidos
                  bool isValid = _validateRequiredFields();
                  if (isValid) {
                    _processCheckout();
                  }
                }
              }
            },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: isButtonDisabled
            ? Colors.grey.shade300
            : _currentStep == 1 
              ? Colors.blue 
              : Theme.of(context).primaryColor,
          foregroundColor: isButtonDisabled ? Colors.grey.shade700 : Colors.white,
        ),
        child: _isProcessing
          ? const SizedBox(
              height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _currentStep == 1 
                  ? const Icon(Icons.arrow_forward) 
                  : const Icon(Icons.check_circle),
                const SizedBox(width: 8),
                Text(
                  _currentStep == 1 ? 'Avançar' : 'Confirmar Pagamento',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
      ),
    );
  }

  // Botão para voltar ao passo anterior (mostrado apenas no passo 2)
  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _currentStep = 1;
          _errorMessage = null; // Limpar mensagens de erro ao voltar
        });
      },
      icon: const Icon(Icons.arrow_back),
      label: const Text('Voltar às opções'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
  
  // Métodos auxiliares para extrair dados da order
  String _getOrderNumber(Map<String, dynamic> result) {
    // Log para debug
    POS2DebugHelper.log('Tentando extrair número da order de: ${result.keys.toList()}');
    
    // 1. Tentar result['order'] primeiro
    if (result['order'] != null) {
      final order = result['order'];
      POS2DebugHelper.log('Dados da order encontrados: ${order.keys.toList()}');
      
      final referenceNumber = order['reference_number']?.toString() ?? 
                             order['id']?.toString() ?? 
                             order['order_number']?.toString() ??
                             order['order_id']?.toString();
      
      if (referenceNumber != null && referenceNumber != 'null') {
        return referenceNumber;
      }
    }
    
    // 2. Tentar result['data']['order']
    if (result['data'] != null && result['data']['order'] != null) {
      final order = result['data']['order'];
      POS2DebugHelper.log('Dados da order em data encontrados: ${order.keys.toList()}');
      
      final referenceNumber = order['reference_number']?.toString() ?? 
                             order['id']?.toString() ?? 
                             order['order_number']?.toString() ??
                             order['order_id']?.toString();
                             
      if (referenceNumber != null && referenceNumber != 'null') {
        return referenceNumber;
      }
    }
    
    // 3. Tentar result['data']['id'] diretamente
    if (result['data'] != null && result['data']['id'] != null) {
      return result['data']['id'].toString();
    }
    
    // 4. Fallback: usar timestamp como número de referência única
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    POS2DebugHelper.log('Usando timestamp como fallback: $timestamp');
    return timestamp.substring(7); // Últimos 6 dígitos do timestamp
  }
  
  String _getOrderTotal(Map<String, dynamic> result) {
    // Tentar obter o total da order
    if (result['order'] != null && result['order']['total'] != null) {
      return result['order']['total'].toStringAsFixed(2);
    }
    
    if (result['data'] != null && result['data']['order'] != null && result['data']['order']['total'] != null) {
      return result['data']['order']['total'].toStringAsFixed(2);
    }
    
    // Fallback para o valor do carrinho
    return _cartService.totalPrice.toStringAsFixed(2);
  }

  // Método para validar campos obrigatórios antes de processar o pagamento
  bool _validateRequiredFields() {
    // O nome do cliente é sempre obrigatório
    if (_customerNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Nome do cliente é obrigatório.';
      });
      return false;
    }
    
    // Validar campos específicos com base na opção de entrega
    if (_sendToPhone && _customerPhoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Telefone é obrigatório quando a entrega é por SMS.';
      });
      return false;
    }
    
    if (_sendToMail && _customerEmailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Email é obrigatório quando a entrega é por email.';
      });
      return false;
    }
    
    // Se chegou aqui, todos os campos obrigatórios estão preenchidos
    _errorMessage = null;
    return true;
  }
}