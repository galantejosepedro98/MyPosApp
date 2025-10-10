import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';
import '../services/pos2_cart_service.dart';
import '../models/pos2_event.dart';
import '../models/pos2_product.dart';
import '../widgets/universal_scanner.dart';
import 'pos2_checkout_view.dart';

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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Definindo o índice inicial como 0 (Produtos)
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
      _syncCartWithUI();
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
  
  // Sincroniza o UI com o estado atual do carrinho
  void _syncCartWithUI() {
    final cartService = POS2CartService.instance;
    final items = cartService.items;
    
    // Limpar quantidades atuais
    _cartQuantities.clear();
    
    // Atualizar quantidades com base nos itens do carrinho
    for (final item in items) {
      final itemData = item['item'];
      final type = itemData['type'] as String?;
      int? id;
      
      if (type == 'ticket' && itemData['ticket_id'] != null) {
        id = itemData['ticket_id'] as int?;
      } else if (type == 'extra' && itemData['extra_id'] != null) {
        id = itemData['extra_id'] as int?;
      }
      
      if (id != null) {
        final quantity = item['quantity'] as int? ?? 0;
        if (quantity > 0) {
          _cartQuantities[id] = quantity;
        }
      }
    }
    
    // Atualizar UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _posName = 'BilheteiraFsc'; // Nome fixo do ponto de venda
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
      
      // Sincronizar o estado do carrinho com a UI
      _syncCartWithUI();
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
      bottomNavigationBar: _selectedEvent != null ? _buildPersistentCartBar() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Removido o ícone de ponto de venda
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
          // Adicionar botões de ação no canto superior direito
          if (_selectedEvent != null) ...[
            // Botão de pesquisa
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(),
              tooltip: 'Pesquisar',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            // Botão de atualizar
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _refreshEventData(),
              tooltip: 'Atualizar',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            // Menu de opções (3 pontos)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showOptionsMenu(),
              tooltip: 'Menu',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduzido o padding vertical
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, // Reduzido de 50 para 40
                                height: 40, // Reduzido de 50 para 40
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.celebration,
                                  color: Color(0xFF667eea),
                                  size: 20, // Adicionado tamanho reduzido
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
                                    // Descrição do evento removida para simplificar a interface
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
                  _buildProductsTab(), // Agora é a primeira aba (padrão)
                  _buildScannerTab(),
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
            icon: Icon(Icons.shopping_basket),
            text: 'Produtos',
          ),
          Tab(
            icon: Icon(Icons.qr_code_scanner),
            text: 'Scanner',
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return UniversalScanner(
      selectedEventId: _selectedEvent?.id,
      onScanResult: (ticketData) {
        POS2DebugHelper.log('Bilhete escaneado: ${ticketData['product_name'] ?? ticketData['name']}');
      },
      onAddToCart: (item) {
        // Item adicionado ao carrinho - sem notificação
        String itemName = item['name'] ?? 'Item';
        // Apenas atualizamos o estado sem mostrar notificação
        
        POS2DebugHelper.log('Item do scanner adicionado ao carrinho: $itemName');
      },
    );
  }

  Widget _buildProductsTab() {
    // Se não houver bilhetes nem extras, mostre mensagem
    if (_tickets.isEmpty && _extras.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_basket,
        title: 'Nenhum produto disponível',
        subtitle: 'Não há bilhetes ou extras para este evento',
      );
    }

    // Combinar bilhetes e extras em uma única lista
    final List<Widget> productCards = [];
    
      // Adicionar um título para os bilhetes se houver bilhetes disponíveis
    if (_tickets.isNotEmpty) {
      productCards.add(
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.confirmation_number, size: 18, color: Color(0xFF48BB78)),
              SizedBox(width: 6),
              Text(
                'Bilhetes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      );      // Adicionar os cards de bilhetes
      for (int i = 0; i < _tickets.length; i++) {
        final ticket = _tickets[i];
        // Último bilhete terá margem maior se houver extras
        final margin = (i == _tickets.length - 1 && _extras.isNotEmpty) 
            ? const EdgeInsets.only(bottom: 24)
            : const EdgeInsets.only(bottom: 12);
            
        productCards.add(
          _buildProductCardWithQuantity(
            id: ticket.id,
            name: ticket.name,
            price: ticket.price,
            stock: ticket.quantity,
            icon: Icons.confirmation_number,
            color: const Color(0xFF48BB78),
            type: 'ticket',
            margin: margin,
          ),
        );
      }
    }
    
    // O espaçamento entre seções agora é gerenciado pelo margin dos cards
    
    // Adicionar um título para os extras se houver extras disponíveis
    if (_extras.isNotEmpty) {
      productCards.add(
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.restaurant, size: 18, color: Color(0xFFED8936)),
              SizedBox(width: 6),
              Text(
                'Extras',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      );
      
      // Adicionar os cards de extras
      for (int i = 0; i < _extras.length; i++) {
        final extra = _extras[i];
        final margin = (i == _extras.length - 1)
            ? const EdgeInsets.only(bottom: 16)
            : const EdgeInsets.only(bottom: 12);
            
        productCards.add(
          _buildProductCardWithQuantity(
            id: extra.id,
            name: extra.name,
            price: extra.price,
            stock: extra.quantity,
            icon: Icons.restaurant,
            color: const Color(0xFFED8936),
            type: 'extra',
            margin: margin,
          ),
        );
      }
    }
    
    // Retornar a lista completa de produtos
    return ListView(
      padding: const EdgeInsets.all(20),
      children: productCards,
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
    EdgeInsets margin = const EdgeInsets.only(bottom: 12),
  }) {
    final quantity = _cartQuantities[id] ?? 0;
    final isAvailable = stock > 0 || stock == 999; // 999 = ilimitado (extras)
    
    return Container(
      margin: margin,
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
    final cartService = POS2CartService.instance;
    
    // Se a quantidade for zero, remover do carrinho
    if (newQuantity <= 0) {
      final itemId = type == 'ticket' ? 'ticket_$id' : 'extra_$id';
      cartService.removeItem(itemId);
      setState(() {
        _cartQuantities.remove(id);
      });
      return;
    }
    
    // Obter a quantidade atual no carrinho
    final currentQuantity = _cartQuantities[id] ?? 0;
    
    // Se for um aumento de quantidade
    if (newQuantity > currentQuantity) {
      // Encontrar o item para adicionar ao carrinho
      if (type == 'ticket') {
        // Procurar o bilhete na lista de bilhetes
        POS2Product? ticket;
        try {
          ticket = _tickets.firstWhere((t) => t.id == id);
        } catch (e) {
          POS2DebugHelper.logError('Bilhete não encontrado', error: e);
          return;
        }
        
        // Adicionar ao carrinho
        cartService.addTicket({
          'id': id,
          'product_name': ticket.name,
          'price': ticket.price,
          'event_id': _selectedEvent?.id,
        });
      } else if (type == 'extra') {
        // Procurar o extra na lista de extras
        POS2Extra? extra;
        try {
          extra = _extras.firstWhere((e) => e.id == id);
        } catch (e) {
          POS2DebugHelper.logError('Extra não encontrado', error: e);
          return;
        }
        
        // Adicionar ao carrinho
        cartService.addExtra({
          'id': id,
          'name': extra.name,
          'price': extra.price,
          'event_id': _selectedEvent?.id,
        });
      }
    }
    
    // Atualizar estado local
    setState(() {
      _cartQuantities[id] = newQuantity;
    });
  }
  
  // Nova barra persistente do carrinho
  Widget _buildPersistentCartBar() {
    final cartService = POS2CartService.instance;
    final totalItems = cartService.totalItems;
    final totalPrice = cartService.totalPrice;
    
    if (totalItems == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone do carrinho com badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart, size: 28),
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$totalItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Valor total
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalItems ${totalItems == 1 ? 'item' : 'itens'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '€${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Botão Pagar
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const POS2CheckoutView()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.payments),
            label: const Text('PAGAR'),
          ),
        ],
      ),
    );
  }

  // Método para mostrar o diálogo de pesquisa
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pesquisar Produtos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Digite o nome do produto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (value) {
                // Implementação da pesquisa em tempo real poderia ser adicionada aqui
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Os resultados aparecerão conforme você digita',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  // Método para atualizar os dados do evento
  Future<void> _refreshEventData() async {
    if (_selectedEvent == null) return;
    
    setState(() => _loading = true);
    
    try {
      // Limpar o cache de requisições para forçar novos dados
      await POS2ApiService.clearCache();
      
      POS2DebugHelper.log('Recarregando produtos e extras do evento ${_selectedEvent!.id}...');
      
      // Recarregar bilhetes e extras em paralelo com parâmetros para evitar cache
      final timestamp = DateTime.now();
      final results = await Future.wait([
        POS2ApiService.getTickets(_selectedEvent!.id, forceRefresh: true, timestamp: timestamp),
        POS2ApiService.getExtras(_selectedEvent!.id, forceRefresh: true, timestamp: timestamp),
      ]);

      // Sempre limpar o carrinho ao atualizar
      final cartService = POS2CartService.instance;
      cartService.clearCart();
      
      // Limpar quantidades locais
      setState(() {
        _cartQuantities.clear();
      });
      
      POS2DebugHelper.log('Carrinho limpo durante atualização');

      setState(() {
        // Limpar listas anteriores
        _tickets = [];
        _extras = [];
        
        if (results[0]['success']) {
          final ticketData = results[0]['data'] as List;
          _tickets = ticketData
              .map((json) {
                try {
                  return POS2Product.fromJson(json);
                } catch (e) {
                  POS2DebugHelper.logError('Erro ao converter ticket', error: e);
                  return null;
                }
              })
              .where((ticket) => ticket != null)
              .cast<POS2Product>()
              .toList();
          
          POS2DebugHelper.log('${_tickets.length} bilhetes carregados');
        }
        
        if (results[1]['success']) {
          final extraData = results[1]['data'] as List;
          _extras = extraData
              .map((json) {
                try {
                  return POS2Extra.fromJson(json);
                } catch (e) {
                  POS2DebugHelper.logError('Erro ao converter extra', error: e);
                  return null;
                }
              })
              .where((extra) => extra != null)
              .cast<POS2Extra>()
              .toList();
          
          POS2DebugHelper.log('${_extras.length} extras carregados');
        }
      });

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produtos atualizados e carrinho limpo!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      _showError('Erro ao atualizar produtos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Método para mostrar o menu de opções
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Color(0xFF667eea)),
                title: const Text('Trocar Evento'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedEvent = null;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF667eea)),
                title: const Text('Histórico de Vendas'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar navegação para o histórico de vendas
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidade em desenvolvimento'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF667eea)),
                title: const Text('Log out'),
                onTap: () async {
                  Navigator.pop(context);
                  // Confirmar logout
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmação'),
                      content: const Text('Tem certeza que deseja sair?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('CANCELAR'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('SAIR'),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (shouldLogout && context.mounted) {
                    // Limpar dados da sessão
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('token');
                    await prefs.remove('user');
                    
                    // Navegar para a tela de login
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
