import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_pos/my_pos.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pos2_debug_helper.dart';

/// Tela para processar QR Físicos após checkout
/// Similar à implementação web em /pos2/physical-qr
class POS2PhysicalQrView extends StatefulWidget {
  final List<int> ticketIds;

  const POS2PhysicalQrView({
    super.key,
    required this.ticketIds,
  });

  @override
  State<POS2PhysicalQrView> createState() => _POS2PhysicalQrViewState();
}

class _POS2PhysicalQrViewState extends State<POS2PhysicalQrView> {
  int _currentTicketIndex = 0;
  bool _isProcessing = false;
  bool _isScanning = false;
  bool _isManualEntry = false;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    POS2DebugHelper.log('POS2PhysicalQr: Iniciando com ${widget.ticketIds.length} tickets');
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  int get _processedCount => _currentTicketIndex;
  int get _totalCount => widget.ticketIds.length;
  bool get _isComplete => _currentTicketIndex >= widget.ticketIds.length;

  /// Processar código QR (escanado ou manual)
  Future<void> _processQrCode(String code) async {
    if (_isProcessing || _isComplete) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentTicketId = widget.ticketIds[_currentTicketIndex];
      
      POS2DebugHelper.log('POS2PhysicalQr: Processando ticket $currentTicketId com código $code');

      // Chamar API para atualizar o ticket com o código QR físico
      final result = await _updateTicketCode(currentTicketId, code);

      if (result['success']) {
        Fluttertoast.showToast(
          msg: 'QR Code atribuído com sucesso!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Avançar para o próximo ticket
        setState(() {
          _currentTicketIndex++;
          _isScanning = false;
          _isManualEntry = false;
          _manualCodeController.clear();
        });

        // Scanner do MyPOS fecha automaticamente após leitura
      } else {
        throw Exception(result['message'] ?? 'Erro ao processar');
      }
    } catch (e) {
      POS2DebugHelper.logError('POS2PhysicalQr: Erro ao processar código', error: e);
      Fluttertoast.showToast(
        msg: 'Erro ao atribuir QR code: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Atualizar ticket com código QR físico via API
  Future<Map<String, dynamic>> _updateTicketCode(int ticketId, String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://events.essenciacompany.com/api/tickets/update-code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'ticket': ticketId,
          'code': code,
        }),
      );

      POS2DebugHelper.logApi('update-ticket-code', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao atualizar ticket',
        };
      }
    } catch (e) {
      POS2DebugHelper.logError('Erro ao atualizar ticket', error: e);
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Iniciar scanner de QR (usando MyPOS)
  void _startScanning() {
    if (_isProcessing || _isComplete) return;

    setState(() {
      _isScanning = true;
      _isManualEntry = false;
    });

    // Navegar para a tela do scanner que usará o MyPOS
    _navigateToScanner();
  }

  /// Navegar para o scanner do MyPOS
  Future<void> _navigateToScanner() async {
    // O scanner do MyPOS retorna o código automaticamente
    final result = await MyPos.openScanner();
    
    // Volta ao estado normal após o scan
    setState(() {
      _isScanning = false;
    });
    
    if (result != null && result.isNotEmpty && !_isProcessing) {
      _processQrCode(result);
    }
  }

  /// Parar scanner (não necessário para MyPOS, mas mantido por compatibilidade)
  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  /// Iniciar entrada manual
  void _startManualEntry() {
    if (_isProcessing || _isComplete) return;

    setState(() {
      _isManualEntry = true;
      _isScanning = false;
    });

    // Focar no campo de texto
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  /// Parar entrada manual
  void _stopManualEntry() {
    setState(() {
      _isManualEntry = false;
      _manualCodeController.clear();
    });
  }

  /// Submeter código manual
  void _submitManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty && !_isProcessing) {
      _processQrCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001232),
      appBar: AppBar(
        title: const Text('POS2 - QR Códigos Físicos'),
        backgroundColor: const Color(0xFF001232),
        leading: _isComplete
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Confirmar saída se não completou
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar?'),
                      content: Text(
                        'Processou $_processedCount de $_totalCount bilhetes.\n'
                        'Tem certeza que deseja cancelar?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Não'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Fecha dialog
                            Navigator.pop(context); // Fecha a tela
                          },
                          child: const Text('Sim'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      body: SafeArea(
        child: _isComplete ? _buildCompletedView() : _buildProcessingView(),
      ),
    );
  }

  /// View quando todos os tickets foram processados
  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              '✅ Todos os bilhetes foram processados!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Processados $_totalCount de $_totalCount bilhetes.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF36A30),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// View principal de processamento
  Widget _buildProcessingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progresso
          _buildProgressSection(),
          const SizedBox(height: 24),

          // Opções de entrada (Scanner ou Manual)
          if (!_isScanning && !_isManualEntry) _buildOptionButtons(),

          // Área do Scanner
          if (_isScanning) _buildScannerSection(),

          // Área de entrada manual
          if (_isManualEntry) _buildManualEntrySection(),
        ],
      ),
    );
  }

  /// Seção de progresso
  Widget _buildProgressSection() {
    final progress = _totalCount > 0 ? _processedCount / _totalCount : 0.0;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$_processedCount / $_totalCount bilhetes processados',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF36A30)),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  /// Botões de opção (Scanner ou Manual)
  Widget _buildOptionButtons() {
    return Column(
      children: [
        _buildOptionCard(
          icon: Icons.qr_code_scanner,
          title: 'Escanear QR Code',
          subtitle: 'Clique para ativar câmara',
          onTap: _startScanning,
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          icon: Icons.keyboard,
          title: 'Inserir código manual',
          subtitle: 'Digitar código manualmente',
          onTap: _startManualEntry,
        ),
      ],
    );
  }

  /// Card de opção
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 60, color: const Color(0xFFF36A30)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  /// Seção do scanner (MyPOS abre scanner nativo)
  Widget _buildScannerSection() {
    return Column(
      children: [
        const Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: Color(0xFFF36A30),
                ),
                SizedBox(height: 16),
                Text(
                  'Scanner MyPOS Ativo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aguardando leitura do código QR...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF36A30)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _stopScanning,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  /// Seção de entrada manual
  Widget _buildManualEntrySection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Inserir código QR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualCodeController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Inserir código do bilhete...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _manualCodeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _manualCodeController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) => _submitManualCode(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _stopManualEntry,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _manualCodeController.text.trim().isEmpty
                      ? null
                      : _submitManualCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF36A30),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
