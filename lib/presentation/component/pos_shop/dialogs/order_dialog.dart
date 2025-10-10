import 'dart:convert';

import 'package:essenciacompany_mobile/core/cart_service.dart';
import 'package:essenciacompany_mobile/domain/auth_requests.dart';
import 'package:essenciacompany_mobile/domain/shop_requests.dart';
import 'package:essenciacompany_mobile/services/printer_service.dart';

import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/processing_view.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/print_options_dialog.dart';
import 'package:flutter/material.dart';
import 'package:my_pos/my_pos.dart';
import 'package:my_pos/enums/my_pos_currency_enum.dart';
import 'package:my_pos/enums/py_pos_payment_response.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDialog extends StatefulWidget {
  final List<dynamic> products;
  final String? eventId;
  const OrderDialog({super.key, this.products = const [], this.eventId});

  @override
  State<OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<OrderDialog> {
  // _withdraw removed as it's always true and button is hidden
  String _invoice = 'None';
  String _paymentMethod = 'card';
  Map<String, dynamic>? _walletUser;
  bool _isLoadingWalletUser = false;
  List<String> _paymentMethods = [];
  String? _dialCode;
  String? _countryCode;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vatController;  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _vatController = TextEditingController();
    loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await getUser(token: token);
    if (res['success']) {
      try {
        Map<String, dynamic> tmpMethods =
            jsonDecode(res['data']['pos']['payment_methods'])
                as Map<String, dynamic>;
        List<String> paymentMethods =
            tmpMethods.keys.where((item) => tmpMethods[item] == "1").toList();
        setState(() {
          _paymentMethods = paymentMethods;
          _paymentMethod = paymentMethods.first;
        });
      } catch (e) {
        print(e.toString());
      }
    }    // Removed settings check as withdraw is always true
  }
  // Removed _toggleWithdraw as withdraw is always true

  _handleInvoice(String? value) {
    if (value == null) return;
    setState(() {
      _invoice = value;
    });
  }

  _handlePaymentMethod(String? value) {
    if (value == null) return;
    setState(() {
      _paymentMethod = value;
    });
  }

  submitOrder() async {
    final products = widget.products.map((item) {
      return {
        'id': item['item']['id'],
        'quantity': item['quantity'],
        'price': item['item']['price']
      };
    }).toList();

    if (_nameController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Name is required .',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if (_invoice == 'Email' && _emailController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Email is required when invoice is sent to email',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if (_invoice == 'Phone' && _phoneController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Phone is required when invoice is sent to phone',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }    double totalPrice = getOrderTotal();
    
    // Se o método de pagamento for cartão, processa pelo myPOS
    if (_paymentMethod == 'card') {
      try {
        final paymentResponse = await MyPos.makePayment(
          amount: totalPrice,
          currency: MyPosCurrency.eur,
          printMerchantReceipt: true,  // Ativar impressão do recibo myPOS
          printCustomerReceipt: true,  // Ativar impressão do recibo myPOS
          reference: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        if (paymentResponse != PaymentResponse.success) {
          Fluttertoast.showToast(
            msg: 'Payment failed or was cancelled',
            gravity: ToastGravity.CENTER,
            backgroundColor: const Color(0xFFF36A30),
            textColor: Colors.white,
            fontSize: 16.0
          );
          return;
        }
        
        // Show processing view for card payments
        try {
          print("Showing ProcessingView for card payment");
          if (mounted) {
            Navigator.of(context).push(PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => const ProcessingView(
                message: 'Processando pagamento cartão',
              ),
            ));
          }
        } catch (e) {
          print("Error showing ProcessingView for card payment: $e");
          // Show a toast instead if the navigation failed
          Fluttertoast.showToast(
            msg: 'Processando pagamento...',
            gravity: ToastGravity.CENTER,
            backgroundColor: const Color(0xFF28BADF),
            textColor: Colors.white,
            fontSize: 16.0
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error processing card payment: ￼${e.toString()}',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0
        );
        return;
      }
    }
    
    // Processamento para pagamento QR
    if (_paymentMethod == 'qr') {
      try {
        print("Showing ProcessingView for QR payment");
        if (mounted) {
          Navigator.of(context).push(PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const ProcessingView(
              message: 'Processando pagamento QR',
            ),
          ));
        }
      } catch (e) {
        print("Error showing ProcessingView for QR payment: $e");
        // Show a toast instead if the navigation failed
        Fluttertoast.showToast(
          msg: 'Processando pagamento...',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFF28BADF),
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    }

    Map<String, dynamic> orderData = {
      'user_id': _walletUser != null ? _walletUser!['id'] : null,
      'event_id': widget.eventId,
      "extras": products,
      'billing': {
        'name': _nameController.text,
        'email':
            _emailController.text.isNotEmpty ? _emailController.text : null,
        'phone': _phoneController.text.isNotEmpty
            ? '$_dialCode${_phoneController.text}'
            : null,
        'vatNumber':
            _vatController.text.isNotEmpty ? _vatController.text : null,
      },
      "total": totalPrice,
      "subtotal": totalPrice,
      "payment_method": _paymentMethod,
      "send_message": _invoice == "Phone" ? true : false,
      "send_email": _invoice == "Email" ? true : false,
    };
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    final res = await createOrder(orderData, token: token);
    // Imprimir a resposta da API para debug
    print('API Response: [${jsonEncode(res)}');
      if (res['success']) {
      // Guardar os dados necessários para impressão
      final clientName = _nameController.text;
      final clientPhone = _phoneController.text;
      final invoiceUrl = res['data']['invoice_url'];
      final orderId = res['data']['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Obter os dados do POS para impressão
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('user') ?? '{}');
      final posName = user['pos']['name'] ?? 'Essencia Company';
      
      // Criar lista de itens uma vez só
      final receiptItems = widget.products.map((item) => OrderItem(
        name: item['item']['name'] ?? '',
        quantity: item['quantity'] ?? 1,
        price: item['item']['price']?.toString() ?? '0.00'
      )).toList();

        // Mostrar diálogo de opções de impressão
      if (mounted) {
        // Primeiro remove qualquer diálogo existente (como a tela de processamento)
        Navigator.of(context).pop();
        
        // Define função local para imprimir recibos
        Future<void> printLocalReceipts(int count) async {
          try {
            // Mostrar tela de processamento com mensagem de impressão
            if (mounted) {
              Navigator.of(context).push(PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const ProcessingView(
                  message: 'A imprimir...',
                ),
              ));
            }
            
            // Imprime o número solicitado de recibos
            for (int i = 0; i < count; i++) {
              await PrinterService.printCustomReceipt(
                posName: posName,
                userName: clientName,
                orderId: orderId,
                total: totalPrice.toString(),
                items: receiptItems,
                timestamp: clientPhone.isNotEmpty ? clientPhone : null,
                invoiceUrl: invoiceUrl,
              );
              
              // Espera 1 segundo entre impressões se houver mais de uma
              if (i < count - 1) {
                await Future.delayed(const Duration(seconds: 1));
              }
            }
            
            // Volta ao POS após impressão
            if (mounted) {
              CartService().resetCart(); // Limpar carrinho antes de voltar ao POS
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacementNamed('/pos/shop');
            }
          } catch (e) {
            print('Erro ao imprimir recibo: $e');
            // Mostrar mensagem de erro e voltar ao POS
            Fluttertoast.showToast(
              msg: 'Erro na impressão: ${e.toString()}',
              gravity: ToastGravity.CENTER,
              backgroundColor: const Color(0xFFF36A30),
              textColor: Colors.white,
              fontSize: 16.0
            );
            
            if (mounted) {
              CartService().resetCart(); // Limpar carrinho antes de voltar ao POS
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacementNamed('/pos/shop');
            }
          }
        }

        // Mostra o diálogo de opções de impressão (não-cancelável)
        showDialog(
          context: context,
          barrierDismissible: false, // Impede fechar clicando fora
          builder: (context) => PrintOptionsDialog(
            onOptionSelected: (option) async {
              switch (option) {
                case 0: // Não imprimir
                  // Voltar ao POS sem imprimir
                  if (mounted) {
                    CartService().resetCart(); // Limpar carrinho antes de voltar ao POS
                    Navigator.of(context).pushReplacementNamed('/pos/shop');
                  }
                  break;
                case 1: // Imprimir 1 recibo
                  await printLocalReceipts(1);
                  break;
                case 2: // Imprimir 2 recibos
                  await printLocalReceipts(2);
                  break;
              }
            },
          ),
        );
      }
    } else {
      Fluttertoast.showToast(
          msg: res['message'] ?? 'Error creating order',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  _makeQrPayment(code) async {
    Navigator.pop(context);
    setState(() {
      _isLoadingWalletUser = true;
    });
    final res = await getUserFromQr(qrCode: code);
    if (res['success']) {
      final userData = res['data'];
      setState(() {
        _walletUser = userData;
        _nameController.text = userData['name'] ?? _nameController.text;
        _emailController.text = userData['email'] ?? _emailController.text;
        _phoneController.text =
            userData['contact_number'] ?? _phoneController.text;
        _vatController.text = userData['vatNumber'] ?? _vatController.text;
      });
    }
    setState(() {
      _isLoadingWalletUser = false;
    });
  }

  _resetQr() {
    setState(() {
      _walletUser = null;
      _nameController.text = '';
      _emailController.text = '';
      _phoneController.text = '';
      _vatController.text = '';
    });
  }

  getOrderTotal() {
    double totalPrice = 0;
    for (var element in widget.products) {
      totalPrice += element['itemTotal'];
    }
    // Arredondar para 2 casas decimais para evitar erros de precisão
    return double.parse(totalPrice.toStringAsFixed(2));
  }  @override
  Widget build(BuildContext context) {
    // Withdraw functionality removed as it's always enabled
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: SafeArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Finalizar Venda',
                  style: TextStyle(fontSize: 18),
                ),                const SizedBox(height: 20),
                if (_paymentMethod == 'qr' &&
                    _walletUser != null &&
                    !_isLoadingWalletUser)
                  GestureDetector(
                    onTap: _resetQr,
                    child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(
                                color: const Color(0xFFF2500B), width: 4)),
                        child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Reset',
                            style: TextStyle(
                                color: Color(0xFFF2500B), fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        )),
                  )
                else if (_paymentMethod == 'qr' && !_isLoadingWalletUser)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ScannerView(onScan: _makeQrPayment);
                      }));
                    },
                    child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(
                                color: const Color(0xFFF2500B), width: 4)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                size: 32, color: Color(0xFFF2500B)),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Pagar com QR Code',
                              style: TextStyle(
                                  color: Color(0xFFF2500B), fontSize: 20),
                              textAlign: TextAlign.center,
                            )
                          ],
                        )),
                  ),
                if (_paymentMethod == 'qr' &&
                    _walletUser != null &&
                    !_isLoadingWalletUser)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        if (_walletUser != null &&
                            _walletUser!['name'] != null &&
                            _walletUser!['name']!.isNotEmpty)
                          Text(
                            '${_walletUser!['name']}',
                            style: const TextStyle(
                                color: Color(0xFFF2500B), fontSize: 30),
                            textAlign: TextAlign.start,
                          ),
                        /* if (_walletUser != null &&
                            _walletUser!['email'] != null &&
                            _walletUser!['email']!.isNotEmpty)
                          Text(
                            '${_walletUser!['email']}',
                            style: const TextStyle(
                                color: Color(0xFF676767), fontSize: 16),
                            textAlign: TextAlign.start,
                          ), */
                        if (_walletUser != null &&
                            _walletUser!['balance'] != null)
                          Text(
                            'Є${_walletUser!['balance']}',
                            style: const TextStyle(
                                color: Color(0xFFF2500B), fontSize: 26),
                            textAlign: TextAlign.start,
                          ),
                      ])
                else if (_isLoadingWalletUser)
                  const Text(
                    'Loading...',
                    style: TextStyle(color: Color(0xFFF2500B), fontSize: 26),
                    textAlign: TextAlign.start,
                  ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xff28badf),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nome',
                      hintStyle: TextStyle(
                        color: Colors.grey[750],
                        fontSize: 20,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xff28badf),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.grey[750],
                        fontSize: 20,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xff28badf),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InternationalPhoneNumberInput(
                      onInputChanged: (data) {
                        setState(() {
                          _dialCode = data.dialCode;
                          _countryCode = data.isoCode;
                        });
                      },
                      initialValue: PhoneNumber(isoCode: _countryCode ?? 'PT'),
                      textFieldController: _phoneController,
                      inputBorder: InputBorder.none,
                      selectorTextStyle: const TextStyle(
                        // color: Colors.white,
                        fontSize: 18,
                      ),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.DIALOG,
                      ),
                      searchBoxDecoration: InputDecoration(
                        hintText: 'Pesquisar',
                        hintStyle: TextStyle(
                          color: Colors.grey[750],
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                      ),
                      hintText: 'Telemovel',
                    )),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xff28badf),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _vatController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Contribuinte',
                      hintStyle: TextStyle(
                        color: Colors.grey[750],
                        fontSize: 20,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Metodo de Pagamento',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color(0xff28badf),
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 10),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xff28badf),
                                      width: 4)),
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                isExpanded: true,
                                isDense: true,
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_downward_sharp,
                                  size: 18,
                                ),
                                items: _paymentMethods.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: _handlePaymentMethod,
                                hint: const Text(
                                  'Cash',
                                ),
                                value: _paymentMethod,
                              ))),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Fatura',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color(0xffec6031),
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 10),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xffec6031),
                                      width: 4)),
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                isExpanded: true,
                                isDense: true,
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_downward_sharp,
                                  size: 18,
                                ),
                                items: <String>['None', 'Phone', 'Email']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: _handleInvoice,
                                hint: const Text(
                                  'None',
                                ),
                                value: _invoice,
                              ))),
                        ],
                      ),
                    )
                  ],
                ),                const SizedBox(
                  height: 10,
                ),
                // Withdraw is always active, button removed
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Total: ${getOrderTotal().toStringAsFixed(2)}€',
                  style:
                      const TextStyle(color: Color(0xFFF2500B), fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: submitOrder,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xff28badf),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Concluir Venda',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                )
              ],
            )),
          )),
    );
  }
}
