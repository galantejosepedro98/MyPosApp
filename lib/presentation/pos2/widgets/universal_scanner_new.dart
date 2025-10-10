import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/pos2_api_service.dart';
import '../services/pos2_debug_helper.dart';
import '../models/pos2_product.dart';

class UniversalScannerNew extends StatefulWidget {
  final Function(Map<String, dynamic>)? onScanResult;
  final Function(Map<String, dynamic>)? onAddToCart;
  final int? selectedEventId;

  const UniversalScannerNew({
    super.key,
    this.onScanResult,
    this.onAddToCart,
    this.selectedEventId,
  });

  @override
  State<UniversalScannerNew> createState() => _UniversalScannerNewState();
}

class _UniversalScannerNewState extends State<UniversalScannerNew> {
  final TextEditingController _scanController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController();
  
  bool _isProcessing = false;
  Map<String, dynamic>? _scannedTicket;
  List<POS2Extra> _availableExtras = [];
  bool _showExtras = false;
  
  bool _isScannerActive = false;
  bool _isManualEntry = false;

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController.dispose();
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
  
  void _startScannerCamera() {
    setState(() {
      _isScannerActive = true;
      _isManualEntry = false;
      _cameraController.start();
    });
  }
  
  void _startManualEntry() {
    setState(() {
      _isScannerActive = false;
      _isManualEntry = true;
      _cameraController.stop();
    });
  }
  
  void _handleReset() {
    _scanController.clear();
    setState(() {
      _scannedTicket = null;
      _isScannerActive = false;
      _isManualEntry = false;
      _cameraController.stop();
      _showExtras = false;
    });
  }
  
  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
      final code = barcodes[0].rawValue!;
      _cameraController.stop();
      setState(() {
        _scanController.text = code;
        _isScannerActive = false;
      });
      _handleScanSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scanner iniciado ou não
        if (!_isScannerActive && !_isManualEntry && _scannedTicket == null) 
          _buildScannerOptions(),
        
        // Scanner de câmera ativo
        if (_isScannerActive) 
          _buildCameraScanner(),
          
        // Entrada manual ativa
        if (_isManualEntry) 
          _buildManualEntry(),
          
        // Resultado do scan
        if (_scannedTicket != null) 
          _buildTicketResult(),
      ],
    );
  }
  
  Widget _buildScannerOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Leitor de QR Codes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionCard(
                title: 'Escanear QR Code',
                icon: Icons.qr_code_scanner,
                onTap: _startScannerCamera,
              ),
              _buildOptionCard(
                title: 'Inserir código manual',
                icon: Icons.keyboard,
                onTap: _startManualEntry,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraScanner() {
    return Column(
      children: [
        Container(
          height: 300,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          child: MobileScanner(
            controller: _cameraController,
            onDetect: _handleBarcodeDetection,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _handleReset,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Digite o código do QR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _scanController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Digite o código aqui',
              prefixIcon: Icon(Icons.qr_code),
            ),
            autofocus: true,
            onSubmitted: (_) => _handleScanSubmit(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _handleReset,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleScanSubmit,
                icon: _isProcessing 
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
                label: Text(_isProcessing ? 'Processando...' : 'Procurar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTicketResult() {
    final status = _getTicketStatus(_scannedTicket);
    final hasError = _scannedTicket?.containsKey('error') ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do resultado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status['color'],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(status['icon'], color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status['text'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Corpo do resultado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: hasError
              ? _buildErrorResult()
              : _buildTicketDetails(),
          ),
          
          // Botões de ação
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _handleReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Novo Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorResult() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          _scannedTicket?['error'] ?? 'Erro desconhecido',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  Widget _buildTicketDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informações do bilhete
        _buildDetailRow('Código', _scannedTicket?['ticket'] ?? '-'),
        _buildDetailRow('Nome', _scannedTicket?['name'] ?? '-'),
        _buildDetailRow('Produto', _scannedTicket?['product_name'] ?? '-'),
        _buildDetailRow('Evento', _scannedTicket?['event_name'] ?? '-'),
        
        // Se for um convite pago não ativado
        if (_scannedTicket?['status'] == 0 && 
            _scannedTicket?['active'] == 0 && 
            _scannedTicket?['type'] == 'paid_invite')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: _handleActivatePaidInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ativar Convite Pago'),
            ),
          ),
          
        // Extras do bilhete
        if (_scannedTicket?['extras'] != null && 
            (_scannedTicket?['extras'] as List).isNotEmpty)
          _buildTicketExtras(),
          
        // Botão para mostrar extras disponíveis
        if (_availableExtras.isNotEmpty && 
            _scannedTicket?['status'] == 0 && 
            _scannedTicket?['active'] == 1)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showExtras = !_showExtras),
              icon: Icon(_showExtras ? Icons.remove : Icons.add),
              label: Text(_showExtras ? 'Esconder Extras' : 'Adicionar Extras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
        // Lista de extras disponíveis
        if (_showExtras && _availableExtras.isNotEmpty)
          _buildAvailableExtras(),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  Widget _buildTicketExtras() {
    final extras = _scannedTicket?['extras'] as List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'Extras do Bilhete:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...extras.map((extra) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(extra['name'] ?? 'Extra'),
            subtitle: Text('Preço: ${extra['price'] ?? 0.0}€'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (extra['withdrawn'] == 0)
                  ElevatedButton(
                    onPressed: () => _handleWithdrawExtra(
                      _scannedTicket?['ticket'],
                      extra['id'],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Levantar'),
                  ),
                if (extra['withdrawn'] == 1)
                  const Chip(
                    label: Text('Levantado'),
                    backgroundColor: Colors.grey,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }
  
  Widget _buildAvailableExtras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'Extras Disponíveis:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ..._availableExtras.map((extra) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(extra.name),
            subtitle: Text('Preço: ${extra.price}€'),
            trailing: ElevatedButton(
              onPressed: () => _handleAddExtraToCart(extra),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Adicionar'),
            ),
          ),
        )).toList(),
      ],
    );
  }
  
  // Este método precisa ser implementado depois
  Future<void> _handleWithdrawExtra(String? ticketCode, dynamic extraId) async {
    // Implementação a ser adicionada
    POS2DebugHelper.log('Levantando extra $extraId do bilhete $ticketCode');
  }
}