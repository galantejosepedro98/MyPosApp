import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';
import '../models/pos2_event.dart';
import '../models/pos2_product.dart';
import '../models/pos2_cart.dart';
import '../providers/pos2_cart_provider.dart';
import '../widgets/universal_scanner.dart';

class POS2ModernDashboard extends StatefulWidget {
  const POS2ModernDashboard({super.key});

  @override
  State<POS2ModernDashboard> createState() => _POS2ModernDashboardState();
}

class _POS2ModernDashboardState extends State<POS2ModernDashboard>
    with TickerProviderStateMixin {
  
  // Estado da aplicação
  List<POS2Event> _events = [];
  List<POS2Product> _tickets = [];
  List<POS2Extra> _extras = [];
  POS2Event? _selectedEvent;
  String _posName = 'POS 2.0';
  bool _loading = true;
  
  // Quantidades no carrinho (id do produto/extra -> quantidade)
  final Map<int, int> _cartQuantities = {};
  
  // Controllers para animações
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      setState(() => _loading = true);
      await _loadUserData();
      await _fetchEvents();
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user') ?? '{}');
    setState(() {
      _posName = user['name'] ?? 'POS 2.0';
    });
  }

  Future<void> _fetchEvents() async {
    final result = await POS2ApiService.getEvents();
    if (result['success']) {
      setState(() {
        _events = result['data'] as List<POS2Event>;
      });
    } else {
      _showError('Erro ao carregar eventos: ${result['message']}');
    }
  }

  Future<void> _selectEvent(POS2Event event) async {
    setState(() {
      _selectedEvent = event;
      _loading = true;
    });

    try {
      // Carregar bilhetes e extras em paralelo
      final results = await Future.wait([
        POS2ApiService.getTickets(event.id),
        POS2ApiService.getExtras(event.id),
      ]);

      setState(() {
        if (results[0]['success']) {
          final ticketData = results[0]['data'] as List;
          POS2DebugHelper.log('Raw ticket data: $ticketData');
          _tickets = ticketData
              .map((json) {
                try {
                  return POS2Product.fromJson(json);
                } catch (e) {
                  POS2DebugHelper.logError('Erro ao converter ticket', error: e);
                  POS2DebugHelper.log('Ticket JSON problemático: $json');
                  return null;
                }
              })
              .where((ticket) => ticket != null)
              .cast<POS2Product>()
              .toList();
        }
        
        if (results[1]['success']) {
          final extraData = results[1]['data'] as List;
          POS2DebugHelper.log('Raw extra data: $extraData');
          _extras = extraData
              .map((json) {
                try {
                  return POS2Extra.fromJson(json);
                } catch (e) {
                  POS2DebugHelper.logError('Erro ao converter extra', error: e);
                  POS2DebugHelper.log('Extra JSON problemático: $json');
                  return null;
                }
              })
              .where((extra) => extra != null)
              .cast<POS2Extra>()
              .toList();
        }
      });

      POS2DebugHelper.log('Evento ${event.name}: ${_tickets.length} bilhetes, ${_extras.length} extras');
    } catch (e) {
      _showError('Erro ao carregar produtos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_selectedEvent == null) _buildEventSelector(),
              if (_selectedEvent != null) _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _posName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedEvent?.name ?? 'Selecione um evento',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Consumer<POS2CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    if (_loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Selecione um Evento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectEvent(event),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.celebration,
                                  color: Color(0xFF667eea),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    if (event.description != null && event.description!.isNotEmpty)
                                      Text(
                                        event.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScannerTab(),
                  _buildTicketsTab(),
                  _buildExtrasTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF667eea),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.qr_code_scanner),
            text: 'Scanner',
          ),
          Tab(
            icon: Icon(Icons.confirmation_number),
            text: 'Bilhetes',
          ),
          Tab(
            icon: Icon(Icons.restaurant),
            text: 'Extras',
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return UniversalScanner(
      selectedEventId: _selectedEvent?.id,
      onScanResult: (ticketData) {
        POS2DebugHelper.log('Bilhete escaneado: ${ticketData['product_name']}');
      },
      onAddToCart: (item) {
        // Adicionar item escaneado ao carrinho usando o provider
        final cartProvider = Provider.of<POS2CartProvider>(context, listen: false);
        
        if (item['type'] == 'paid_invite_activation') {
          // Criar produto fictício para ativação de convite
          final activationProduct = POS2Product(
            id: item['id'],
            name: item['name'],
            price: item['price'].toDouble(),
            quantity: 1,
            eventId: _selectedEvent?.id ?? 0,
            active: true,
          );
          
          cartProvider.addItem(
            type: POS2CartItemType.ticket,
            product: activationProduct,
            quantity: 1,
            metadata: {'type': 'paid_invite_activation', 'ticket_id': item['ticket_id']},
          );
        } else if (item['type'] == 'extra') {
          final extra = POS2Extra(
            id: item['id'],
            name: item['name'],
            price: item['price'].toDouble(),
            eventId: item['metadata']['eventId'],
            active: true,
          );
          
          cartProvider.addItem(
            type: POS2CartItemType.extra,
            product: extra,
            quantity: item['quantity'] ?? 1,
            metadata: {'ticket_id': item['ticket_id'], 'scanned_from_qr': true},
          );
        }
        
        POS2DebugHelper.log('Item do scanner adicionado ao carrinho: ${item['name']}');
      },
    );
  }

  Widget _buildTicketsTab() {
    if (_tickets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.confirmation_number,
        title: 'Nenhum bilhete disponível',
        subtitle: 'Não há bilhetes para este evento',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _buildProductCardWithQuantity(
          id: ticket.id,
          name: ticket.name,
          price: ticket.price,
          stock: ticket.quantity,
          icon: Icons.confirmation_number,
          color: const Color(0xFF48BB78),
          type: 'ticket',
        );
      },
    );
  }

  Widget _buildExtrasTab() {
    if (_extras.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant,
        title: 'Nenhum extra disponível',
        subtitle: 'Não há extras para este evento',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _extras.length,
      itemBuilder: (context, index) {
        final extra = _extras[index];
        return _buildProductCardWithQuantity(
          id: extra.id,
          name: extra.name,
          price: extra.price,
          stock: extra.quantity,
          icon: Icons.restaurant,
          color: const Color(0xFFED8936),
          type: 'extra',
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCardWithQuantity({
    required int id,
    required String name,
    required double price,
    required int stock,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    final quantity = _cartQuantities[id] ?? 0;
    final isAvailable = stock > 0 || stock == 999; // 999 = ilimitado (extras)
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock == 999 ? 'Stock: Ilimitado' : 'Stock: $stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                // Botões + e - com quantidade no meio
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão -
                    Material(
                      color: quantity > 0 ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: quantity > 0 ? () => _updateQuantity(id, name, quantity - 1, type) : null,
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: quantity > 0 ? color : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quantidade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: quantity > 0 ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: quantity > 0 ? color : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão +
                    Material(
                      color: isAvailable ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: isAvailable ? () => _updateQuantity(id, name, quantity + 1, type) : null,
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: isAvailable ? color : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(int id, String name, int newQuantity, String type) {
    setState(() {
      if (newQuantity <= 0) {
        _cartQuantities.remove(id);
      } else {
        _cartQuantities[id] = newQuantity;
      }
    });
  }
}
