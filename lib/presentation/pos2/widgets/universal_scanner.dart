import 'package:flutter/material.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';
import '../models/pos2_product.dart';

class UniversalScanner extends StatefulWidget {
  final Function(Map<String, dynamic>)? onScanResult;
  final Function(Map<String, dynamic>)? onAddToCart;
  final int? selectedEventId;

  const UniversalScanner({
    super.key,
    this.onScanResult,
    this.onAddToCart,
    this.selectedEventId,
  });

  @override
  State<UniversalScanner> createState() => _UniversalScannerState();
}

class _UniversalScannerState extends State<UniversalScanner> {
  final TextEditingController _scanController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _scannedTicket;
  List<POS2Extra> _availableExtras = [];
  bool _showExtras = false;

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  /// Obtém o status visual do bilhete baseado no estado
  Map<String, dynamic> _getTicketStatus(Map<String, dynamic>? ticket) {
    if (ticket == null || ticket.containsKey('error')) {
      return {
        'color': Colors.red,
        'text': 'Inválido',
        'icon': Icons.error,
      };
    }
    
    final status = ticket['status'] ?? -1;
    final active = ticket['active'] ?? 0;
    final type = ticket['type'] ?? '';
    
    // Verde: status=0 e active=1 (bilhete válido/ativo)
    if (status == 0 && active == 1) {
      return {
        'color': Colors.green,
        'text': 'Válido',
        'icon': Icons.check_circle,
      };
    }
    
    // Amarelo: status=0, active=0 e type=paid_invite (convite pago para ativar)
    if (status == 0 && active == 0 && type == 'paid_invite') {
      return {
        'color': Colors.orange,
        'text': 'Convite Pago',
        'icon': Icons.access_time,
      };
    }
    
    // Vermelho: status=1 (bilhete usado/inválido)
    if (status == 1) {
      return {
        'color': Colors.red,
        'text': 'Já Usado',
        'icon': Icons.block,
      };
    }
    
    // Default: outros casos
    return {
      'color': Colors.grey,
      'text': 'Inativo',
      'icon': Icons.help,
    };
  }

