import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';

class POS2SalesHistoryView extends StatefulWidget {
  const POS2SalesHistoryView({super.key});

  @override
  State<POS2SalesHistoryView> createState() => _POS2SalesHistoryViewState();
}

class _POS2SalesHistoryViewState extends State<POS2SalesHistoryView> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        _showError('Sessão expirada. Por favor, faça login novamente.');
        return;
      }

      final result = await POS2ApiService.getOrders(token);
      
      if (result['success']) {
        setState(() {
          _orders = result['data'] ?? [];
          _loading = false;
        });
      } else {
        _showError(result['message'] ?? 'Erro ao carregar histórico');
        setState(() => _loading = false);
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao carregar histórico de vendas', error: e);
      _showError('Erro ao carregar histórico: $e');
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

  List<dynamic> get _filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    
    return _orders.where((order) {
      final query = _searchQuery.toLowerCase();
      
      // ID da ordem
      final orderId = order['id']?.toString().toLowerCase() ?? '';
      
      // Informações do cliente (dentro do objeto 'user')
      final user = order['user'] as Map<String, dynamic>?;
      final customerName = (user?['name']?.toString() ?? '').toLowerCase();
      final customerEmail = (user?['email']?.toString() ?? '').toLowerCase();
      final customerPhone = (user?['phone']?.toString() ?? '').toLowerCase();
      
      // VAT/NIF (pode estar em diferentes campos)
      final vatNumber = (order['vat_number']?.toString() ?? order['nif']?.toString() ?? '').toLowerCase();
      
      // Pesquisar em todos os campos relevantes
      return orderId.contains(query) ||
             customerName.contains(query) ||
             customerEmail.contains(query) ||
             customerPhone.contains(query) ||
             vatNumber.contains(query);
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '€0.00';
    
    try {
      final amount = double.parse(value.toString());
      return '€${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '€0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Histórico de Vendas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildOrdersList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF2A2A2A),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Pesquisar por ID, Nome, Email, Telefone ou NIF...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF3A3A3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Nenhuma venda registada',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Nenhum resultado encontrado',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadOrders,
        color: const Color(0xFF667eea),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderCard(order, index);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final orderId = order['id']?.toString() ?? 'N/A';
    final total = _formatCurrency(order['total']);
    final date = _formatDate(order['created_at']);
    
    // Informações do cliente (dentro do objeto 'user')
    final user = order['user'] as Map<String, dynamic>?;
    final customerName = user?['name']?.toString() ?? '';
    final customerEmail = user?['email']?.toString() ?? '';
    final customerPhone = user?['phone']?.toString() ?? '';
    final vatNumber = order['vat_number']?.toString() ?? order['nif']?.toString() ?? '';
    
    // Flags de envio e alert
    final sendMessage = order['send_message'] == 1 || order['send_message'] == true;
    final sendEmail = order['send_email'] == 1 || order['send_email'] == true;
    final isMarked = order['alert'] == 'marked';
    
    // Verificar se é bilhete físico (QR Code físico)
    final isPhysicalTicket = !sendMessage && !sendEmail;
    
    // Determinar qual contato mostrar baseado nas flags de envio
    String contactInfo = '';
    IconData contactIcon = Icons.person;
    
    if (isPhysicalTicket) {
      // Bilhete físico - não mostrar contacto
      contactInfo = '';
    } else if (sendMessage && customerPhone.isNotEmpty && customerPhone != 'N/A') {
      // Se SMS foi enviado, mostrar telemóvel
      contactInfo = customerPhone;
      contactIcon = Icons.phone;
    } else if (sendEmail && customerEmail.isNotEmpty && customerEmail != 'N/A') {
      // Se Email foi enviado, mostrar email
      contactInfo = customerEmail;
      contactIcon = Icons.email;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: ID + Total + Botão Opções
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Venda #$orderId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        total,
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                        onPressed: () => _showOrderOptions(order),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Badge "Marcado" se tiver problema sinalizado
              if (isMarked)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFFF5252),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        color: Color(0xFFFF5252),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Marcado',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Se NÃO estiver marcado, mostrar informações normais
              if (!isMarked) ...[
                // Nome do cliente
                if (customerName.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey.shade500, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          customerName,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                
                if (customerName.isNotEmpty) const SizedBox(height: 6),
                
                // Badge "Bilhete Físico" ou Email/Phone
                if (isPhysicalTicket)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFF9800),
                        width: 1,
                      ),
                    ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code,
                        color: Color(0xFFFF9800),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Bilhete Físico',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (contactInfo.isNotEmpty)
                Row(
                  children: [
                    Icon(contactIcon, color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contactInfo,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              if (isPhysicalTicket || contactInfo.isNotEmpty) const SizedBox(height: 6),
              
              // VAT Number (se existir)
              if (vatNumber.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.badge, color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'NIF: $vatNumber',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              
              if (vatNumber.isNotEmpty) const SizedBox(height: 8),
              ], // Fim do if (!isMarked)
              
              // Data (sempre visível)
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey.shade500, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final user = order['user'] as Map<String, dynamic>?;
    final customerName = user?['name']?.toString() ?? 'N/A';
    final customerEmail = user?['email']?.toString() ?? 'N/A';
    final customerPhone = user?['phone']?.toString() ?? 'N/A';
    
    // Flags de envio
    final sendMessage = order['send_message'] == 1 || order['send_message'] == true;
    final sendEmail = order['send_email'] == 1 || order['send_email'] == true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Detalhes da Venda #${order['id']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Badge "Marcado" se tiver problema sinalizado
                if (order['alert'] == 'marked') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF5252),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag,
                          color: Color(0xFFFF5252),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Problema Sinalizado',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order['note'] != null && order['note'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notes, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order['note'].toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                ],
                
                // Informações do cliente
                const Text(
                  'Cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Nome', customerName),
                
                // Badge "Bilhete Físico" ou mostrar contactos
                if (sendMessage || sendEmail) ...[
                  // Email com indicador de envio
                  if (customerEmail != 'N/A')
                    _buildDetailRow(
                      'Email',
                      customerEmail,
                      highlight: sendEmail,
                      icon: sendEmail ? Icons.check_circle : null,
                    ),
                  
                  // Telefone com indicador de envio
                  if (customerPhone != 'N/A')
                    _buildDetailRow(
                      'Telefone',
                      customerPhone,
                      highlight: sendMessage,
                      icon: sendMessage ? Icons.check_circle : null,
                    ),
                ] else ...[
                  // Bilhete Físico
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: Color(0xFFFF9800),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bilhete Físico (QR Code)',
                            style: TextStyle(
                              color: Color(0xFFFF9800),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                
                // Informações da venda
                const Text(
                  'Venda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('ID', order['id']?.toString() ?? 'N/A'),
                _buildDetailRow('Total', _formatCurrency(order['total'])),
                _buildDetailRow('Data', _formatDate(order['created_at'])),
                _buildDetailRow('Método Pagamento', order['payment_method']?.toString() ?? 'N/A'),
                
                // Bilhetes
                if (order['tickets'] != null && order['tickets'] is List && (order['tickets'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Bilhetes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(order['tickets'] as List).map((ticket) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '• ${ticket['product_name'] ?? 'Bilhete'} (ID: ${ticket['id']})',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ],
                
                // Extras
                if (order['extras'] != null && order['extras'] is List && (order['extras'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Extras',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(order['extras'] as List).map((extra) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '• ${extra['name'] ?? 'Extra'} (${extra['quantity'] ?? 1}x)',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ],
                
                const SizedBox(height: 20),
                
                // Botão de fechar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
            );
          },
        );
      },
    );
  }

  void _showOrderOptions(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                'Opções do Pedido #${order['id']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Atualizar Dados
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                title: const Text(
                  'Atualizar Dados',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  'Editar email ou telefone do cliente',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleUpdateContact(order);
                },
              ),
              
              const Divider(color: Colors.grey),
              
              // Reenviar Email
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF667eea)),
                title: const Text(
                  'Reenviar Email',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  'Enviar bilhetes por email novamente',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleResendEmail(order);
                },
              ),
              
              const Divider(color: Colors.grey),
              
              // Reenviar SMS
              ListTile(
                leading: const Icon(Icons.sms, color: Color(0xFF4CAF50)),
                title: const Text(
                  'Reenviar SMS',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  'Enviar bilhetes por SMS novamente',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleResendSMS(order);
                },
              ),
              
              const Divider(color: Colors.grey),
              
              // Sinalizar Problema
              ListTile(
                leading: const Icon(Icons.flag, color: Color(0xFFFF9800)),
                title: const Text(
                  'Sinalizar Problema',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  'Marcar esta venda com um problema',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleMarkProblem(order);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Botão Cancelar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Future<void> _handleUpdateContact(Map<String, dynamic> order) async {
    final user = order['user'] as Map<String, dynamic>?;
    final currentEmail = user?['email']?.toString() ?? '';
    final currentPhone = user?['phone']?.toString() ?? '';
    
    final emailController = TextEditingController(text: currentEmail != 'N/A' ? currentEmail : '');
    final phoneController = TextEditingController(text: currentPhone != 'N/A' ? currentPhone : '');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Atualizar Dados',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Atualize os dados de contacto do cliente:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              // Campo Email
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF667eea)),
                  hintText: 'email@exemplo.com',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF667eea)),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Campo Telefone
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                  hintText: '912345678',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty || phoneController.text.isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha pelo menos um campo'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Atualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token == null) {
          _showError('Sessão expirada');
          emailController.dispose();
          phoneController.dispose();
          return;
        }

        final result = await POS2ApiService.updateContact(
          token,
          order['id'],
          email: emailController.text.isNotEmpty ? emailController.text : null,
          phone: phoneController.text.isNotEmpty ? phoneController.text : null,
        );
        
        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Dados atualizados!'),
                backgroundColor: Colors.blue,
              ),
            );
            
            // Recarregar lista e aguardar
            await _loadOrders();
            
            // Buscar a ordem atualizada da lista
            final updatedOrder = _orders.firstWhere(
              (o) => o['id'] == order['id'],
              orElse: () => order,
            );
            
            // Reabrir o modal de opções com dados atualizados
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _showOrderOptions(updatedOrder);
            });
          } else {
            _showError(result['message'] ?? 'Erro ao atualizar dados');
          }
        }
      } catch (e) {
        _showError('Erro ao atualizar dados: $e');
      }
    }
    
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _handleResendEmail(Map<String, dynamic> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        _showError('Sessão expirada');
        return;
      }

      // Mostrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reenviando email...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await POS2ApiService.resendEmail(token, order['id']);
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Email enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders(); // Recarregar lista
        } else {
          _showError(result['message'] ?? 'Erro ao enviar email');
        }
      }
    } catch (e) {
      _showError('Erro ao enviar email: $e');
    }
  }

  Future<void> _handleResendSMS(Map<String, dynamic> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        _showError('Sessão expirada');
        return;
      }

      // Mostrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reenviando SMS...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await POS2ApiService.resendSMS(token, order['id']);
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'SMS enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders(); // Recarregar lista
        } else {
          _showError(result['message'] ?? 'Erro ao enviar SMS');
        }
      }
    } catch (e) {
      _showError('Erro ao enviar SMS: $e');
    }
  }

  Future<void> _handleMarkProblem(Map<String, dynamic> order) async {
    final noteController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Sinalizar Problema',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Exemplo: Cliente não recebeu o bilhete...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF667eea)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.length >= 10) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Descrição deve ter pelo menos 10 caracteres'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            child: const Text('Sinalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && noteController.text.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token == null) {
          _showError('Sessão expirada');
          return;
        }

        final result = await POS2ApiService.markOrder(
          token,
          order['id'],
          noteController.text,
        );
        
        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Problema sinalizado!'),
                backgroundColor: Colors.orange,
              ),
            );
            _loadOrders(); // Recarregar lista
          } else {
            _showError(result['message'] ?? 'Erro ao sinalizar problema');
          }
        }
      } catch (e) {
        _showError('Erro ao sinalizar problema: $e');
      }
    }
    
    noteController.dispose();
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: highlight ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                  size: 16,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: TextStyle(
                  color: highlight ? const Color(0xFF4CAF50) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
