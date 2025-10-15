import 'package:flutter/material.dart';
import 'package:my_pos/my_pos.dart';
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
  
  /// Abrir scanner MyPOS automaticamente ao iniciar
  final bool autoOpenScanner;

  const UniversalScanner({
    super.key,
    this.onScanResult,
    this.onAddToCart,
    this.selectedEventId,
    this.autoOpenScanner = false,
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Abrir scanner MyPOS automaticamente se configurado
      if (widget.autoOpenScanner) {
        _openMyPosScanner();
      } else {
        // Só dar foco ao campo de texto se NÃO for auto-abrir o scanner
        // (para evitar abrir o teclado desnecessariamente)
        _scanFocusNode.requestFocus();
      }
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

  /// Abrir scanner MyPOS nativo
  Future<void> _openMyPosScanner() async {
    if (_isProcessing) return;
    
    try {
      POS2DebugHelper.log('Abrindo scanner MyPOS...');
      
      // Abrir scanner do MyPOS
      final result = await MyPos.openScanner();
      
      if (result != null && result.isNotEmpty) {
        // Preencher o campo com o código escaneado
        _scanController.text = result;
        
        // Processar automaticamente
        await _handleScanSubmit();
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao abrir scanner MyPOS', error: e);
      // Mostrar mensagem de erro se montado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir scanner: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
  /// Adicionar extra ao carrinho (withdraw automático acontece no backend após pagamento)
  Future<void> _handleAddExtraToCart(dynamic extra) async {
    if (_scannedTicket == null) return;
    
    final cartService = POS2CartService.instance;
    final ticketCode = _scannedTicket!['ticket'];
    final ticketId = _scannedTicket!['id'];
    final eventId = _scannedTicket!['event_id'];
    
    // Adicionar ao carrinho
    final success = cartService.addExtra(
      extra,
      ticketCode: ticketCode,
      ticketId: ticketId,
      eventId: eventId,
    );
    
    if (success) {
      if (widget.onAddToCart != null) {
        widget.onAddToCart!(extra);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extra "${extra['name']}" adicionado ao carrinho'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  /// Levantar um extra associado a um bilhete
  Future<void> _handleWithdrawExtra(dynamic extra) async {
    if (_scannedTicket == null || _isProcessing) return;
    
    // Converter qty e used para int (backend pode enviar como String)
    final int qtyTotal = int.tryParse(extra['qty']?.toString() ?? '0') ?? 0;
    final int qtyUsed = int.tryParse(extra['used']?.toString() ?? '0') ?? 0;
    final int qtyAvailable = qtyTotal - qtyUsed;
    
    if (qtyAvailable <= 0) return;
    
    int quantityToWithdraw = 1;
    
    // Se tem mais de 1 disponível, mostrar popup para escolher quantidade
    if (qtyAvailable > 1) {
      quantityToWithdraw = await _showQuantityDialog(extra['name'], qtyAvailable) ?? 0;
      if (quantityToWithdraw == 0) return; // Cancelou
    }
    
    // Processar o withdraw
    await _performWithdraw(extra, quantityToWithdraw);
  }
  
  /// Mostrar dialog para escolher quantidade a levantar
  Future<int?> _showQuantityDialog(String extraName, int maxQty) async {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Column(
            children: [
              const Icon(Icons.shopping_bag, color: Color(0xFF667eea), size: 32),
              const SizedBox(height: 12),
              Text(
                extraName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quantas deseja levantar?',
                style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Grid de números (1, 2, 3, 4...)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(maxQty > 5 ? 5 : maxQty, (index) {
                  final qty = index + 1;
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(qty),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3A3A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('$qty', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              // Botão "TODAS" destacado
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(maxQty),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'TODAS ($maxQty)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(0),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB0B0B0))),
            ),
          ],
        );
      },
    );
  }
  
  /// Executar o withdraw com a quantidade especificada
  Future<void> _performWithdraw(dynamic extra, int quantity) async {
    if (_scannedTicket == null || _isProcessing) return;
    
    final ticketCode = _scannedTicket!['ticket'];
    final extraId = extra['id'];
    
    if (ticketCode == null || extraId == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      POS2DebugHelper.log('Levantando $quantity x ${extra['name']} do bilhete $ticketCode');
      
      // Chamar API UMA VEZ com a quantidade especificada
      final result = await POS2ApiService.withdrawExtra(ticketCode, extraId, quantity: quantity);
      
      if (!result['success']) {
        throw Exception(result['message'] ?? 'Erro ao levantar extra');
      }
      
      // Atualizar dados com resposta do servidor
      if (result['data']?['ticket']?['extras'] != null) {
        setState(() {
          _scannedTicket = {
            ..._scannedTicket!,
            'extras': result['data']['ticket']['extras'],
          };
        });
      }
      
      if (mounted) {
        // Fechar o bilhete imediatamente
        setState(() {
          _scannedTicket = null;
          _showExtras = false;
          _availableExtras = [];
        });
        
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quantity == 1 
                      ? '${extra['name']} levantado com sucesso!'
                      : '$quantity x ${extra['name']} levantados com sucesso!',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        // Aguardar um momento e então abrir o scanner MyPOS
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _openMyPosScanner();
          }
        });
      }
      
      POS2DebugHelper.log('✅ $quantity x ${extra['name']} levantado(s) com sucesso!');
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
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
              style: const TextStyle(fontSize: 16.0, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Insira ou digitalize o código QR',
                hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Color(0xFF667eea)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                filled: true,
                fillColor: const Color(0xFF2D2D2D),
              ),
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
          // Botão do scanner MyPOS
          IconButton(
            onPressed: _isProcessing ? null : _openMyPosScanner,
            icon: const Icon(Icons.qr_code_scanner),
            color: const Color(0xFF667eea),
            iconSize: 28.0,
            tooltip: 'Abrir Scanner MyPOS',
            padding: const EdgeInsets.all(12.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          const SizedBox(width: 4.0),
          // Botão de procurar
          IconButton(
            onPressed: _isProcessing || _scanController.text.trim().isEmpty 
                ? null 
                : _handleScanSubmit,
            icon: _isProcessing 
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.search),
            color: Colors.white,
            iconSize: 28.0,
            tooltip: 'Procurar',
            padding: const EdgeInsets.all(12.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              disabledBackgroundColor: const Color(0xFF3A3A3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
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
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _scannedTicket!['error'].toString(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _scannedTicket = null);
              _scanFocusNode.requestFocus();
            },
            splashRadius: 24.0,
            color: Colors.red,
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
                        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
                        children: [
                          const TextSpan(
                            text: 'Bilhete: ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          TextSpan(
                            text: _scannedTicket!['product_name'] ?? 'ID: ${_scannedTicket!['id']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const TextSpan(text: ' | ', style: TextStyle(color: Colors.white)),
                          const TextSpan(
                            text: 'Evento: ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          TextSpan(
                            text: _scannedTicket!['event_name'] ?? 'N/A',
                            style: const TextStyle(color: Colors.white),
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
                            style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
                            children: [
                              const TextSpan(
                                text: 'Cliente: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              TextSpan(text: _scannedTicket!['name'], style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    
                    // Extras no bilhete (se existirem)
                    if (_scannedTicket!['extras'] != null && 
                        (_scannedTicket!['extras'] is List ? 
                          (_scannedTicket!['extras'] as List).isNotEmpty : 
                          (_scannedTicket!['extras'] as Map).isNotEmpty))
                      _buildTicketExtras(false),
                    
                    // Botão para adicionar extras (para bilhetes válidos e convites pagos)
                    if (status['text'] == 'Válido' || status['text'] == 'Convite Pago')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(
                              _showExtras ? Icons.expand_less : Icons.add_circle_outline,
                              size: 18.0,
                            ),
                            label: Text(_showExtras ? 'Esconder Extras' : 'Adicionar Extras ao Bilhete'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              foregroundColor: const Color(0xFF667eea),
                              side: const BorderSide(color: Color(0xFF667eea)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            onPressed: () {
                              setState(() => _showExtras = !_showExtras);
                            },
                          ),
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
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          const Row(
            children: [
              Icon(Icons.restaurant_menu, size: 16.0, color: Colors.orange),
              SizedBox(width: 6.0),
              Text(
                'Extras no Bilhete',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8.0),
          
          // Lista de extras no bilhete - Cada extra num card compacto
          ...extrasAsList.map((extra) {
            // Converter qty e used para int, já que pode vir como string do backend
            final int qty = int.tryParse(extra['qty']?.toString() ?? '0') ?? 0;
            final int used = int.tryParse(extra['used']?.toString() ?? '0') ?? 0;
            final int available = qty - used;
            final bool isAvailable = available > 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFF3A3A3A),
                border: Border.all(
                  color: isAvailable ? Colors.orange.withValues(alpha: 0.4) : const Color(0xFF3A3A3A),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha 1: Nome do extra + Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          extra['name'] ?? 'Extra',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? Colors.white : const Color(0xFFB0B0B0),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          '$available / $qty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Linha 2: Botão de levantar (só se disponível)
                  if (isAvailable) ...[
                    const SizedBox(height: 8.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleWithdrawExtra(extra),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                        icon: const Icon(Icons.download, size: 18.0),
                        label: const Text(
                          'LEVANTAR EXTRA',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Constrói a seção de extras disponíveis para adicionar
  Widget _buildAvailableExtras() {
    if (_availableExtras.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16.0, color: Color(0xFFB0B0B0)),
            SizedBox(width: 8.0),
            Expanded(
              child: Text(
                'Não há extras disponíveis para adicionar a este bilhete',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Color(0xFFB0B0B0),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          const Row(
            children: [
              Icon(Icons.add_shopping_cart, size: 16.0, color: Colors.green),
              SizedBox(width: 6.0),
              Text(
                'Adicionar Novos Extras',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10.0),
          
          // Lista de extras disponíveis - Grid para aproveitar melhor o espaço
          ..._availableExtras.map((extra) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6.0),
              child: ElevatedButton(
                onPressed: () => _handleAddExtraToCart(extra),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        extra['name'] ?? 'Extra',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '€${(extra['price'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        const Icon(Icons.add_circle, size: 18.0),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}