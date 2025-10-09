import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';
import '../models/pos2_event.dart';
import '../providers/pos2_cart_provider.dart';
import '../models/pos2_cart.dart';

class POS2DashboardView extends StatefulWidget {
  const POS2DashboardView({super.key});

  @override
  State<POS2DashboardView> createState() => _POS2DashboardViewState();
}

class _POS2DashboardViewState extends State<POS2DashboardView> {
  List<POS2Event> _events = [];
  List<dynamic> _products = [];
  POS2Event? _selectedEvent;
  String _posName = 'POS 2.0';
  bool _loading = true;
  bool _showEventSelector = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      setState(() => _loading = true);
      
      // Carregar dados do usuário
      await loadUserData();
      
      // Carregar eventos
      await fetchEvents();
      
    } catch (e) {
      POS2DebugHelper.logError('Erro ao carregar dados iniciais', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user') ?? '{}');
    if (mounted) {
      setState(() {
        _posName = user['pos']['name'] ?? 'POS 2.0';
      });
    }
  }

  Future<void> fetchEvents() async {
    final result = await POS2ApiService.getEvents();
    
    if (result['success']) {
      if (mounted) {
        setState(() {
          _events = result['data'] as List<POS2Event>;
          _showEventSelector = _events.isNotEmpty;
        });
      }
    } else {
      POS2DebugHelper.logError('Erro ao carregar eventos: ${result['message']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar eventos: ${result['message']}')),
        );
      }
    }
  }

  Future<void> selectEvent(POS2Event event) async {
    if (mounted) {
      setState(() {
        _selectedEvent = event;
        _showEventSelector = false;
        _loading = true;
      });
    }
    
    POS2DebugHelper.log('Evento selecionado: ${event.name} (ID: ${event.id})');
    
    try {
      // Carregar produtos/extras do evento selecionado
      await fetchProducts(event.id);
    } catch (e) {
      POS2DebugHelper.logError('Erro ao carregar dados do evento', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> fetchProducts(int eventId) async {
    POS2DebugHelper.log('Carregando bilhetes e extras para evento $eventId');
    
    try {
      // Carregar bilhetes e extras separadamente (como no website POS2)
      final [ticketsResult, extrasResult] = await Future.wait([
        POS2ApiService.getTickets(eventId),
        POS2ApiService.getExtras(eventId),
      ]);
      
      List<dynamic> allProducts = [];
      
      if (ticketsResult['success']) {
        final tickets = ticketsResult['data'] ?? [];
        allProducts.addAll(tickets);
        POS2DebugHelper.log('${tickets.length} bilhete(s) carregado(s)');
      }
      
      if (extrasResult['success']) {
        final extras = extrasResult['data'] ?? [];
        allProducts.addAll(extras);
        POS2DebugHelper.log('${extras.length} extra(s) carregado(s)');
      }
      
      if (mounted) {
        setState(() {
          _products = allProducts;
        });
      }
      
      POS2DebugHelper.log('Total: ${allProducts.length} item(s) carregado(s)');
      
    } catch (e) {
      POS2DebugHelper.logError('Erro ao carregar produtos e extras', error: e);
    }
  }



  void changeEvent() {
    if (mounted) {
      setState(() {
        _selectedEvent = null;
        _showEventSelector = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POS 2.0 - $_posName'),
            if (_selectedEvent != null)
              Text(
                _selectedEvent!.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedEvent != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: changeEvent,
              tooltip: 'Trocar Evento',
            ),
          if (_selectedEvent != null)
            Consumer<POS2CartProvider>(
              builder: (context, cart, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: _showCart,
                      tooltip: 'Carrinho',
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
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
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner QR em desenvolvimento...')),
              );
            },
            tooltip: 'Scanner QR',
          ),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _showEventSelector
          ? _buildEventSelector()
          : _selectedEvent == null
            ? const Center(child: Text('Selecione um evento para continuar'))
            : _buildMainContent(),
    );
  }

  Widget _buildEventSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione um Evento',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          if (_events.isEmpty)
            const Center(
              child: Text('Nenhum evento disponível'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return GestureDetector(
                    onTap: () {
                      POS2DebugHelper.log('Card clicado: ${event.name}');
                      selectEvent(event);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Nenhum produto disponível',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Este evento não tem produtos/extras configurados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Produtos e Extras',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Chip(
                label: Text('${_products.length} items'),
                backgroundColor: Colors.blue[100],
              ),
            ],
          ),
        ),
        
        // Lista de produtos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(product['name'] ?? 'Produto'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product['description'] != null)
                        Text(product['description']),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '€${(product['price'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Stock: Ilimitado',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _addToCart(product),
                    child: const Text('Adicionar'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addToCart(dynamic product) {
    final cartProvider = Provider.of<POS2CartProvider>(context, listen: false);
    
    cartProvider.addItem(
      type: POS2CartItemType.extra, // Produtos são tratados como extras no sistema
      product: product,
      quantity: 1,
      name: product['name'] ?? 'Produto',
      price: (product['price'] ?? 0).toDouble(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} adicionado ao carrinho!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver Carrinho',
          textColor: Colors.white,
          onPressed: () => _showCart(),
        ),
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Carrinho de Compras',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Cart content
              Expanded(
                child: Consumer<POS2CartProvider>(
                  builder: (context, cart, child) {
                    if (cart.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Carrinho vazio',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adicione produtos para continuar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: cart.items.length,
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    item.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('€${item.totalPrice.toStringAsFixed(2)}'),
                                  trailing: SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => cart.updateQuantity(
                                            item.id,
                                            item.quantity - 1,
                                          ),
                                          icon: const Icon(Icons.remove, size: 18),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          onPressed: () => cart.updateQuantity(
                                            item.id,
                                            item.quantity + 1,
                                          ),
                                          icon: const Icon(Icons.add, size: 18),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Footer com total e botão de checkout
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Column(
                            children: [
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
                                    '€${cart.totals.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: cart.isEmpty ? null : () {
                                    Navigator.pop(context);
                                    _proceedToCheckout();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text(
                                    'Finalizar Compra',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToCheckout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checkout em desenvolvimento...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}