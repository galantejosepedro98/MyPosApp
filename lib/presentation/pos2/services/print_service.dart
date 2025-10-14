import 'dart:convert';
import 'dart:typed_data';

import 'package:my_pos/my_pos.dart';
import 'package:my_pos/models/my_pos_paper.dart';
import 'package:my_pos/enums/py_pos_print_response.dart';

import '../services/pos2_api_service.dart';
import 'pos2_debug_helper.dart';

class PrintService {
  /// Obtém os dados de impressão para um pedido específico
  /// Retorna um map com 'success' e os dados relevantes ou uma mensagem de erro
  static Future<Map<String, dynamic>> getReceiptData(int orderId) async {
    POS2DebugHelper.log('PrintService: Obtendo dados para o pedido #$orderId');
    
    final result = await POS2ApiService.getReceiptPrintData(orderId);
    
    // Adicionar log para debug
    if (result['success'] == true) {
      POS2DebugHelper.log('PrintService: Dados de impressão obtidos com sucesso');
      
      // Log dos dados recebidos da API para debug
      if (result['data'] != null) {
        final data = result['data'];
        POS2DebugHelper.log('PrintService: Dados disponíveis - print_data_base64: ${data['print_data_base64'] != null ? "SIM" : "NÃO"}');
        POS2DebugHelper.log('PrintService: Format: ${data['print_format'] ?? "não especificado"}');
        POS2DebugHelper.log('PrintService: Invoice: ${data['invoice_number'] ?? "não especificado"}');
      }
    } else {
      POS2DebugHelper.logError('PrintService: Falha ao obter dados de impressão', 
          error: result['message']);
    }
    
    // SIMPLES! Usar dados limpos diretamente
    if (result['success'] == true && result['dados_limpos'] != null) {
      return {
        'success': true,
        'dados_limpos': result['dados_limpos'], // Dados já limpos!
        'print_format': 'dados_limpos',
        'invoice_number': result['invoice_number'],
        'invoice_date': result['invoice_date'],
      };
    }
    
    return result;
  }
  
