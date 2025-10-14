// Página de teste para a impressão de recibos Vendus
// Usa o novo serviço de impressão

import 'package:flutter/material.dart';

import '../services/print_service.dart';
import '../services/pos2_debug_helper.dart';

class PrintTestPage extends StatefulWidget {
  static const routeName = '/test/print';
  
  const PrintTestPage({super.key});

  @override
  State<PrintTestPage> createState() => _PrintTestPageState();
}

class _PrintTestPageState extends State<PrintTestPage> {
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;
  // Armazenar o resultado do último teste

  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _testPrintService() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'Obtendo dados para o pedido #22680...';
      _isSuccess = false;
    });
    
    try {
      // 1. Obter dados de impressão usando o PrintService
      const orderId = 22680; // ID do pedido associado à fatura que queremos testar
      
      final result = await PrintService.printOrderReceipt(orderId);
      
      if (result['success'] != true) {
        throw Exception('Erro: ${result['message']}');
      }
      
      // Dados obtidos com sucesso
      setState(() {
        _isSuccess = true;
        _resultMessage = 'Dados de impressão obtidos com sucesso!\n'
            'Fatura: ${result['invoice_number'] ?? ''}\n'
            'Data: ${result['invoice_date'] ?? ''}\n'
            'Tamanho dos dados: ${result['data_size'] ?? 0} bytes';
      });
      
      // 2. Simular impressão dos dados na impressora MyPOS
      await _simulatePrintOnMyPOS(result);
      
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _resultMessage = 'Erro: $e';
      });
      POS2DebugHelper.logError('Erro no teste de impressão', error: e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _simulatePrintOnMyPOS(Map<String, dynamic> printData) async {
    try {
      // Em uma implementação real, usaríamos:
      // 1. Obter os bytes de impressão do resultado
      // final bytes = printData['print_bytes'];
      // 2. Enviar para a impressora usando a API MyPOS
      // final mypos = MyPos();
      // final result = await mypos.printRawBytes(bytes);
      
      // Para este teste, apenas simulamos a impressão com sucesso
      await Future.delayed(const Duration(seconds: 2)); // Simular tempo de impressão
      
      setState(() {
        _resultMessage += '\n\nSimulação de impressão concluída com sucesso!';
        _resultMessage += '\n\nEm uma implementação real, os dados ESC/POS';
        _resultMessage += '\nseriam enviados diretamente para a impressora.';
      });
      
    } catch (e) {
      setState(() {
        _resultMessage += '\n\nErro na impressão: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Impressão Vendus'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'TESTE DE IMPRESSÃO VIA API',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este teste usa o novo PrintService para obter os dados de impressão '
                      'usando a API correta do backend e imprime usando a biblioteca MyPOS.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testPrintService,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('TESTAR IMPRESSÃO DO PEDIDO #22680'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Área de resultados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSuccess ? Colors.green : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.info,
                        color: _isSuccess ? Colors.green : Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RESULTADO:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _resultMessage,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}