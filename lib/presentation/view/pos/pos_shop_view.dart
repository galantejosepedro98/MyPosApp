import 'dart:convert';

import 'package:essenciacompany_mobile/core/cart_service.dart';
import 'package:essenciacompany_mobile/domain/shop_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/custom_app_bar.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/order_dialog.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/product_item.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosShopView extends StatefulWidget {
  const PosShopView({super.key});

  @override
  State<PosShopView> createState() => _PosShopViewState();
}

class _PosShopViewState extends State<PosShopView> {
  List<dynamic> _eventsList = [];
  List<dynamic> _categoriesList = [];
  List<dynamic> _productsList = [];
  String? _selectedEvent;
  String? _selectedCategory;
  String? _pos;
  bool _showSearchbar = false;
  final TextEditingController _searchController = TextEditingController();

  toggleSearchBar() {
    setState(() {
      _showSearchbar = !_showSearchbar;
    });
  }

  // Use singleton corretamente
  final CartService cartService = CartService();

  @override
  void initState() {
    super.initState();
    checkPOS2Permissions();
    loadData();
    _searchController.addListener(() {
      refetchExtras();
    });
  }

  Future<void> checkPOS2Permissions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('user') ?? '{}');
      
      // DEBUG: Imprimir estrutura completa do user
      print('=== DEBUG POS2 PERMISSIONS ===');
      print('User completo: ${jsonEncode(user)}');
      print('User POS: ${user['pos']}');
      if (user['pos'] != null) {
        print('POS permission (singular): ${user['pos']['permission']}'); // CORRIGIDO
        print('POS name: ${user['pos']['name']}');
      }
      print('===============================');
      
      final permissions = user['pos']?['permission']; // CORRIGIDO: singular
      
      // Verificar se tem permissão para tickets (vários formatos possíveis)
      final hasTickets = permissions != null && 
          (permissions['tickets'] == true || 
           permissions['tickets'] == 1 ||
           permissions['tickets'] == '1' ||  // STRING "1"
           permissions['Tickets'] == true ||
           permissions['Tickets'] == 1 ||
           permissions['Tickets'] == '1');   // STRING "1"
      
      print('Has tickets permission: $hasTickets');
      
      if (hasTickets) {
        // Se tem permissão para tickets, mostrar opção POS2
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPOS2Option();
        });
      } else {
        print('POS2: Este POS não tem permissão para bilhetes - usando sistema atual');
      }
    } catch (e) {
      print('Erro ao verificar permissões POS2: $e');
    }
  }

  void _showPOS2Option() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sistema de Vendas'),
          content: const Text(
            'Você tem acesso ao novo POS 2.0 com funcionalidades avançadas de bilhetes e extras. Qual sistema deseja usar?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Continuar com sistema atual (só extras)
              },
              child: const Text('Sistema Atual\n(Só Extras)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar para POS2
                Navigator.pushReplacementNamed(context, '/pos2/dashboard');
              },
              child: const Text('POS 2.0\n(Avançado)'),
            ),
          ],
        );
      },
    );
  }

  loadData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(_prefs.getString('user') ?? '{}');
    setState(() {
      _productsList = [];
      _pos = user['pos']['name'] ?? 'Essencia Company';
    });
    final token = _prefs.getString('token');
    final events = await getEvents(token: token);
    if (events['success']) {
      setState(() {
        _eventsList = events['data'];
      });
      try {
        setState(() {
          _selectedEvent = '${events['data'][0]['id']}';
        });
      } catch (err) {
        print(err.toString());
      }
    }

    // Filter categories with extras
    final categories = await getExtrasCategories(token: token);
    if (categories['success']) {
      List<dynamic> filteredCategories = [];
      for (var category in categories['data']) {
        final extras = await getProducts(
          token: token,
          eventId: _selectedEvent,
          categoryId: '${category['id']}',
        );
        if (extras['success'] && extras['data'].isNotEmpty) {
          filteredCategories.add(category);
        }
      }

      setState(() {
        _categoriesList = filteredCategories;
      });
    }

    // Load products
    final res = await getProducts(
        token: token, eventId: _selectedEvent, query: _searchController.text);
    if (res['success']) {
      setState(() {
        _productsList = res['data'];
      });
    }
  }

  refetchExtras() async {
    // cartService.resetCart(); // Removido para não limpar o carrinho ao atualizar extras
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final token = _prefs.getString('token');
    final res = await getProducts(
        token: token,
        eventId: _selectedEvent,
        categoryId: _selectedCategory,
        query: _searchController.text);
    if (res['success']) {
      setState(() {
        _productsList = res['data'];
      });
    }
  }

  refetchCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final categories = await getExtrasCategories(
      token: token,
      eventId: _selectedEvent,
    );

    if (categories['success']) {
      List<dynamic> filteredCategories = [];
      for (var category in categories['data']) {
        // Check if there are extras for the category
        final extras = await getProducts(
          token: token,
          eventId: _selectedEvent,
          categoryId: '${category['id']}',
        );
        if (extras['success'] && extras['data'].isNotEmpty) {
          filteredCategories.add(category);
        }
      }

      setState(() {
        _categoriesList = filteredCategories;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar.showPosAppBar(context, title: '$_pos',
            onRefresh: () {
          // Limpar o carrinho e recarregar a página
          cartService.resetCart();
          Navigator.pushReplacementNamed(context, '/pos/shop');
        },
            showSearchbar: _showSearchbar,
            toggleSearchbar: toggleSearchBar,
            searchController: _searchController),
        body: SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black45,
                                offset: Offset(0, 2),
                                blurRadius: 5)
                          ]),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          isExpanded: true,
                          isDense: true,
                          value: _selectedEvent,
                          items: _eventsList.isNotEmpty
                              ? _eventsList
                                  .map((eventItem) => DropdownMenuItem(
                                      value: '${eventItem['id']}',
                                      onTap: () {
                                        setState(() {
                                          _selectedEvent = '${eventItem['id']}';
                                        });
                                        refetchExtras();
                                        refetchCategories();
                                      },
                                      child: Text(eventItem['name'])))
                                  .toList()
                              : [
                                  DropdownMenuItem(
                                      child: const Text('None'), onTap: () {})
                                ],
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categoriesList.map((category) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_selectedCategory ==
                                    category['id'].toString()) {
                                  _selectedCategory = null;
                                } else {
                                  _selectedCategory = '${category['id']}';
                                }
                              });
                              refetchExtras();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _selectedCategory ==
                                        category['id'].toString()
                                    ? Colors.black
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedCategory ==
                                        category['id'].toString()
                                    ? [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.yellow.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.indigo.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.5),
                                          offset: const Offset(0, 0),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                              ),
                              child: Text(
                                category['name'],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedCategory ==
                                            category['id'].toString()
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < _productsList.length; i++)
                            if ((double.tryParse(
                                        '${_productsList[i]['price']}') ??
                                    0.00) >
                                0)                              ProductItem(
                                index: i,
                                name: _productsList[i]['name'] ?? '',
                                price: double.tryParse(
                                        '${_productsList[i]['price']}') ??
                                    0.00,                                quantity: (() {
                                  try {
                                    final item = cartService.getItem(_productsList[i]['id']);
                                    return item['quantity'] ?? 0;
                                  } catch (e) {
                                    print("Error getting quantity: $e");
                                    return 0;
                                  }
                                })(),addItem: () {
                                  print('Adding item from PosShopView: ${_productsList[i]['name']}');
                                  try {
                                    final result = cartService.addItem(_productsList[i]);
                                    print('Add result: $result, cartService items: ${cartService.items.length}');
                                    if (mounted) {
                                      setState(() {
                                        print('setState called, rebuilding UI for ${_productsList[i]['name']}, items in cart: ${cartService.items.length}');
                                      });
                                    }
                                  } catch (e) {
                                    print('ERROR in addItem callback: $e');
                                    // Force rebuild UI even if there was an error
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                },                                updateQuantity: (qty) {
                                  print('Updating quantity: $qty for ${_productsList[i]['name']}');
                                  try {
                                    final result = cartService.updateQuantity(
                                        _productsList[i], qty);
                                    print('Update result: $result, new quantity: ${cartService.getItem(_productsList[i]['id'])['quantity'] ?? 0}');
                                    if (mounted) {
                                      setState(() {
                                        print('setState called after quantity update, items in cart: ${cartService.items.length}');
                                      });
                                    }
                                  } catch (e) {
                                    print('ERROR in updateQuantity callback: $e');
                                    // Force rebuild UI even if there was an error
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                },
                              ),
                        ],
                      ),
                    )),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 20),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xff737373),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 5)
                            ]),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                size: 40,
                                color: Colors.white,
                              ),
                              Text(
                                '${cartService.totalItems} Produtos',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900),
                              ),
                              // SizedBox.expand(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${cartService.totalPrice.toStringAsFixed(2)}€',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (cartService.items.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg: 'Cart is empty',
                                            gravity: ToastGravity.TOP,
                                            backgroundColor:
                                                const Color(0xFFF36A30),
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                        return;
                                      }
                                      showDialog(
                                          context: context,
                                          builder: (context) => OrderDialog(
                                                products: cartService.items,
                                                eventId: _selectedEvent,
                                              ));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff28badf),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'PAGAR',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ]))
                  ],
                ))));
  }
}
