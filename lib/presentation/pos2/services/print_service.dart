import 'dart:convert';
import 'dart:typed_data';

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
    } else {
      POS2DebugHelper.logError('PrintService: Falha ao obter dados de impressão', 
          error: result['message']);
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
      
      // 2. Decodificar dados Base64 para bytes ESC/POS
      final printDataBase64 = receiptData['print_data_base64'];
      if (printDataBase64 == null || printDataBase64.isEmpty) {
        return {
          'success': false,
          'message': 'Dados de impressão inválidos ou vazios',
        };
      }
      
      final printBytes = decodeReceiptData(printDataBase64);
      
      // 3. Aqui você implementaria o envio para a impressora conectada
      // Essa implementação depende da biblioteca de impressão que você estiver usando
      // (BluetoothPrinter, WebUSB, etc.)
      
      // Exemplo simples (pseudocódigo):
      // await printer.connect();
      // await printer.printRawData(printBytes);
      // await printer.disconnect();
      
      POS2DebugHelper.log('PrintService: Dados prontos para impressão (${printBytes.length} bytes)');
      
      // Retornar sucesso com informações úteis
      return {
        'success': true,
        'message': 'Dados preparados para impressão',
        'invoice_number': receiptData['invoice_number'],
        'invoice_date': receiptData['invoice_date'],
        'data_size': printBytes.length,
        'print_data_base64': printDataBase64, // Adicionar base64 no resultado
        'print_bytes': printBytes, // bytes prontos para enviar à impressora
      };
      
    } catch (e) {
      POS2DebugHelper.logError('PrintService: Erro ao imprimir recibo', error: e);
      return {
        'success': false,
        'message': 'Erro ao processar impressão: $e',
      };
    }
  }
}