  /// Converte os dados Base64 em Uint8List para envio à impressora
  /// Retorna um Uint8List com os bytes ESC/POS prontos para impressão
  static Uint8List decodeReceiptData(String base64Data) {
    try {
      final bytes = base64Decode(base64Data);
      POS2DebugHelper.log('PrintService: Dados convertidos com sucesso (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      POS2DebugHelper.logError('PrintService: Erro ao decodificar dados Base64', error: e);
      throw Exception('Erro ao processar dados de impressão: $e');
    }
  }
  
  /// Decodifica dados JSON de base64 para Map
  static Future<Map<String, dynamic>> _decodeJsonData(String base64Data) async {
    try {
      // Decodificar base64 para string UTF-8
      final bytes = base64Decode(base64Data);
      final jsonString = utf8.decode(bytes);
      
      // Decodificar a string para Map
      final jsonData = json.decode(jsonString);
      
      if (jsonData is Map<String, dynamic>) {
        POS2DebugHelper.log('PrintService: JSON decodificado com sucesso');
        
        // IMPRIMIR JSON COMPLETO FORMATADO PARA DEBUG
        POS2DebugHelper.log('=== DADOS JSON DECODIFICADOS ===');
        const prettyJson = JsonEncoder.withIndent('  ');
        POS2DebugHelper.log(prettyJson.convert(jsonData));
        POS2DebugHelper.log('=== FIM DOS DADOS JSON ===');
        
        return jsonData;
      } else {
        throw Exception('Dados JSON inválidos');
      }
    } catch (e) {
      POS2DebugHelper.logError('PrintService: Erro ao decodificar JSON', error: e);
      throw Exception('Erro ao processar dados JSON: $e');
    }
  }
  
  /// Imprime um recibo formatado com base nos dados JSON (igual ao botão IMPRIMIR RECIBO TESTE)
  static Future<bool> _printFormattedReceipt(Map<String, dynamic> receiptData) async {
    try {
      POS2DebugHelper.log('PrintService: Formatando recibo para impressão');
      
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
      final number = receiptData['invoice_number'] ?? '';
      paper.addText("$type $number", alignment: PrinterAlignment.center);
      
      // Versão e data
      final version = receiptData['version'] ?? 'Original'; 
      final date = receiptData['invoice_time'] ?? '';
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
        final title = item['title'] ?? 'Produto';
        paper.addText(title, alignment: PrinterAlignment.left);
        
        // Quantidade, preço e taxa - usando campos simplificados
        final qty = item['qty'] ?? 1;
        final priceUnit = item['price_unit']?.toString() ?? '0.00';
        final priceTotal = item['price_total']?.toString() ?? priceUnit;
        final taxRate = item['tax_rate'] ?? 23;
        
        // Informações em formato compacto para papel pequeno
        paper.addText("$qty x $priceUnit€ ($taxRate%) = $priceTotal€", 
            alignment: PrinterAlignment.left);
        paper.addSpace(1);
      }
      
      // Linha separadora
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // ----- TOTAIS E PAGAMENTO -----
      // Total
      final total = receiptData['amount_gross']?.toString() ?? '0.00';
      paper.addText("TOTAL: $total€", fontSize: 24, alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // Método de pagamento
      paper.addText("PAGAMENTO:", alignment: PrinterAlignment.center);
      final payments = receiptData['payments'] ?? [];
      if (payments is List && payments.isNotEmpty) {
        for (var payment in payments) {
          if (payment is Map<String, dynamic>) {
            final method = payment['label']?.toString() ?? 'Multibanco';
            final amount = payment['value']?.toString() ?? total;
            
            paper.addText("$method: $amount", alignment: PrinterAlignment.center);
          }
        }
      } else {
        // Se não há informações de pagamento específicas, usar valor padrão
        paper.addText("Multibanco: $total€", alignment: PrinterAlignment.center);
      }
      paper.addSpace(1);
      
      // ----- DETALHES DO IVA -----
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addText("RESUMO IVA", 
          alignment: PrinterAlignment.center, fontSize: 20);
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      
      // Detalhes dos impostos - usando dados dos itens se taxes não estiver disponível
      final taxes = receiptData['taxes'] ?? {};
      if (taxes is Map<String, dynamic> && taxes.isNotEmpty && taxes['rates'] != null) {
        final rates = taxes['rates'] ?? [];
        if (rates is List) {
          for (var rate in rates) {
            if (rate is Map<String, dynamic>) {
              final ratePercent = rate['rate']?.toString() ?? '23';
              final base = rate['base']?.toString() ?? '0.00';
              final amount = rate['amount']?.toString() ?? '0.00';
              final taxTotal = rate['total']?.toString() ?? '0.00';
              
              paper.addText("Taxa: $ratePercent%", alignment: PrinterAlignment.left);
              paper.addText("Base: $base€  IVA: $amount€", alignment: PrinterAlignment.left);
              paper.addText("Total: $taxTotal€", alignment: PrinterAlignment.left);
            }
          }
        }
      } else {
        // Calcular IVA baseado nos totais disponíveis
        final netAmount = receiptData['amount_net']?.toString() ?? '0.00';
        final grossAmount = receiptData['amount_gross']?.toString() ?? '0.00';
        final netFloat = double.tryParse(netAmount) ?? 0.0;
        final grossFloat = double.tryParse(grossAmount) ?? 0.0;
        final taxAmount = grossFloat - netFloat;
        
        paper.addText("Taxa: 23%", alignment: PrinterAlignment.left);
        paper.addText("Base: $netAmount€  IVA: ${taxAmount.toStringAsFixed(2)}€", alignment: PrinterAlignment.left);
        paper.addText("Total: $grossAmount€", alignment: PrinterAlignment.left);
      }
      
      paper.addText("--------------------------------", 
          alignment: PrinterAlignment.center);
      paper.addSpace(1);
      
      // ----- ATCUD E ASSINATURA -----
      // ATCUD se disponível
      final atcud = receiptData['atcud'] ?? '';
      if (atcud.isNotEmpty) {
        paper.addText(atcud, alignment: PrinterAlignment.center);
        paper.addSpace(1);
      }
      
      // ----- QR CODE -----
      // Gerar e imprimir o QR code se disponível (com limitação de tamanho)
      final qrcodeData = receiptData['qrcode'] ?? receiptData['qrcode_data'] ?? '';
      
      if (qrcodeData.isNotEmpty) {
        try {
          // Limitar o tamanho dos dados do QR code para evitar erro "Data too big"
          String qrData = qrcodeData.toString();
          if (qrData.length > 200) {
            // Se muito grande, usar apenas uma URL simples
            qrData = 'https://events.essenciacompany.com';
          }
          paper.addQrCode(qrData, size: 200);
          paper.addSpace(1);
        } catch (e) {
          // Se falhar, continuar sem QR code
          POS2DebugHelper.logError('Erro ao gerar QR code', error: e);
          paper.addText('QR Code indisponível', alignment: PrinterAlignment.center);
          paper.addSpace(1);
        }
      }
      
      // Assinatura
      final signature = receiptData['signature'] ?? 'Processado por programa de faturação';
      if (signature.isNotEmpty) {
        paper.addText(signature, alignment: PrinterAlignment.center);
        paper.addSpace(1);
      }
      
      // Mensagem de agradecimento
      paper.addText("Obrigado pela preferência!", alignment: PrinterAlignment.center);
      paper.addSpace(3);
      
      paper.addCutLine();
      
      // Enviar para impressão
      final printResult = await MyPos.printPaper(paper);
      
      // Retornar sucesso/falha
      return printResult == PrintResponse.success;
    } catch (e) {
      POS2DebugHelper.logError('PrintService: Erro ao formatar/imprimir recibo', error: e);
      return false;
    }
  }
  
  /// Método principal para impressão de um recibo
  /// Obtém os dados e os prepara para impressão
  static Future<Map<String, dynamic>> printOrderReceipt(int orderId) async {
    try {
      // 1. Obter dados de impressão
      final receiptData = await getReceiptData(orderId);
      
      if (receiptData['success'] != true) {
        return {
          'success': false,
          'message': receiptData['message'] ?? 'Falha ao obter dados de impressão',
        };
      }
      
      // 2. SIMPLES! Verificar se temos dados limpos
      final dadosLimpos = receiptData['dados_limpos'];
      if (dadosLimpos != null) {
        POS2DebugHelper.log('PrintService: DADOS LIMPOS detectados - impressão direta!');
        
        // Usar dados limpos diretamente - sem Base64, sem JSON decode!
        final printResult = await _printFormattedReceipt(dadosLimpos);
        
        return {
          'success': printResult,
          'message': printResult ? 'Fatura impressa com sucesso!' : 'Falha na impressão',
          'invoice_number': receiptData['invoice_number'],
          'invoice_date': receiptData['invoice_date'],
          'print_format': 'dados_limpos'
        };
      }
      
      // FALLBACK: Verificar dados Base64 antigos (para compatibilidade)
      final printDataBase64 = receiptData['print_data_base64'];
      if (printDataBase64 == null || printDataBase64.isEmpty) {
        return {
          'success': false,
          'message': 'Dados de impressão inválidos ou vazios',
        };
      }
      
      // 3. Processar dados Base64 (método antigo)
      try {
        final jsonData = await _decodeJsonData(printDataBase64);
        
        POS2DebugHelper.log('PrintService: Detectados dados JSON Base64 - usando formatação personalizada');
        
        final printResult = await _printFormattedReceipt(jsonData);
        
        return {
          'success': printResult,
          'message': printResult ? 'Fatura impressa com sucesso' : 'Falha na impressão',
          'invoice_number': receiptData['invoice_number'],
          'invoice_date': receiptData['invoice_date'],
          'print_format': 'json_formatted'
        };
      } catch (jsonError) {
        return {
          'success': false,
          'message': 'Erro ao processar dados de impressão: $jsonError',
        };
      }
      
    } catch (e) {
      POS2DebugHelper.logError('PrintService: Erro ao imprimir recibo', error: e);
      return {
        'success': false,
        'message': 'Erro ao processar impressão: $e',
      };
    }
  }
}