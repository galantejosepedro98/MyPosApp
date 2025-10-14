import 'package:flutter/material.dart';
import 'package:my_pos/my_pos.dart';
import 'package:my_pos/models/my_pos_paper.dart';
import 'package:my_pos/enums/py_pos_print_response.dart';
import '../dialogs/pos2_print_options_dialog.dart';
import '../widgets/pos2_processing_view.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Serviço responsável por gerenciar as impressões no POS2
class POS2PrinterService {
  /// Mostra o diálogo de opções de impressão e gerencia todo o fluxo de impressão
  /// 
  /// [context] - Contexto para mostrar diálogos
  /// [invoiceId] - ID da fatura para identificação na impressão
  /// [invoiceUrl] - URL da fatura para gerar o QR code
  static Future<void> printInvoice(
    BuildContext context,
    String invoiceId,
    String invoiceUrl,
  ) async {
    // Mostrar diálogo de opções de impressão e aguardar resposta
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => POS2PrintOptionsDialog(
        onOptionSelected: (int copies) async {
          // Se escolheu não imprimir (0), apenas retorna
          if (copies == 0) return;
          
          // Iniciar processo de impressão
          await _doPrintInvoice(context, invoiceId, invoiceUrl, copies);
        },
      ),
    );
  }

  /// Método privado que realiza a impressão propriamente dita
  static Future<void> _doPrintInvoice(
    BuildContext context,
    String invoiceId,
    String invoiceUrl,
    int copies,
  ) async {
    // Mostrar tela de processamento
    final processingOverlay = OverlayEntry(
      builder: (context) => const POS2ProcessingView(
        message: "Imprimindo fatura...",
      ),
    );
    
    Overlay.of(context).insert(processingOverlay);
    
    try {
      // Cria o objeto de papel para impressão
      final paper = MyPosPaper();
      
      // Prepara os dados para impressão
      _preparePaper(paper, invoiceId, invoiceUrl);
      
      // Imprime o número de cópias solicitado
      for (int i = 0; i < copies; i++) {
        final printResult = await MyPos.printPaper(paper);
        
        // Se a impressão falhar, lança exceção
        if (printResult != PrintResponse.success) {
          throw Exception('Falha na impressão: ${printResult.toString()}');
        }
        
        // Aguarda um pouco entre as impressões
        if (i < copies - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      // Mostra mensagem de sucesso
      Fluttertoast.showToast(
        msg: "Fatura impressa com sucesso!",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      // Mostra mensagem de erro
      Fluttertoast.showToast(
        msg: "Erro ao imprimir fatura: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      // Remove a tela de processamento
      processingOverlay.remove();
    }
  }

  /// Prepara os dados para impressão incluindo QR code
  static void _preparePaper(MyPosPaper paper, String invoiceId, String invoiceUrl) {
    // Cabeçalho
    paper.addText("================================", alignment: PrinterAlignment.center);
    paper.addText("FATURA #$invoiceId", fontSize: 32, alignment: PrinterAlignment.center);
    paper.addText("================================", alignment: PrinterAlignment.center);
    paper.addSpace(1);
    
    // Informações da empresa
    paper.addText("THE BLUE HUB", alignment: PrinterAlignment.center);
    paper.addText("Recibo de Pagamento", alignment: PrinterAlignment.center);
    paper.addSpace(1);
    
    // QR code com URL da fatura
    paper.addQrCode(invoiceUrl);
    paper.addText("Escaneie para ver a fatura online", alignment: PrinterAlignment.center);
    paper.addSpace(1);
    
    // Rodapé
    paper.addText("Obrigado pela preferência!", alignment: PrinterAlignment.center);
    paper.addSpace(2);
    
    // Linha de corte
    paper.addCutLine();
  }
  
  /// Método para impressão rápida sem mostrar o diálogo de opções
  /// Útil para reimprimir faturas já emitidas
  static Future<void> quickPrint(
    BuildContext context,
    String invoiceId,
    String invoiceUrl, {
    int copies = 1,
  }) async {
    await _doPrintInvoice(context, invoiceId, invoiceUrl, copies);
  }
}