  /// Processar scan do código QR
  Future<void> _handleScanSubmit() async {
    final code = _scanController.text.trim();
    if (code.isEmpty || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      POS2DebugHelper.log('Escaneando código: $code');
      
      // Buscar informações do bilhete
      final result = await POS2ApiService.getTicketByCode(code);
      
      if (result['success']) {
        final ticketData = result['data'];
        setState(() => _scannedTicket = ticketData);
        
        // Buscar extras disponíveis para este evento
        if (ticketData['event_id'] != null) {
          await _fetchEventExtras(ticketData['event_id']);
        }
        
        // Callback para o componente pai
        if (widget.onScanResult != null) {
          widget.onScanResult!(ticketData);
        }
        
        // Limpar o campo após sucesso
        _scanController.clear();
        
        POS2DebugHelper.log('Bilhete escaneado com sucesso: ${ticketData['product_name']}');
      } else {
        setState(() {
          _scannedTicket = {'error': result['message'] ?? 'Código não encontrado ou inválido'};
        });
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao escanear código', error: e);
      setState(() {
        _scannedTicket = {'error': 'Erro ao processar código'};
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Buscar extras disponíveis para o evento
  Future<void> _fetchEventExtras(int eventId) async {
    try {
      final result = await POS2ApiService.getExtras(eventId);
      if (result['success']) {
        final extrasData = result['data'] as List;
        setState(() {
          _availableExtras = extrasData
              .map((json) => POS2Extra.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar extras do evento', error: e);
      setState(() => _availableExtras = []);
    }
  }

  /// Ativar convite pago
  void _handleActivatePaidInvite() {
    if (_scannedTicket != null && widget.onAddToCart != null) {
      widget.onAddToCart!({
        'id': _scannedTicket!['id'],
        'name': 'Ativação: ${_scannedTicket!['name'] ?? 'Convite Pago'}',
        'price': _scannedTicket!['price'] ?? 0.0,
        'type': 'paid_invite_activation',
        'ticket_id': _scannedTicket!['id'],
      });
      
      setState(() => _scannedTicket = null);
    }
  }

  /// Adicionar extra ao carrinho (será associado ao bilhete no checkout)
  void _handleAddExtraToCart(POS2Extra extra) {
    if (widget.onAddToCart != null && _scannedTicket != null) {
      widget.onAddToCart!({
        'id': extra.id,
        'name': extra.name,
        'price': extra.price,
        'quantity': 1,
        'type': 'extra',
        'ticket_id': _scannedTicket!['id'],
        'metadata': {
          'ticketCode': _scannedTicket!['ticket'],
          'eventId': _scannedTicket!['event_id'],
        },
      });
      
      POS2DebugHelper.log('Extra "${extra.name}" adicionado ao carrinho');
    }
  }
  
  /// Levantar um extra associado a um bilhete
  Future<void> _handleWithdrawExtra(String? ticketCode, dynamic extraId) async {
    if (ticketCode == null || extraId == null || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      POS2DebugHelper.log('Levantando extra $extraId do bilhete $ticketCode');
      
      final result = await POS2ApiService.withdrawExtra(ticketCode, int.parse(extraId.toString()));
      
      if (result['success']) {
        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Extra levantado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Atualizar informações do bilhete para refletir as alterações
        final updatedTicket = await POS2ApiService.getTicketByCode(ticketCode);
        if (updatedTicket['success'] && mounted) {
          setState(() => _scannedTicket = updatedTicket['data']);
        }
      } else {
        // Mostrar mensagem de erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erro ao levantar extra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao levantar extra', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao levantar extra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getTicketStatus(_scannedTicket);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de input do scanner
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scanController,
                  decoration: InputDecoration(
                    hintText: 'Insira ou digitalize o código QR',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enabled: !_isProcessing,
                  autofocus: true,
                  onSubmitted: (_) => _handleScanSubmit(),
                  onChanged: (value) {
                    // Limpar resultado anterior quando começar a digitar
                    if (_scannedTicket != null) {
                      setState(() {
                        _scannedTicket = null;
                        _availableExtras = [];
                        _showExtras = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _scanController.text.trim().isEmpty || _isProcessing 
                    ? null 
                    : _handleScanSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Resultado do scan
          if (_scannedTicket != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status['color'].withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: status['color'], width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header do resultado
                  Row(
                    children: [
                      Icon(
                        status['icon'],
                        color: status['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bilhete ${status['text']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status['color'],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_scannedTicket!.containsKey('error')) ...[
                    const SizedBox(height: 12),
                    Text(
                      _scannedTicket!['error'],
                      style: const TextStyle(color: Colors.red),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    
                    // Informações do bilhete
                    Text(
                      'Bilhete: ${_scannedTicket!['product_name'] ?? 'ID: ${_scannedTicket!['id']}'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Evento: ${_scannedTicket!['event_name'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    
                    if (_scannedTicket!['name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${_scannedTicket!['name']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Mostrar extras já associados ao bilhete
                    if (_scannedTicket!['extras'] != null && _scannedTicket!['extras'] is Map && _scannedTicket!['extras'].isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.fastfood, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Extras no bilhete:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      ...(_scannedTicket!['extras'] as Map).entries.map((entry) {
                        final extra = entry.value;
                        final used = extra['used'] ?? 0;
                        final qty = extra['qty'] ?? 0;
                        final available = qty - used;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        extra['name'] ?? 'Extra',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Disponível: $available/$qty',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (available > 0) ...[
                                  ElevatedButton(
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _handleWithdrawExtra(
                                            _scannedTicket!['ticket'],
                                            extra['id'],
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: _isProcessing
                                        ? const SizedBox(
                                            width: 20, 
                                            height: 20, 
                                            child: CircularProgressIndicator(
                                              color: Colors.black, 
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('LEVANTAR'),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: available > 0 ? Colors.green : Colors.grey,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Disponível: $available',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    
                    // Ações baseadas no status
                    if (status['text'] == 'Convite Pago') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleActivatePaidInvite,
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: const Text('Ativar Convite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    
                    // Mostrar extras disponíveis para adicionar
                    if ((status['text'] == 'Válido' || status['text'] == 'Convite Pago') && 
                        _availableExtras.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Extras disponíveis:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _showExtras = !_showExtras);
                            },
                            child: Text(_showExtras ? 'Ocultar' : 'Ver Extras'),
                          ),
                        ],
                      ),
                      
                      if (_showExtras) ...[
                        const SizedBox(height: 8),
                        ...(_availableExtras.map((extra) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(extra.name),
                            subtitle: Text('€${extra.price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              onPressed: () => _handleAddExtraToCart(extra),
                              icon: const Icon(Icons.add_shopping_cart),
                              color: const Color(0xFF667eea),
                            ),
                          ),
                        ))),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}