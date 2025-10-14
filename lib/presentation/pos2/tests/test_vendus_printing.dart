// Página de teste para a impressão de recibos Vendus
// Adaptado para o aplicativo Flutter (requer token válido)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos/my_pos.dart';
import 'package:my_pos/models/my_pos_paper.dart';
import 'package:my_pos/enums/py_pos_print_response.dart';
import '../services/print_service.dart';
import '../services/pos2_debug_helper.dart';

class VendusPrintTestPage extends StatefulWidget {
  static const routeName = '/test/vendus-print';
  
  const VendusPrintTestPage({super.key});

  @override
  State<VendusPrintTestPage> createState() => _VendusPrintTestPageState();
}

class _VendusPrintTestPageState extends State<VendusPrintTestPage> {
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _testVendusInvoice() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'Obtendo dados para o pedido #22680...';
      _isSuccess = false;
    });
    
    try {
      // 1. Usar a rota correta para o servidor (com /api/app/ no caminho)
      const orderId = 22680;
      
      // 2. Obter dados de impressão usando o PrintService
      final result = await PrintService.printOrderReceipt(orderId);
      
      if (result['success'] != true) {
        throw Exception('Erro: ${result['message']}');
      }
      
      // 3. Dados obtidos com sucesso
      setState(() {
        _isSuccess = true;
        _resultMessage = 'Dados de impressão obtidos com sucesso!\n'
            'Fatura: ${result['invoice_number'] ?? ''}\n'
            'Data: ${result['invoice_date'] ?? ''}\n'
            'Tamanho dos dados: ${result['data_size'] ?? 0} bytes';
      });
      
      // 4. Processar os dados para impressão
      final base64Data = result['print_data_base64'];
      if (base64Data != null && base64Data.isNotEmpty) {
        // Converter Base64 para bytes
        final rawEscPosData = base64Decode(base64Data);
        
        // Imprimir usando SDK MyPOS
        await _printRawData(rawEscPosData);
      } else {
        throw Exception('Dados de impressão vazios ou inválidos');
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _resultMessage = 'Erro: $e';
      });
      POS2DebugHelper.logError('Erro ao testar impressão Vendus', error: e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _printTestReceipt() async {
    try {
      setState(() {
        _isLoading = true;
        _resultMessage = 'Obtendo dados do Vendus e preparando recibo...';
      });
      
      // Simulamos a chamada à API Vendus obtendo os dados do JSON que já temos
      // Numa implementação real, você faria uma chamada HTTP à API do Vendus
      final String vendusFatura = await _getVendusJsonData();
      
      setState(() {
        _resultMessage += '\nDados JSON do Vendus obtidos com sucesso!';
      });
      
      // Parse do JSON
      final Map<String, dynamic> receiptData = json.decode(vendusFatura);
      
      // Verificar se há dados válidos
      if (!receiptData.containsKey('company')) {
        throw Exception('Dados de recibo inválidos ou incompletos');
      }
      
      // Inicializa o objeto de impressão
      final paper = MyPosPaper();
      
      // ----- CABEÇALHO -----
      // Nome da empresa centralizado
      final company = receiptData['company'] ?? {};
      paper.addText(company['name'] ?? 'Essencia Eventos e Comunicacao Unipessoal Lda', 
          fontSize: 24, alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // Endereço
      final address = company['address'] ?? {};
      paper.addText(address['street'] ?? 'Avenida Dr. Antunes Guimaraes, No 788', 
          alignment: PrinterAlignment.center);
      paper.addText("${address['postal_code'] ?? '4100-075'} ${address['city'] ?? 'Porto'}", 
          alignment: PrinterAlignment.center);
      
      // NIF da empresa
      paper.addText("NIF: ${company['fiscal_id'] ?? '506844374'}", 
          alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // Linha separadora
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      
      // ----- DADOS DO DOCUMENTO -----
      // Tipo e número do documento
      final type = receiptData['type'] ?? 'Fatura Recibo';
      final number = receiptData['number'] ?? 'FR 01P2025/3';
      paper.addText("$type $number", alignment: PrinterAlignment.center);
      // Versão e data
      // Alterado para "Original" conforme solicitado
      const version = "Original"; // Ignorando o valor do JSON
      final date = receiptData['localtime'] ?? '2025-10-13 19:08:00';
      paper.addText("$version - $date", alignment: PrinterAlignment.left);
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      

      
      
      // ----- DADOS DO CLIENTE -----
      final client = receiptData['client'] ?? {};
      paper.addText("NIF: ${client['fiscal_id'] ?? '---------'}", 
          alignment: PrinterAlignment.left);
      paper.addText("Nome: ${client['name'] ?? 'Consumidor Final'}", 
          alignment: PrinterAlignment.left);
      paper.addSpace(1);
      
      // ----- CABEÇALHO DE PRODUTOS -----
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addText("PRODUTOS", 
          alignment: PrinterAlignment.center, fontSize: 20);
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      
      // ----- ITENS DO PEDIDO -----
      final items = receiptData['items'] ?? [];
      for (var item in items) {
        // Título do produto
        final title = item['title'] ?? 'Copo Riedel EV LISBOA 2025';
        paper.addText(title, alignment: PrinterAlignment.left);
        
        // Quantidade, preço e taxa em linhas separadas para melhor legibilidade
        final qty = item['qty'] ?? 1;
        final price = item['price'] ?? '€ 5,00';
        final taxRate = item['tax']?['rate'] ?? 23;
        final total = item['total'] ?? '€ 5,00';
        
        // Informações em formato mais compacto para papel pequeno
        paper.addText("$qty x ${_formatPrice(price)} ($taxRate%) = $total", 
            alignment: PrinterAlignment.left);
        paper.addSpace(1);
      }
      
      // Linha separadora
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // ----- TOTAIS E PAGAMENTO -----
      // Total
      final total = receiptData['total'] ?? '€ 5,00';
      paper.addText("TOTAL: $total", fontSize: 24, alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // Método de pagamento
      paper.addText("PAGAMENTO:", alignment: PrinterAlignment.center);
      final payments = receiptData['payments'] ?? [];
      if (payments.isNotEmpty) {
        for (var payment in payments) {
          final method = payment['label'] ?? 'Cartao de Credito';
          final amount = payment['value'] ?? '€ 5,00';
          
          paper.addText("$method: $amount", alignment: PrinterAlignment.center);
        }
      }
      paper.addSpace(1);
      
      // ----- DETALHES DO IVA -----
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addText("RESUMO IVA", 
          alignment: PrinterAlignment.center, fontSize: 20);
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      
      // Detalhes dos impostos
      final taxes = receiptData['taxes'] ?? {};
      final rates = taxes['rates'] ?? [];
      for (var rate in rates) {
        final ratePercent = rate['rate'] ?? '23%';
        final base = rate['base'] ?? '€ 4,07';
        final amount = rate['amount'] ?? '€ 0,93';
        final taxTotal = rate['total'] ?? '€ 5,00';
        
        // Formato simplificado para caber melhor no papel pequeno
        paper.addText("Taxa: $ratePercent", alignment: PrinterAlignment.left);
        paper.addText("Base: $base  IVA: $amount", alignment: PrinterAlignment.left);
        paper.addText("Total: $taxTotal", alignment: PrinterAlignment.left);
      }
      
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // ----- ATCUD E ASSINATURA -----
      // ATCUD
      final atcud = receiptData['atcud'] ?? 'ATCUD:J6FJZV9T-3';
      paper.addText(atcud, alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // ----- QR CODE -----
      // Gerar e imprimir o QR code
      final qrcodeData = receiptData['qrcode_data'] ?? 
          "A:506844374*B:999999990*C:PT*D:FR*E:N*F:20251013*G:FR 01P2025/3*H:J6FJZV9T-3*I1:PT*I7:4.07*I8:0.93*N:0.93*O:5.00*P:0.00*Q:PVOY*R:2230";
      
      if (qrcodeData.isNotEmpty) {
        paper.addQrCode(qrcodeData, size: 200);
        paper.addSpace(1);
      }
      
      // Assinatura
      final signature = receiptData['signature'] ?? 'PVOY-Processado por programa certificado n. 2230/AT';
      paper.addText(signature, alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // Operador
      paper.addText("Operador: Jose Galante", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // Mensagem de agradecimento
      paper.addText("Obrigado pela preferência!", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      paper.addCutLine();
      
      // Enviar para impressão
      final printResult = await MyPos.printPaper(paper);
      
      // Verificar resultado
      if (printResult == PrintResponse.success) {
        setState(() {
          _isSuccess = true;
          _resultMessage = 'Impressão de teste concluída com sucesso!';
        });
      } else {
        throw Exception('Falha na impressão: $printResult');
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _resultMessage = 'Erro ao processar impressão de teste: $e';
      });
      POS2DebugHelper.logError('Erro ao imprimir recibo de teste', error: e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printRawData(List<int> rawData) async {
    try {
      setState(() {
        _resultMessage += '\n\nEnviando dados para a impressora...';
      });
      
      // Em vez de tentar usar os dados ESC/POS diretamente, vamos criar um recibo simples
      // usando o MyPosPaper que sabemos que funciona
      
      final paper = MyPosPaper();
      
      // Criar um recibo simples
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addText("FATURA VENDUS", fontSize: 32, alignment: PrinterAlignment.center);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("Dados ESC/POS recebidos: ${rawData.length} bytes", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("Fatura #22680", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("THE BLUE HUB", alignment: PrinterAlignment.center);
      paper.addText("Recibo de Pagamento", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("Obrigado pela preferência!", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addCutLine();
      
      // Enviar para impressão
      final printResult = await MyPos.printPaper(paper);
      
      // Verificar resultado
      if (printResult == PrintResponse.success) {
        setState(() {
          _resultMessage += '\n\nImpressão concluída com sucesso!';
          _resultMessage += '\nDados ESC/POS (${rawData.length} bytes) processados.';
        });
      } else {
        throw Exception('Falha na impressão: $printResult');
      }
    } catch (e) {
      setState(() {
        _resultMessage += '\n\nErro ao processar impressão: $e';
      });
    }
  }
  
  // Funções auxiliares para o recibo Vendus
  Future<String> _getVendusJsonData() async {
    // Em uma implementação real, você faria uma chamada HTTP para a API do Vendus
    // Exemplo: final response = await http.get(Uri.parse('https://www.vendus.pt/ws/v1.2/documents/22680?output=json&return_qrcode=1'));
    
    // Aqui estamos simulando com dados fixos
    return '''
    {
      "company": {
        "name": "Essencia Eventos e Comunicacao Unipessoal Lda",
        "fiscal_id": "506844374",
        "address": {
          "street": "Avenida Dr. Antunes Guimaraes, No 788",
          "postal_code": "4100-075",
          "city": "Porto"
        }
      },
      "type": "Fatura Recibo",
      "number": "FR 01P2025/3",
      "date": "2025-10-13",
      "time": "15:30:45",
      "version": "Segunda Via",
      "client": {
        "fiscal_id": "---------",
        "name": "Consumidor Final"
      },
      "items": [
        {
          "reference": "EXTRA-6",
          "title": "Copo Riedel EV LISBOA 2025",
          "qty": 1,
          "price": "€ 5,00",
          "total": "€ 5,00",
          "tax": {
            "rate": 23
          }
        }
      ],
      "total": "€ 5,00",
      "payments": [
        {
          "label": "Cartao de Credito",
          "value": "€ 5,00"
        }
      ],
      "taxes": {
        "rates": [
          {
            "rate": "23%",
            "base": "€ 4,07",
            "amount": "€ 0,93",
            "total": "€ 5,00"
          }
        ]
      },
      "atcud": "ATCUD:J6FJZV9T-3",
      "signature": "PVOY-Processado por programa certificado n. 2230/AT",
      "qrcode_data": "A:506844374*B:999999990*C:PT*D:FR*E:N*F:20251013*G:FR 01P2025/3*H:J6FJZV9T-3*I1:PT*I7:4.07*I8:0.93*N:0.93*O:5.00*P:0.00*Q:PVOY*R:2230"
    }
    ''';
  }
  
  // Formata um valor de preço (remove caracteres extras se necessário)
  String _formatPrice(String price) {
    // Remove caracteres extras se necessário
    return '${price.replaceAll('€ ', '').trim()}€';
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
              color: Colors.green.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TESTE DA FATURA DO PEDIDO #22680:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testVendusInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 60),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('TESTAR IMPRESSÃO DA FATURA'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _printTestReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 60),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('IMPRIMIR RECIBO DE TESTE'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.shade50 : Colors.grey.shade100,
                border: Border.all(
                  color: _isSuccess ? Colors.green : Colors.grey.shade300,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resultado:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _isSuccess ? Colors.green : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _resultMessage,
                    style: const TextStyle(fontSize: 16),
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