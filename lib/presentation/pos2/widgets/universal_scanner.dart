import 'package:flutter/material.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';
import '../services/pos2_cart_service.dart';
// 'package:flutter/services.dart' is unnecessary here (Material exports what we need)

/// UniversalScanner - Scanner universal para códigos QR e bilhetes
/// Replica o comportamento do componente web para o Flutter
/// Permite validar bilhetes, gerenciar extras e adicionar itens ao carrinho
class UniversalScanner extends StatefulWidget {
  /// Callback quando um código é escaneado com sucesso
  final Function(Map<String, dynamic>)? onScanResult;
  
  /// Callback para adicionar um item ao carrinho
  final Function(Map<String, dynamic>)? onAddToCart;
  
  /// ID do evento selecionado (opcional)
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
  // Controladores e estados
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  bool _isProcessing = false;
  Map<String, dynamic>? _scannedTicket;
  List<dynamic> _availableExtras = [];
  bool _showExtras = false;

  @override
  void initState() {
    super.initState();
    // Foco automático no campo de entrada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  /// Obtém o status visual do bilhete baseado no estado
  Map<String, dynamic> _getTicketStatus(Map<String, dynamic>? ticket) {
    if (ticket == null || ticket.containsKey('error')) {
      return {
        'color': Colors.red,
        'text': 'Inválido',
        'icon': Icons.error,
        'textColor': Colors.white,
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
        'textColor': Colors.white,
      };
    }
    
    // Amarelo: status=0, active=0 e type=paid_invite (convite pago para ativar)
    if (status == 0 && active == 0 && type == 'paid_invite') {
      return {
        'color': Colors.amber,
        'text': 'Convite Pago',
        'icon': Icons.access_time,
        'textColor': Colors.black,
      };
    }
    
    // Vermelho: status=1 (bilhete usado/inválido)
    if (status == 1) {
      return {
        'color': Colors.red,
        'text': 'Já Usado',
        'icon': Icons.block,
        'textColor': Colors.white,
      };
    }
    
    // Default: outros casos
    return {
      'color': Colors.grey,
      'text': 'Inativo',
      'icon': Icons.help,
      'textColor': Colors.white,
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
        
        // Verificar se há extras no bilhete e formatar corretamente
        if (ticketData['extras'] != null) {
          POS2DebugHelper.log('Extras encontrados no bilhete: ${ticketData['extras']}');
        } else {
          POS2DebugHelper.log('Nenhum extra encontrado no bilhete.');
        }
        
        // Callback para o componente pai
        if (widget.onScanResult != null) {
          widget.onScanResult!(ticketData);
        }
        
        // Limpar o campo após sucesso
        _scanController.clear();
        
        POS2DebugHelper.log('Bilhete escaneado com sucesso: ${ticketData['product_name'] ?? ticketData['id']}');
      } else {
        setState(() {
          _scannedTicket = {'error': result['message'] ?? 'Código não encontrado ou inválido'};
        });
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao escanear código', error: e);
      if (mounted) {
        setState(() {
            _scannedTicket = {'error': 'Erro ao processar código: $e'};
          });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Voltar a focar o campo de entrada após processar
        _scanFocusNode.requestFocus();
      }
    }
  }

  /// Buscar extras disponíveis para o evento
  Future<void> _fetchEventExtras(int eventId) async {
    try {
      final result = await POS2ApiService.getExtras(eventId);
      if (result['success']) {
        setState(() {
          _availableExtras = result['data'] as List;
        });
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao buscar extras do evento', error: e);
      setState(() => _availableExtras = []);
    }
  }

  /// Ativar convite pago
  void _handleActivatePaidInvite() {
    if (_scannedTicket != null) {
      final cartService = POS2CartService.instance;
      final success = cartService.addPaidInviteActivation(_scannedTicket!);
      
      if (success && widget.onAddToCart != null) {
        widget.onAddToCart!(_scannedTicket!);
      }
      
      // Reset do scanner após adicionar ao carrinho
      setState(() {
        _scannedTicket = null;
        _showExtras = false;
      });
      
      // Voltar a focar o campo de entrada
      _scanFocusNode.requestFocus();
    }
  }

  /// Adicionar extra ao carrinho (será associado ao bilhete no checkout)
  void _handleAddExtraToCart(dynamic extra) {
    if (_scannedTicket != null) {
      final cartService = POS2CartService.instance;
      final success = cartService.addExtra(
        extra,
        ticketCode: _scannedTicket!['ticket'],
        ticketId: _scannedTicket!['id'],
        eventId: _scannedTicket!['event_id'],
      );
      
      if (success && widget.onAddToCart != null) {
        widget.onAddToCart!(extra);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extra "${extra['name']}" adicionado ao carrinho'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      POS2DebugHelper.log('Extra "${extra['name']}" adicionado ao carrinho');
    }
  }
  
  /// Levantar um extra associado a um bilhete
  Future<void> _handleWithdrawExtra(dynamic extra) async {
    if (_scannedTicket == null || _isProcessing) return;
    
    final ticketCode = _scannedTicket!['ticket'];
    final extraId = extra['id'];
    
    if (ticketCode == null || extraId == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      POS2DebugHelper.log('Levantando extra $extraId do bilhete $ticketCode');
      
      // Chamar API com o código do bilhete e ID do extra
      
      final result = await POS2ApiService.withdrawExtra(ticketCode, extraId);
      
      if (result['success']) {
        // Atualizar o bilhete com os novos dados
        if (result['data']?['ticket']?['extras'] != null) {
          setState(() {
            _scannedTicket = {
              ..._scannedTicket!,
              'extras': result['data']['ticket']['extras'],
            };
          });
        } else {
          // Fallback: atualizar localmente se o servidor não retornar extras atualizados
          // Garantir que 'used' seja tratado como número
          final int currentUsed = extra['used'] ?? 0;
          final newUsedQuantity = currentUsed + 1;
          
          final updatedExtra = {
            ...extra,
            'used': newUsedQuantity,
          };
          
          if (_scannedTicket!['extras'] is List) {
            final List updatedExtras = List.from(_scannedTicket!['extras']);
            final index = updatedExtras.indexWhere((e) => e['id'] == extra['id']);
            if (index >= 0) {
              updatedExtras[index] = updatedExtra;
            }
            
            setState(() {
              _scannedTicket = {
                ..._scannedTicket!,
                'extras': updatedExtras,
              };
            });
          } else if (_scannedTicket!['extras'] is Map) {
            final Map updatedExtras = Map.from(_scannedTicket!['extras']);
            
            // Encontrar a chave correta no mapa
            String? targetKey;
            updatedExtras.forEach((key, value) {
              if (value['id'] == extra['id']) {
                targetKey = key;
              }
            });
            
            if (targetKey != null) {
              updatedExtras[targetKey!] = updatedExtra;
            }
            
            setState(() {
              _scannedTicket = {
                ..._scannedTicket!,
                'extras': updatedExtras,
              };
            });
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extra "${extra['name']}" levantado com sucesso!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        POS2DebugHelper.log('✅ Extra "${extra['name']}" levantado com sucesso!');
      } else {
        throw Exception(result['message'] ?? 'Erro ao levantar extra');
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
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getTicketStatus(_scannedTicket);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de entrada do scanner
          _buildScannerInput(),
          
          // Resultado do scan
          if (_scannedTicket != null)
            _buildScanResult(status),
        ],
      ),
    );
  }

  /// Constrói o campo de entrada do scanner
  Widget _buildScannerInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _scanController,
              focusNode: _scanFocusNode,
              decoration: InputDecoration(
                hintText: 'Insira ou digitalize o código QR',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              ),
              style: const TextStyle(fontSize: 16.0),
              onSubmitted: (_) => _handleScanSubmit(),
              onChanged: (value) {
                // Limpar resultado anterior quando começar a digitar novo código
                if (_scannedTicket != null) {
                  setState(() {
                    _scannedTicket = null;
                    _availableExtras = [];
                    _showExtras = false;
                  });
                }
              },
              enabled: !_isProcessing,
            ),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: _isProcessing || _scanController.text.trim().isEmpty 
                ? null 
                : _handleScanSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isProcessing
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text('Processando...'),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 18.0),
                      SizedBox(width: 8.0),
                      Text('Procurar'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Constrói o resultado do scan
  Widget _buildScanResult(Map<String, dynamic> status) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      child: _scannedTicket!.containsKey('error')
          ? _buildErrorResult()
          : _buildTicketResult(status),
    );
  }

  /// Constrói o resultado de erro
  Widget _buildErrorResult() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _scannedTicket!['error'].toString(),
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _scannedTicket = null);
              _scanFocusNode.requestFocus();
            },
            splashRadius: 24.0,
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  /// Constrói o resultado do bilhete
  Widget _buildTicketResult(Map<String, dynamic> status) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: status['color'].withAlpha((0.1 * 255).round()),
        border: Border.all(color: status['color'].withAlpha((0.3 * 255).round())),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com status
                    Row(
                      children: [
                        Icon(status['icon'], color: status['color']),
                          const SizedBox(width: 8.0),
                        Text(
                          'Bilhete ${status['text']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: status['color'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    
                    // Detalhes do bilhete
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(
                            text: 'Bilhete: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: _scannedTicket!['product_name'] ?? 'ID: ${_scannedTicket!['id']}',
                          ),
                          const TextSpan(text: ' | '),
                          const TextSpan(
                            text: 'Evento: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: _scannedTicket!['event_name'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    
                    // Nome do cliente (se disponível)
                    if (_scannedTicket!['name'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(
                                text: 'Cliente: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: _scannedTicket!['name']),
                            ],
                          ),
                        ),
                      ),
                    
                    // Extras no bilhete (se existirem)
                    if (_scannedTicket!['extras'] != null && 
                        (_scannedTicket!['extras'] is List ? 
                          (_scannedTicket!['extras'] as List).isNotEmpty : 
                          (_scannedTicket!['extras'] as Map).isNotEmpty))
                      _buildTicketExtras(false), // Não mostrar botão aqui, vamos mostrar abaixo
                    
                    // Botão para adicionar extras (para bilhetes válidos e convites pagos)
                    if (status['text'] == 'Válido' || status['text'] == 'Convite Pago')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                  Icon(Icons.restaurant, size: 16.0, color: Colors.grey),
                                  SizedBox(width: 4.0),
                                  Text(
                                    'Extras:',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                            ),
                            TextButton.icon(
                              icon: Icon(
                                _showExtras ? Icons.remove : Icons.add,
                                size: 16.0,
                              ),
                              label: Text(_showExtras ? 'Esconder Extras' : 'Adicionar Extras'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                setState(() => _showExtras = !_showExtras);
                              },
                            ),
                          ],
                        ),
                      ),
                    
                    // Ações específicas por status
                    if (status['text'] == 'Convite Pago')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Ativar Convite (Adicionar ao Carrinho)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _handleActivatePaidInvite,
                        ),
                      ),
                    
                    // Extras disponíveis para adicionar
                    if (_showExtras)
                      _buildAvailableExtras(),
                  ],
                ),
              ),
              
              // Botão para fechar
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _scannedTicket = null;
                    _showExtras = false;
                    _availableExtras = [];
                  });
                  _scanFocusNode.requestFocus();
                },
                splashRadius: 24.0,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de extras no bilhete
  Widget _buildTicketExtras([bool showButton = true]) {
    // Determinar se os extras estão em formato de lista ou mapa
    List<dynamic> extrasAsList = [];
    
    if (_scannedTicket!['extras'] is List) {
      extrasAsList = _scannedTicket!['extras'];
    } else if (_scannedTicket!['extras'] is Map) {
      extrasAsList = (_scannedTicket!['extras'] as Map).values.toList();
    } else {
      return const SizedBox.shrink();  // Tipo não suportado
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant, size: 14.0, color: Colors.grey),
                  SizedBox(width: 4.0),
                  Text(
                    'Extras no bilhete:',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Botão para mostrar extras disponíveis (opcional)
              if (showButton && 
                 (_getTicketStatus(_scannedTicket)['color'] == Colors.green || 
                  _getTicketStatus(_scannedTicket)['color'] == Colors.amber))
                TextButton.icon(
                  icon: Icon(
                    _showExtras ? Icons.remove : Icons.add,
                    size: 14.0,
                  ),
                  label: Text(_showExtras ? 'Esconder Extras' : 'Adicionar Extras'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Theme.of(context).primaryColor,
                    textStyle: const TextStyle(fontSize: 12.0),
                  ),
                  onPressed: () {
                    setState(() => _showExtras = !_showExtras);
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 8.0),
          
          // Lista de extras no bilhete
          Column(
            children: extrasAsList.map((extra) {
              // Converter qty para int, já que pode vir como string do backend
              final int qty = int.tryParse(extra['qty']?.toString() ?? '0') ?? 0;
              final int used = extra['used'] ?? 0;
              final int available = qty - used;
              final bool isAvailable = available > 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      extra['name'] ?? 'Extra',
                      style: TextStyle(
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        // Botão para levantar extra
                        if (isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: () => _handleWithdrawExtra(extra),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                visualDensity: VisualDensity.compact,
                                textStyle: const TextStyle(fontSize: 12.0),
                              ),
                              child: const Text('LEVANTAR'),
                            ),
                          ),
                        
                        // Badge com contagem
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            isAvailable ? 'Disponível: $available' : 'Esgotado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 4.0),
                        
                        // Contagem de uso
                        Text(
                          '($used/$qty)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de extras disponíveis para adicionar
  Widget _buildAvailableExtras() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extras Disponíveis:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Row(
                      children: [
                Icon(Icons.info_outline, size: 14.0, color: Colors.grey),
                SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    'Os extras serão adicionados ao bilhete apenas após o pagamento no checkout.',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mensagem quando não há extras disponíveis
          if (_availableExtras.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 24.0, color: Colors.grey),
                    SizedBox(height: 8.0),
                    Text(
                      'Não há extras disponíveis para este evento.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          // Grid de extras disponíveis
          if (_availableExtras.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _availableExtras.length,
              itemBuilder: (context, index) {
                final extra = _availableExtras[index];
                
                return Card(
                  elevation: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extra['name'] ?? 'Extra',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '€${(extra['price'] ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _handleAddExtraToCart(extra),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 10.0),
                            ),
                            child: const Text('Adicionar ao Carrinho'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}